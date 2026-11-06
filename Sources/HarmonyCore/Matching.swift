// SPDX-License-Identifier: AGPL-3.0-only
import Foundation
public struct MatchCandidate: Identifiable, Sendable {
    public var id: UUID { track.id }
    public var track: Track
    public var confidence: Double
    public var explanation: String
    public var exact: Bool
}
public enum TrackMatcher {
    public static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }
    public static func candidates(for entry: PlaylistEntry, in tracks: [Track]) -> [MatchCandidate] {
        tracks.compactMap { track in
            let durationAgrees = entry.duration.flatMap { duration in track.duration.map { abs(duration - $0) <= 2 } } ?? false
            let identifier = (entry.isrc != nil && entry.isrc?.uppercased() == track.isrc?.uppercased()) || (entry.recordingID != nil && entry.recordingID == track.recordingID)
            if identifier {
                return MatchCandidate(track: track, confidence: durationAgrees ? 1 : 0.92, explanation: durationAgrees ? "Recording identifier and duration agree" : "Recording identifier agrees; review duration", exact: durationAgrees)
            }
            guard normalized(entry.title) == normalized(track.title) else { return nil }
            let artistAgrees = entry.artist.map { !$0.isEmpty && normalized($0) == normalized(track.artist ?? "") } ?? false
            return MatchCandidate(track: track, confidence: artistAgrees ? (durationAgrees ? 0.89 : 0.75) : 0.35,
                                  explanation: artistAgrees ? "Title and artist agree; recording requires confirmation" : "Title only; insufficient recording evidence", exact: false)
        }.sorted { $0.confidence > $1.confidence }
    }
}
