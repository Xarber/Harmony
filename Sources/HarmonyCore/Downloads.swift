// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import os

public struct DownloadProgress: Sendable {
    public var received: Int64
    public var expected: Int64?
    public var fraction: Double? { expected.flatMap { $0 > 0 ? min(1, Double(received) / Double($0)) : nil } }
}
/// A single bounded, cancellable HTTPS transfer. Redirects are rejected and no cookies are retained.
public final class DirectDownload: NSObject, URLSessionDownloadDelegate, Sendable {
    public static let maximumBytes: Int64 = 2_000_000_000
    private struct State: Sendable {
        var continuation: CheckedContinuation<URL, any Error>?
        var task: URLSessionDownloadTask?
        var cancelled = false
        var completed = false
    }
    private let state = OSAllocatedUnfairLock(initialState: State())
    private let source: URL
    private let destination: URL
    private let progress: @Sendable (DownloadProgress) -> Void
    public init(source: URL, destination: URL, progress: @escaping @Sendable (DownloadProgress) -> Void) throws {
        guard source.scheme == "https", source.host != nil, source.user == nil, source.password == nil,
              !CodecRegistry.requiresConversion(source.pathExtension) else { throw HarmonyError.invalid("Use a direct HTTPS audio-file URL with a supported extension and no embedded credentials.") }
        self.source = source; self.destination = destination; self.progress = progress
    }
    public func run() async throws -> URL {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let config = URLSessionConfiguration.ephemeral
                config.timeoutIntervalForRequest = 30; config.timeoutIntervalForResource = 3600
                config.httpCookieStorage = nil; config.urlCredentialStorage = nil
                let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
                let task = session.downloadTask(with: source)
                let cancelled = state.withLock { value in value.continuation = continuation; value.task = task; return value.cancelled }
                if cancelled { task.cancel(); finish(.failure(CancellationError())); session.invalidateAndCancel() }
                else { task.resume() }
            }
        } onCancel: { self.state.withLock { $0.cancelled = true; $0.task?.cancel() } }
    }
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesWritten <= Self.maximumBytes, totalBytesExpectedToWrite <= Self.maximumBytes else {
            downloadTask.cancel(); finish(.failure(HarmonyError.invalid("Download exceeds the 2 GB limit."))); return
        }
        progress(DownloadProgress(received: totalBytesWritten, expected: totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil))
    }
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            guard let response = downloadTask.response as? HTTPURLResponse, (200..<300).contains(response.statusCode),
                  (try location.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max) <= Self.maximumBytes else { throw HarmonyError.invalid("Server did not return a valid audio download.") }
            guard !state.withLock({ $0.cancelled }) else { throw CancellationError() }
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.moveItem(at: location, to: destination)
            finish(.success(destination))
        } catch { finish(.failure(error)) }
    }
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error { finish(.failure(error)) }; session.finishTasksAndInvalidate()
    }
    private func finish(_ result: Result<URL, any Error>) {
        let continuation = state.withLock { value -> CheckedContinuation<URL, any Error>? in
            guard !value.completed else { return nil }; value.completed = true; let continuation = value.continuation; value.continuation = nil; value.task = nil; return continuation
        }; continuation?.resume(with: result)
    }
}
