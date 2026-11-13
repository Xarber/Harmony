# Architecture

Harmony has a native SwiftUI application and a browser PWA. The browser owns its own IndexedDB library and HTML media player. See [Web application](WEB.md). iOS/iPadOS 17+ are primary; macOS 14+ shares the same source and is currently the validated runtime. Swift tools minimum is 6.2; initial compilation used Swift 6.4 and the existing stable macOS 26.5 SDK. No third-party runtime dependencies were added. System SQLite, AVFoundation, MediaPlayer, CryptoKit, Observation and SwiftUI provide the core.

## Ownership and boundaries

`HarmonyApp` creates one `AppModel`, `LibraryStore` and `PlaybackController`. SwiftUI views display state and submit actions. The store actor owns the SQLite connection and managed file operations. Playback is main-actor isolated because it coordinates UI and Apple media APIs. Pure parsers, matching and queue models are Sendable values usable independently of UI.

Modules are source files in `Sources/HarmonyCore`: models, database, library storage, backup, parsers, matching, playback queue/controller, providers and downloads. `Sources/HarmonyApp` contains app lifecycle and focused view groups. The iOS Xcode target consumes the local HarmonyCore package. The package executable runs the same UI on Mac.

The app enables Swift 6 checking and main-actor default isolation for its UI target. General-purpose core APIs retain explicit isolation. The small SQLite binding is intentionally confined to an actor; prepared statements, foreign keys and transactions are tested. It is not a replacement for a comprehensive database ORM.

## Schema 1

- `tracks`: recording metadata JSON plus indexed title/artist/album columns.
- `audio_files`: separately identified managed audio copies, recording foreign key, unique SHA-256 and technical metadata JSON.
- `playlists`: ordered entry values with independent occurrence IDs and optional track references. Repeated occurrences and missing audio survive.
- `lyrics`, `lyrics_revisions`, `metadata_revisions`: latest documents and recoverable prior values.
- `ideas`: isolated developer feedback domain, not playlists/history.
- `state`: typed versioned application state such as playback restoration.

Artist and album display groupings currently derive from track fields; separate normalized Artist/Album/RecordingIdentity tables, FTS and a fully lazy UI are not implemented. These are recorded limitations, not completed schema goals. The current app reloads at most 100,000 records and sequentially loads audio references; large-library performance remains unmeasured.

## Extensibility

`MetadataProvider` and `AcquisitionBackend` define narrow, typed extension points. Codec capabilities and pure parsing are separate from views. Future lyrics providers, transports and host-controlled screen registries can be added without replacing playback or storage. No arbitrary-code plugin loader, sandbox, marketplace or runtime is implemented.

## Errors and lifecycle

Newer database schema versions are rejected without downgrading. Storage initialization failure shows a recoverable error rather than recreating/deleting a database. Imports copy into disposable staging, inspect audio, hash bytes and move atomically on the same volume before committing a record. Orphan cleanup and transactional file journaling still need hardening for a crash after file movement. Player operations use generation IDs to discard stale asynchronous track loads. Paused queue restoration never starts audio unexpectedly.

See the roadmap for known gaps. No complete-application audit or production readiness is claimed.
