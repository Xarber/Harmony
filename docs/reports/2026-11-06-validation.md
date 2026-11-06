# Harmony implementation and validation report

Date: 2026-11-06. Scope: newly created Harmony Swift core, shared SwiftUI application, iOS project/build preparation and associated documentation. This is not a completed-product audit.

## Implemented slice

Managed audio import and separate audio-file records; actor-owned SQLite; playback/queue/restoration; local library browsing/search/playlists; playlist parsers and confidence review; database metadata editing; artwork selection/thumbnails; local LRC; explicit MusicBrainz adapter; direct download and proposed Fetch client; metadata backup/restore; developer Ideas/changelog. Exact completeness is in ROADMAP.md.

## Executed environment and checks

- Apple Silicon Mac; Swift 6.4; existing macOS 26.5 SDK; deployment target macOS 14.
- `scripts/check.sh`: **21 tests in 7 suites passed**, including four parameterized playlist export formats. Full sanitized output: automated-test-output.txt.
- Original generated WAV import, duration validation, duplicate hashing, preserved source bytes, database reopening/search/edit and byte-identical individual audio export passed.
- Real M4A created with AVFoundation: embedded title/artist/album read correctly and provenance reported embedded tags.
- Actual AVPlayer playback: clock advanced, pause held position, seek and resume worked, queue restored paused.
- Playlist order/duplicate occurrences, M3U/M3U8, PLS, XSPF, CSV quoting/newlines, JSON round trips and plain-list parsing passed.
- Matching title-only never exact, recording-ID/duration confidence, meaningful live-version distinction and Unicode normalization passed.
- LRC timestamps, repeated timestamps, offsets, invalid seconds, plain lyrics and timing/export passed.
- Traversal and malformed audio rejected; HLS and XML entities rejected; duplicate JSON entry IDs rejected; unsafe download/Fetch URLs rejected before network access.
- Metadata backup adds missing records while retaining existing records; no restored audio falsely appears available.
- Ideas safe merge, schema rejection, persistent revisions/status history and developer triple-tap/activity/expiry model passed.
- Future SQLite schema rejected without resetting its version.
- macOS SwiftUI executable builds and launches via scripts/run-mac.sh.
- Xcode project and Info.plist pass `plutil -lint`; app icon verified as 1024×1024, with no alpha after export correction. These are structural checks, not iOS build proof.

## Observed desktop UI flows

Used a debug-only isolated `.build/QA-Library` with original low-volume synthesized audio and original authored lyric lines. No production music/history was seeded.

1. Onboarding and empty-library view displayed.
2. Files picker imported First Light.wav; a 12-second track appeared.
3. Selecting it started playback; Now Playing showed Pause and the actual clock reached 0:08 of 0:12.
4. Metadata & Lyrics saved artist OpenRecode QA, album Original test recordings and original LRC text; the album count became one.
5. After app restart, track/artist/album and paused playback position were restored.
6. Lyrics view displayed saved lines. Tapping the line at 0:04 changed playback position to 4 seconds while paused.

These observations establish selected Mac UI behavior only. No screenshot mockup was passed off as a functioning application.

## Problems found and corrections

- CLT's 27.0 SwiftUI SDK referenced a missing macro plugin. Used the stable 26.5 SDK already present, with local test-framework flags. Installed no SDK or emulator.
- Initial SwiftPM test discovery/build lacked the Testing framework under the native build-system fallback; the check script supplies the existing CLT framework path.
- Corrected a missing throwing-call marker and mutating-expression test macro usage; subsequent suite passed.
- Added a newer-database-schema guard, safe JSON occurrence validation, persistent Ideas revisions, current-playback metadata refresh and one-transfer start guard during review.
- Bounded individual FileDocument audio exports to 256 MB and cached resized artwork to avoid unbounded UI decode costs.
- Converted icon export to exact pixel dimensions and opaque output. Visual inspection caught a black image from an unsupported RGB bitmap context; an explicit opaque Core Graphics context corrected it and the final raster was visually verified. Editable SVG source remains layered.

## Unavailable or unexecuted

Full Xcode was unavailable because its external-disk symlink target was disconnected. No iOS compile, simulator launch, IPA, simulator app artifact, physical iPhone/iPad test, signed build, notarization, release, deploy or remote CI run was completed. The GitHub workflow is prepared only. Android is not targeted.

No live Spotify/MusicKit/AcoustID/LRCLIB, MusicBrainz response, Fetch handshake, direct HTTPS media transfer, backend worker, provider OAuth or processing integration was verified. No invented service or performance benchmark is reported. Large-library, accessibility audit, memory/battery, long background audio and complete native error/recovery testing remain open.

## Git, publication and cleanup

Development is committed on testing; beta/main retain repository-foundation baseline and are not promoted. Git's configured hardware-backed signature failed because the key was unavailable; commits were created unsigned per invocation without changing global signing settings or identity. No remote is configured or pushed; repository/publication/deployment was explicitly prohibited without authorization. No temporary branches or worktrees were created, so none required deletion. Original media remains preserved.
