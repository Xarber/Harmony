// SPDX-License-Identifier: AGPL-3.0-only
import Foundation

public struct Track: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID = UUID()
    public var title: String
    public var artist: String?
    public var album: String?
    public var albumArtist: String?
    public var genre: String?
    public var composer: String?
    public var trackNumber: Int?
    public var discNumber: Int?
    public var releaseDate: String?
    public var isrc: String?
    public var recordingID: String?
    public var releaseID: String?
    public var duration: Double?
    public var favorite = false
    public var rating: Int?
    public var comments: String?
    public var addedAt = Date()
    public var playCount = 0
    public var lastPlayedAt: Date?
    public var artworkPath: String?
    public var provenance: [String: String] = [:]
    public init(title: String, artist: String? = nil, album: String? = nil, duration: Double? = nil) {
        self.title = title; self.artist = artist; self.album = album; self.duration = duration
    }
}

public struct AudioFile: Identifiable, Codable, Hashable, Sendable {
    public var id = UUID()
    public var trackID: UUID
    public var relativePath: String
    public var originalName: String
    public var sha256: String
    public var byteCount: Int64
    public var container: String
    public var sampleRate: Double?
    public var channels: Int?
    public init(trackID: UUID, relativePath: String, originalName: String, sha256: String, byteCount: Int64, container: String, sampleRate: Double? = nil, channels: Int? = nil) {
        self.trackID = trackID; self.relativePath = relativePath; self.originalName = originalName
        self.sha256 = sha256; self.byteCount = byteCount; self.container = container
        self.sampleRate = sampleRate; self.channels = channels
    }
}

public struct PlaylistEntry: Identifiable, Codable, Hashable, Sendable {
    public var id = UUID()
    public var trackID: UUID?
    public var title: String
    public var artist: String?
    public var duration: Double?
    public var sourcePath: String?
    public var isrc: String?
    public var recordingID: String?
    public init(title: String, artist: String? = nil, trackID: UUID? = nil, duration: Double? = nil, sourcePath: String? = nil) {
        self.title = title; self.artist = artist; self.trackID = trackID; self.duration = duration; self.sourcePath = sourcePath
    }
}
public struct Playlist: Identifiable, Codable, Hashable, Sendable {
    public var id = UUID()
    public var name: String
    public var description: String = ""
    public var entries: [PlaylistEntry]
    public init(name: String, entries: [PlaylistEntry] = []) { self.name = name; self.entries = entries }
}
public struct LyricLine: Identifiable, Codable, Hashable, Sendable {
    public var id = UUID()
    public var time: Double?
    public var text: String
    public init(time: Double?, text: String) { self.time = time; self.text = text }
}
public struct LyricsDocument: Codable, Sendable {
    public var raw: String
    public var offset: Double = 0
    public var source = "User import"
    public var updatedAt = Date()
    public init(raw: String, offset: Double = 0) { self.raw = raw; self.offset = offset }
    public var lines: [LyricLine] { LRC.parse(raw) }
    public func activeIndex(at seconds: Double) -> Int? {
        lines.lastIndex { line in line.time.map { $0 + offset <= seconds } ?? false }
    }
}
public enum IdeaStatus: String, Codable, CaseIterable, Sendable {
    case pending, approved, deferred, inProgress, implemented, rejected
}
public struct Idea: Identifiable, Codable, Hashable, Sendable {
    public var id = UUID()
    public var title: String
    public var description: String
    public var category = "Improvement"
    public var priority = "Normal"
    public var status: IdeaStatus = .pending
    public var createdAt = Date()
    public var updatedAt = Date()
    public var implementationReference: String?
    public init(title: String, description: String = "") { self.title = title; self.description = description }
}
public struct IdeasExport: Codable, Sendable {
    public var schemaVersion = 1
    public var project = "it.xarber.harmony"
    public var exportedAt = Date()
    public var ideas: [Idea]
    public init(ideas: [Idea]) { self.ideas = ideas }
    public func validated() throws -> [Idea] {
        guard schemaVersion == 1, project == "it.xarber.harmony", ideas.count <= 10_000,
              Set(ideas.map(\.id)).count == ideas.count, ideas.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw HarmonyError.invalid("Invalid or incompatible Ideas collection.")
        }
        return ideas
    }
}
public enum HarmonyError: LocalizedError, Sendable {
    case invalid(String), storage(String), unsupported(String)
    public var errorDescription: String? { switch self { case .invalid(let s), .storage(let s), .unsupported(let s): s } }
}
public enum CodecRegistry {
    public static let nativeCandidates: Set<String> = ["mp3", "m4a", "aac", "alac", "wav", "aiff", "aif", "flac", "mp4", "caf"]
    public static func requiresConversion(_ ext: String) -> Bool { !nativeCandidates.contains(ext.lowercased()) }
    // Every candidate must additionally pass AVAsset's runtime audio/playability validation.
}
