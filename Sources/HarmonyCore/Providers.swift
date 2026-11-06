// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
public struct MetadataCandidate: Identifiable, Codable, Sendable {
    public var id: String
    public var title: String
    public var artist: String?
    public var duration: Double?
}
public protocol MetadataProvider: Sendable {
    func search(title: String, artist: String?) async throws -> [MetadataCandidate]
}
/// Explicit user searches only. Each instance enforces one request per second.
public actor MusicBrainzProvider: MetadataProvider {
    public static let shared = MusicBrainzProvider()
    private var nextRequest = Date.distantPast
    public init() {}
    public func search(title: String, artist: String?) async throws -> [MetadataCandidate] {
        let slot = max(Date(), nextRequest)
        nextRequest = slot.addingTimeInterval(1.1)
        let delay = slot.timeIntervalSinceNow
        if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
        func escaped(_ text: String) -> String { text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") }
        var components = URLComponents(string: "https://musicbrainz.org/ws/2/recording/")!
        let query = "recording:\"\(escaped(title))\"" + (artist.map { " AND artist:\"\(escaped($0))\"" } ?? "")
        components.queryItems = [URLQueryItem(name: "query", value: query), URLQueryItem(name: "fmt", value: "json"), URLQueryItem(name: "limit", value: "12")]
        var request = URLRequest(url: components.url!); request.timeoutInterval = 25
        request.setValue("Harmony/0.1.0 (OpenRecode; https://github.com/Xarber)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200, data.count <= 5_000_000 else { throw HarmonyError.invalid("MusicBrainz is unavailable or rate limited. Your local metadata is unchanged.") }
        struct Response: Decodable {
            struct Recording: Decodable {
                struct Credit: Decodable { struct Artist: Decodable { var name: String }; var artist: Artist }
                var id: String; var title: String; var length: Double?; var artistCredit: [Credit]?
                enum CodingKeys: String, CodingKey { case id, title, length; case artistCredit = "artist-credit" }
            }
            var recordings: [Recording]
        }
        return try JSONDecoder().decode(Response.self, from: data).recordings.map { MetadataCandidate(id: $0.id, title: $0.title, artist: $0.artistCredit?.map(\.artist.name).joined(separator: ", "), duration: $0.length.map { $0 / 1000 }) }
    }
}

/// Versioned proposed Fetch contract. Not a claim of compatibility with any existing server.
public struct FetchCapabilities: Codable, Sendable { public var protocolVersion: Int; public var audioFormats: [String]; public var cancellation: Bool }
public struct FetchJob: Identifiable, Codable, Sendable { public var id: String; public var status: String; public var progress: Double?; public var artifactPath: String? }
public protocol AcquisitionBackend: Sendable {
    func capabilities() async throws -> FetchCapabilities
    func create(source: URL, format: String, authorized: Bool) async throws -> FetchJob
    func job(_ id: String) async throws -> FetchJob
    func cancel(_ id: String) async throws
}
public struct FetchAdapter: AcquisitionBackend {
    public let baseURL: URL
    private let token: String
    public init(baseURL: URL, token: String) throws {
        guard baseURL.scheme == "https", baseURL.host != nil, baseURL.user == nil, baseURL.password == nil else { throw HarmonyError.invalid("Use an HTTPS server address without embedded credentials.") }
        self.baseURL = baseURL; self.token = token
    }
    private func request(_ path: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/v1/" + path)); request.httpMethod = method; request.httpBody = body; request.timeoutInterval = 30
        request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization"); request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config, delegate: NoRedirectDelegate(), delegateQueue: nil); defer { session.invalidateAndCancel() }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), data.count <= 5_000_000 else { throw HarmonyError.invalid("Fetch rejected the request or returned an invalid response.") }; return data
    }
    public func capabilities() async throws -> FetchCapabilities { let value = try JSONDecoder().decode(FetchCapabilities.self, from: await request("capabilities")); guard value.protocolVersion == 1 else { throw HarmonyError.unsupported("Incompatible Fetch protocol.") }; return value }
    public func create(source: URL, format: String, authorized: Bool) async throws -> FetchJob {
        guard authorized, source.scheme == "https", source.user == nil, source.password == nil else { throw HarmonyError.invalid("Confirm authorization and use an HTTPS source URL.") }
        let caps = try await capabilities(); guard caps.audioFormats.contains(format) else { throw HarmonyError.unsupported("Worker does not support this format.") }
        let body = try JSONSerialization.data(withJSONObject: ["sourceURL": source.absoluteString, "format": format, "authorized": true])
        return try JSONDecoder().decode(FetchJob.self, from: await request("downloads", method: "POST", body: body))
    }
    public func job(_ id: String) async throws -> FetchJob { guard Self.safeID(id) else { throw HarmonyError.invalid("Invalid job ID.") }; return try JSONDecoder().decode(FetchJob.self, from: await request("downloads/" + id)) }
    public func cancel(_ id: String) async throws { guard Self.safeID(id) else { throw HarmonyError.invalid("Invalid job ID.") }; _ = try await request("downloads/" + id, method: "DELETE") }
    private static func safeID(_ id: String) -> Bool { !id.isEmpty && id.count < 128 && id.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_" )).contains($0) } }
}
final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) { completionHandler(nil) }
}
