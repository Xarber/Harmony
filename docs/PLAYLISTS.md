# Playlist parsing, review and management

Supported imports: extended M3U/M3U8, PLS, CSV, XSPF, Harmony JSON and pasted Artist — Title lines. Imports are UTF-8, bounded to 10 MB, preserve order and maintain distinct entry IDs for duplicate occurrences. HLS `#EXT-X-` manifests are rejected. CSV supports escaped quotes, embedded commas and newlines. XSPF external entity resolution is disabled; DOCTYPE/ENTITY declarations are rejected. Paths are retained as metadata only and never traversed automatically.

CSV requires a title header; artist, duration (seconds) and path are optional. XSPF duration is milliseconds. Harmony JSON uses the Codable Playlist/PlaylistEntry schema. A saved playlist has UUID, name, description and ordered entries; entries have their own UUID, optional local trackID, title, artist, duration, source path and optional recording identifiers. Duplicate occurrence IDs in JSON are invalid.

## Matching

Normalization handles case, diacritics and punctuation without removing version words. Title-only matches have confidence 0.35 and are never exact. Title+artist remains a probable match (0.75, or 0.89 with duration). Matching ISRC/recording ID plus duration within two seconds is exact. An identifier without agreeing duration is 0.92 but requires review. Multiple exact candidates are not auto-selected. Confidence is a heuristic explanation, not a measured probability.

The preview supports per-entry inclusion, all/none and choosing among local candidates or metadata-only. Only one uniquely exact candidate is preselected. Saving preserves original order and intentional duplicates. Missing audio remains visible; playlist import never implies acquisition rights or downloads protected subscription streams.

Matching does not yet consider album/release relationships, fingerprints, sophisticated featuring-credit normalization or source-provider IDs. Manual review remains necessary. Playlist-relative paths do not automatically locate/import neighboring files; select audio through Files.

## Management

Create, rename, edit description, add, remove, reorder, duplicate, play available entries and export JSON/CSV/M3U8/XSPF. iOS exposes Edit controls; Mac list reordering relies on supported list interactions. Genre/favorite/recent groupings are built-in queries, not editable smart playlists. Playlist merge, artwork and a smart-rule builder are not implemented. Playback from a generic TrackRow currently uses the library sequence; the playlist's Play available tracks action respects playlist order.

## Online providers

Spotify, MusicKit, YouTube and SoundCloud playlist adapters are not implemented or authorized in this preview. Spotify's 2026 developer restrictions must be reviewed against the actual application registration before implementation. File-based import remains available independently. MusicKit requires user authorization and an appropriate developer setup; subscription audio stays separate from independently owned files.

Official references checked during initial implementation:
- https://developer.spotify.com/blog/2026-02-06-update-on-developer-access-and-platform-security
- https://developer.apple.com/documentation/applemusicapi/user-authentication-for-musickit
- https://developer.apple.com/documentation/musickit/musicauthorization/request%28%29
