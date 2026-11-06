// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
public struct LibraryMetadataBackup: Codable, Sendable {
    public var schemaVersion = 1
    public var project = "it.xarber.harmony"
    public var exportedAt = Date()
    public var tracks: [Track]
    public var playlists: [Playlist]
    public init(tracks: [Track], playlists: [Playlist]) { self.tracks = tracks; self.playlists = playlists }
}
extension LibraryStore {
    public func exportMetadata() throws -> Data {
        var values = try tracks(limit: 100_000)
        for index in values.indices { values[index].artworkPath = nil }
        return try JSONEncoder().encode(LibraryMetadataBackup(tracks: values, playlists: playlists()))
    }
    public func restoreMetadata(_ data: Data) throws -> Int {
        guard data.count <= 50_000_000 else { throw HarmonyError.invalid("Backup exceeds 50 MB.") }
        let backup = try JSONDecoder().decode(LibraryMetadataBackup.self, from: data)
        guard backup.schemaVersion == 1, backup.project == "it.xarber.harmony", backup.tracks.count <= 100_000,
              Set(backup.tracks.map(\.id)).count == backup.tracks.count,
              Set(backup.playlists.map(\.id)).count == backup.playlists.count,
              backup.tracks.allSatisfy({ !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw HarmonyError.invalid("Invalid backup schema or duplicate identifiers.") }
        // Validate every record before changing the database. Managed paths never come from a backup.
        return try restoreValidatedMetadata(backup)
    }
    public func clearHistory() throws { try resetHistory() }
}
