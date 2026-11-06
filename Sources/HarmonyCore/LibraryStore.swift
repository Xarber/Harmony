// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
import AVFoundation
import CryptoKit

public struct ImportResult: Sendable { public var track: Track; public var duplicate: Bool }

public actor LibraryStore {
    public let root: URL
    private let db: Database
    public init(root: URL) throws {
        self.root = root
        for directory in ["Audio", "Artwork", "Staging", "Exports"] { try FileManager.default.createDirectory(at: root.appendingPathComponent(directory), withIntermediateDirectories: true) }
        db = try Database(url: root.appendingPathComponent("Library.sqlite"))
        // Interrupted copies never enter the database; only disposable staging files are removed.
        for url in try FileManager.default.contentsOfDirectory(at: root.appendingPathComponent("Staging"), includingPropertiesForKeys: nil) { try FileManager.default.removeItem(at: url) }
    }
    public func tracks(search: String = "", limit: Int = 500, offset: Int = 0) throws -> [Track] {
        let query = "%" + search.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "%", with: "\\%").replacingOccurrences(of: "_", with: "\\_") + "%"
        return try db.rows("SELECT json FROM tracks WHERE title LIKE ? ESCAPE '\\' OR artist LIKE ? ESCAPE '\\' OR album LIKE ? ESCAPE '\\' ORDER BY title COLLATE NOCASE LIMIT ? OFFSET ?", [query, query, query, String(max(1, min(limit, 100_000))), String(max(0, offset))]).map { try decode(Track.self, $0[0]) }
    }
    public func count() throws -> Int { Int(try db.rows("SELECT COUNT(*) FROM tracks")[0][0]) ?? 0 }
    public func track(_ id: UUID) throws -> Track? { try db.rows("SELECT json FROM tracks WHERE id=?", [id.uuidString]).first.map { try decode(Track.self, $0[0]) } }
    public func files(for id: UUID) throws -> [AudioFile] { try db.rows("SELECT json FROM audio_files WHERE track_id=?", [id.uuidString]).map { try decode(AudioFile.self, $0[0]) } }
    public func audioURL(for id: UUID) throws -> URL? { try files(for: id).first.map { try managedURL($0.relativePath) } }
    public func managedURL(_ path: String) throws -> URL {
        guard !path.hasPrefix("/"), !path.split(separator: "/").contains("..") else { throw HarmonyError.invalid("Unsafe managed file path.") }
        let url = root.appendingPathComponent(path).standardizedFileURL.resolvingSymlinksInPath()
        guard url.path.hasPrefix(root.standardizedFileURL.resolvingSymlinksInPath().path + "/") else { throw HarmonyError.invalid("File escapes the managed library.") }; return url
    }
    private func saveTrack(_ track: Track) throws {
        try db.execute("INSERT INTO tracks(id,title,artist,album,json) VALUES(?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET title=excluded.title,artist=excluded.artist,album=excluded.album,json=excluded.json", [track.id.uuidString, track.title, track.artist, track.album, try encode(track)])
    }
    public func update(_ track: Track) throws {
        guard !track.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw HarmonyError.invalid("A track needs a title.") }
        if let artworkPath = track.artworkPath { _ = try managedURL(artworkPath) }
        try db.transaction {
            if let old = try self.track(track.id) { try db.execute("INSERT INTO metadata_revisions(track_id,json) VALUES(?,?)", [track.id.uuidString, try encode(old)]) }
            try saveTrack(track)
        }
    }
    public func importAudio(_ source: URL) async throws -> ImportResult {
        let access = source.startAccessingSecurityScopedResource(); defer { if access { source.stopAccessingSecurityScopedResource() } }
        guard source.isFileURL else { throw HarmonyError.invalid("Select a local audio file.") }
        let values = try source.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true, let size = values.fileSize, size > 0, size <= 2_000_000_000 else { throw HarmonyError.invalid("Select a regular audio file smaller than 2 GB.") }
        let available = try root.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage ?? Int64.max
        guard available > Int64(size) + 50_000_000 else { throw HarmonyError.storage("Not enough free space to safely import this file.") }
        guard !CodecRegistry.requiresConversion(source.pathExtension) else { throw HarmonyError.unsupported("This container requires backend conversion. Original file preserved.") }
        let staging = root.appendingPathComponent("Staging/\(UUID()).\(source.pathExtension.lowercased())")
        try FileManager.default.copyItem(at: source, to: staging)
        defer { try? FileManager.default.removeItem(at: staging) }
        let hash = try Self.digest(staging)
        if let row = try db.rows("SELECT track_id FROM audio_files WHERE sha256=?", [hash]).first,
           let id = UUID(uuidString: row[0]), let existing = try track(id) { return ImportResult(track: existing, duplicate: true) }
        try Task.checkCancellation()
        let asset = AVURLAsset(url: staging)
        let playable = try await asset.load(.isPlayable)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard playable, !audioTracks.isEmpty else { throw HarmonyError.unsupported("AVFoundation cannot play audio in this file on this device.") }
        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0 else { throw HarmonyError.invalid("Audio has no valid duration.") }
        var track = Track(title: source.deletingPathExtension().lastPathComponent, duration: duration)
        track.provenance["title"] = "Filename"
        let metadata = try await asset.load(.commonMetadata)
        var artwork: Data?
        for item in metadata {
            switch item.commonKey {
            case .commonKeyTitle: if let value = try await item.load(.stringValue), !value.isEmpty { track.title = value; track.provenance["title"] = "Embedded tags" }
            case .commonKeyArtist: track.artist = try await item.load(.stringValue); track.provenance["artist"] = "Embedded tags"
            case .commonKeyAlbumName: track.album = try await item.load(.stringValue); track.provenance["album"] = "Embedded tags"
            case .commonKeyArtwork: artwork = try await item.load(.dataValue)
            default: break
            }
        }
        try Task.checkCancellation()
        // Recheck after suspension: another import may have committed the same bytes.
        if let row = try db.rows("SELECT track_id FROM audio_files WHERE sha256=?", [hash]).first,
           let id = UUID(uuidString: row[0]), let existing = try self.track(id) { return ImportResult(track: existing, duplicate: true) }
        let relative = "Audio/\(UUID()).\(source.pathExtension.lowercased())"
        let destination = try managedURL(relative)
        try FileManager.default.moveItem(at: staging, to: destination)
        if let artwork, artwork.count < 15_000_000 {
            let path = "Artwork/\(UUID()).image"
            try artwork.write(to: managedURL(path), options: .atomic); track.artworkPath = path
        }
        let inspected = try? AVAudioFile(forReading: destination)
        let file = AudioFile(trackID: track.id, relativePath: relative, originalName: source.lastPathComponent, sha256: hash, byteCount: Int64(size), container: source.pathExtension.lowercased(), sampleRate: inspected?.fileFormat.sampleRate, channels: inspected.map { Int($0.fileFormat.channelCount) })
        do {
            try db.transaction {
                try saveTrack(track)
                try db.execute("INSERT INTO audio_files(id,track_id,sha256,json) VALUES(?,?,?,?)", [file.id.uuidString, track.id.uuidString, hash, try encode(file)])
            }
        } catch { try? FileManager.default.removeItem(at: destination); throw error }
        return ImportResult(track: track, duplicate: false)
    }
    public static func digest(_ url: URL) throws -> String {
        let file = try FileHandle(forReadingFrom: url); defer { try? file.close() }
        var hash = SHA256()
        while let data = try file.read(upToCount: 1_048_576), !data.isEmpty { try Task.checkCancellation(); hash.update(data: data) }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
    public func playlists() throws -> [Playlist] { try db.rows("SELECT json FROM playlists ORDER BY rowid DESC").map { try decode(Playlist.self, $0[0]) } }
    public func save(_ playlist: Playlist) throws { try db.execute("INSERT INTO playlists(id,json) VALUES(?,?) ON CONFLICT(id) DO UPDATE SET json=excluded.json", [playlist.id.uuidString, try encode(playlist)]) }
    public func deletePlaylist(_ id: UUID) throws { try db.execute("DELETE FROM playlists WHERE id=?", [id.uuidString]) }
    public func lyrics(for id: UUID) throws -> LyricsDocument? { try db.rows("SELECT json FROM lyrics WHERE track_id=?", [id.uuidString]).first.map { try decode(LyricsDocument.self, $0[0]) } }
    public func saveLyrics(_ document: LyricsDocument, for id: UUID) throws {
        try db.transaction {
            if let old = try lyrics(for: id) { try db.execute("INSERT INTO lyrics_revisions(track_id,json) VALUES(?,?)", [id.uuidString, try encode(old)]) }
            try db.execute("INSERT INTO lyrics(track_id,json) VALUES(?,?) ON CONFLICT(track_id) DO UPDATE SET json=excluded.json", [id.uuidString, try encode(document)])
        }
    }
    public func setState<T: Encodable & Sendable>(_ value: T, key: String) throws { try db.execute("INSERT INTO state(key,json) VALUES(?,?) ON CONFLICT(key) DO UPDATE SET json=excluded.json", [key, try encode(value)]) }
    public func state<T: Decodable & Sendable>(_ type: T.Type, key: String) throws -> T? { try db.rows("SELECT json FROM state WHERE key=?", [key]).first.map { try decode(type, $0[0]) } }
    public func ideas() throws -> [Idea] { try db.rows("SELECT json FROM ideas ORDER BY rowid DESC").map { try decode(Idea.self, $0[0]) } }
    public func saveIdea(_ idea: Idea) throws { try db.execute("INSERT INTO ideas(id,json) VALUES(?,?) ON CONFLICT(id) DO UPDATE SET json=excluded.json", [idea.id.uuidString, try encode(idea)]) }
    public func deleteIdea(_ id: UUID) throws { try db.execute("DELETE FROM ideas WHERE id=?", [id.uuidString]) }
    public func importIdeas(_ collection: IdeasExport) throws -> Int {
        let incoming = try collection.validated(); let existing = Set(try ideas().map(\.id)); var added = 0
        try db.transaction { for idea in incoming where !existing.contains(idea.id) { try saveIdea(idea); added += 1 } }; return added
    }
    public func recordPlay(_ id: UUID) throws {
        guard var value = try track(id) else { return }; value.playCount += 1; value.lastPlayedAt = Date(); try saveTrack(value)
    }
    public func artworkURL(for track: Track) throws -> URL? { try track.artworkPath.map(managedURL) }
    public func setArtwork(_ source: URL, for id: UUID) throws {
        guard var track = try track(id) else { return }
        let access = source.startAccessingSecurityScopedResource(); defer { if access { source.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: source)
        guard data.count <= 15_000_000, ["png", "jpg", "jpeg", "heic", "webp"].contains(source.pathExtension.lowercased()) else { throw HarmonyError.invalid("Select a PNG, JPEG, HEIC, or WebP image smaller than 15 MB.") }
        let path = "Artwork/\(UUID()).\(source.pathExtension)"; try data.write(to: managedURL(path), options: .atomic)
        track.artworkPath = path; track.provenance["artwork"] = "User selected"; try update(track)
    }
    public func removeTrack(_ id: UUID) throws {
        // Only remove database ownership. Retain managed audio for recovery; never touch original files.
        try db.execute("DELETE FROM tracks WHERE id=?", [id.uuidString])
    }
    public func exportAudio(_ id: UUID) throws -> URL {
        guard let file = try files(for: id).first else { throw HarmonyError.invalid("Audio is unavailable.") }
        let output = root.appendingPathComponent("Exports/\(file.id).\(file.container)")
        if !FileManager.default.fileExists(atPath: output.path) { try FileManager.default.copyItem(at: managedURL(file.relativePath), to: output) }; return output
    }
    func restoreValidatedMetadata(_ backup: LibraryMetadataBackup) throws -> Int {
        var added = 0
        let existingPlaylists = Set(try playlists().map(\.id))
        try db.transaction {
            for var value in backup.tracks where try track(value.id) == nil {
                value.artworkPath = nil; try saveTrack(value); added += 1
            }
            for playlist in backup.playlists where !existingPlaylists.contains(playlist.id) { try save(playlist) }
        }; return added
    }
    func resetHistory() throws {
        try db.transaction {
            for var value in try tracks(limit: 100_000) { value.playCount = 0; value.lastPlayedAt = nil; try saveTrack(value) }
        }
    }

}
