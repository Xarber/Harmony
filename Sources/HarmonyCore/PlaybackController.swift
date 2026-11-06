// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import Observation
import AVFoundation
import MediaPlayer
#if os(iOS)
import UIKit
#else
import AppKit
#endif

@MainActor @Observable public final class PlaybackController {
    public private(set) var queue = PlaybackQueue()
    public private(set) var currentTrack: Track?
    public private(set) var isPlaying = false
    public private(set) var position: Double = 0
    public private(set) var duration: Double = 0
    public private(set) var errorMessage: String?
    public private(set) var lyrics: LyricsDocument?
    public var sleepDeadline: Date?
    public var stopAfterTrack = false
    private let store: LibraryStore
    private let player = AVPlayer()
    private var periodic: Any?
    private var endObserver: NSObjectProtocol?
    private var errorObservation: NSKeyValueObservation?
    private var controlObservation: NSKeyValueObservation?
    private var notifications: [NSObjectProtocol] = []
    private var remoteTargets: [(MPRemoteCommand, Any)] = []
    private var loadGeneration = UUID()
    private var lastSavedSecond = -1
    private var resumeAfterInterruption = false
    public init(store: LibraryStore) {
        self.store = store
        periodic = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 600), queue: .main) { [weak self] time in
            MainActor.assumeIsolated { self?.tick(time.seconds) }
        }
        controlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let playing = player.timeControlStatus == .playing
            Task { @MainActor in self?.isPlaying = playing; self?.updateNowPlaying() }
        }
        configureRemoteCommands()
        #if os(iOS)
        notifications.append(NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor in
                guard let self else { return }
                if type == AVAudioSession.InterruptionType.began.rawValue { self.resumeAfterInterruption = self.isPlaying; self.pause() }
                else if self.resumeAfterInterruption && AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) { self.play() }
            }
        })
        notifications.append(NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            let reason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            if reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue { Task { @MainActor in self?.pause() } }
        })
        #endif
    }
    public func restore() async {
        do {
            if let saved = try await store.state(PlaybackQueue.self, key: "playback") {
                queue = saved; await load(autoplay: false); seek(to: saved.position)
            }
        } catch { errorMessage = error.localizedDescription }
    }
    public func start(_ tracks: [Track], at id: UUID? = nil) async {
        queue.replace(tracks.map(\.id), start: id.flatMap { wanted in tracks.firstIndex(where: { $0.id == wanted }) } ?? 0)
        await load(autoplay: true)
    }
    public func play() {
        guard player.currentItem != nil else { return }
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            if position >= duration - 0.05 { seek(to: 0) }
            player.play(); isPlaying = true; errorMessage = nil; updateNowPlaying()
        } catch { errorMessage = error.localizedDescription; isPlaying = false }
    }
    public func pause() { player.pause(); isPlaying = false; persist(); updateNowPlaying() }
    public func toggle() { isPlaying ? pause() : play() }
    public func seek(to seconds: Double) {
        guard seconds.isFinite else { return }
        let target = max(0, min(seconds, duration)); position = target; queue.position = target
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        persist(); updateNowPlaying()
    }
    public func next(automatic: Bool = false) async {
        if automatic && stopAfterTrack { stopAfterTrack = false; pause(); return }
        if queue.next(automatic: automatic) { await load(autoplay: true) } else { pause(); seek(to: 0) }
    }
    public func previous() async {
        if position > 3 { seek(to: 0); return }; queue.previous(); await load(autoplay: true)
    }
    public func setShuffle(_ enabled: Bool) { queue.shuffle = enabled; persist() }
    public func cycleRepeat() { queue.repeatMode = switch queue.repeatMode { case .off: .all; case .all: .one; case .one: .off }; persist() }
    public func add(_ id: UUID, next: Bool = false) { queue.append(id, next: next); persist() }
    public func removeQueueItem(_ id: UUID) async {
        let old = queue.current; queue.remove(id)
        if old != queue.current { await load(autoplay: isPlaying) }; persist()
    }
    public func moveQueueItem(from: Int, to: Int) { queue.move(from: from, to: to); persist() }
    public func clearQueue() { loadGeneration = UUID(); queue = PlaybackQueue(); player.replaceCurrentItem(with: nil); currentTrack = nil; isPlaying = false; position = 0; duration = 0; lyrics = nil; MPNowPlayingInfoCenter.default().nowPlayingInfo = nil; persist() }
    public func refreshLyrics() async { if let id = currentTrack?.id { lyrics = try? await store.lyrics(for: id) } }
    private func load(autoplay: Bool) async {
        let generation = UUID(); loadGeneration = generation
        player.pause(); isPlaying = false; position = 0; errorMessage = nil; currentTrack = nil; lyrics = nil
        player.replaceCurrentItem(with: nil)
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }; endObserver = nil
        errorObservation = nil
        guard let id = queue.current else { duration = 0; return }
        do {
            guard let track = try await store.track(id), let url = try await store.audioURL(for: id), FileManager.default.fileExists(atPath: url.path) else { throw HarmonyError.invalid("This track's audio is missing. Import the file to play it.") }
            let document = try await store.lyrics(for: id)
            guard generation == loadGeneration else { return }
            currentTrack = track; duration = track.duration ?? 0; lyrics = document
            let item = AVPlayerItem(url: url); player.replaceCurrentItem(with: item)
            errorObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                if item.status == .failed {
                    let message = item.error?.localizedDescription ?? "Playback failed."
                    Task { @MainActor in guard self?.loadGeneration == generation else { return }; self?.errorMessage = message; self?.pause() }
                }
            }
            endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in
                Task { @MainActor in guard let self, self.loadGeneration == generation else { return }; await self.next(automatic: true) }
            }
            if autoplay { play(); try await store.recordPlay(id) }
            persist(); updateNowPlaying()
        } catch { if generation == loadGeneration { errorMessage = error.localizedDescription; isPlaying = false } }
    }
    private func tick(_ time: Double) {
        guard time.isFinite else { return }; position = max(0, time); queue.position = position
        if let deadline = sleepDeadline, Date() >= deadline { sleepDeadline = nil; pause() }
        let second = Int(position)
        if second % 5 == 0 && second != lastSavedSecond { lastSavedSecond = second; persist(); updateNowPlaying() }
    }
    private func persist() {
        let saved = queue
        Task { do { try await store.setState(saved, key: "playback") } catch { errorMessage = error.localizedDescription } }
    }
    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        var info: [String: Any] = [MPMediaItemPropertyTitle: track.title, MPMediaItemPropertyArtist: track.artist ?? "Unknown artist", MPMediaItemPropertyAlbumTitle: track.album ?? "", MPMediaItemPropertyPlaybackDuration: duration, MPNowPlayingInfoPropertyElapsedPlaybackTime: position, MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0, MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue]
        if let path = track.artworkPath {
            let url = store.root.appendingPathComponent(path)
            #if os(iOS)
            if let image = UIImage(contentsOfFile: url.path) { info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image } }
            #else
            if let image = NSImage(contentsOf: url) { info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image } }
            #endif
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        #if os(macOS)
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
        #endif
    }
    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        func register(_ command: MPRemoteCommand, action: @escaping @MainActor () -> Void) {
            command.isEnabled = true
            let target = command.addTarget { _ in Task { @MainActor in action() }; return .success }
            remoteTargets.append((command, target))
        }
        register(center.playCommand) { [weak self] in self?.play() }
        register(center.pauseCommand) { [weak self] in self?.pause() }
        register(center.togglePlayPauseCommand) { [weak self] in self?.toggle() }
        register(center.nextTrackCommand) { [weak self] in Task { await self?.next() } }
        register(center.previousTrackCommand) { [weak self] in Task { await self?.previous() } }
        center.changePlaybackPositionCommand.isEnabled = true
        let target = center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let position = event.positionTime; Task { @MainActor in self?.seek(to: position) }; return .success
        }; remoteTargets.append((center.changePlaybackPositionCommand, target))
    }
    /// Explicit lifecycle end; app owns exactly one controller for its lifetime.
    public func shutdown() {
        pause(); if let periodic { player.removeTimeObserver(periodic) }; periodic = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }; endObserver = nil
        notifications.forEach { NotificationCenter.default.removeObserver($0) }; notifications = []
        remoteTargets.forEach { $0.0.removeTarget($0.1) }; remoteTargets = []; errorObservation = nil; controlObservation = nil
    }
}
