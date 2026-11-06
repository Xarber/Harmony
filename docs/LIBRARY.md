# Library and portable data

Normal storage is the application's Application Support/Harmony directory. iOS uses its app container. Audio, Artwork, Staging and Exports are distinct subdirectories; Library.sqlite is authoritative. The document picker is scoped only for the read/copy duration. Originals are never moved or deleted. The onboarding explains managed private storage; choosing arbitrary referenced library roots is not supported yet.

## Import

Local regular files must be nonempty, at most 2 GB and have a candidate native container. Harmony checks free space with a 50 MB safety margin, stages a copy, computes incremental SHA-256, verifies AVAsset playability plus an audio track and finite positive duration, reads common embedded title/artist/album/artwork, then moves into managed storage and commits a record. Cancellation is checked between stages and during hashing. A hash is rechecked after asynchronous metadata reads to prevent duplicate concurrent imports.

MP3, M4A, AAC, ALAC, WAV, AIFF, FLAC, MP4 and CAF are candidate containers, not a promise that every encoding works on every OS. AVFoundation runtime validation is decisive. Ogg/Vorbis and Opus require future licensed decoding or configured conversion; the app reports unsupported media and preserves the original.

Imported artwork is bounded at 15 MB. User-selected artwork accepts raster formats only, never SVG/HTML. The UI creates bounded ImageIO thumbnails and caches up to 32 MB. Sample rate and channel count are recorded when AVAudioFile can inspect them. Container is reported as container; source encoding, bitrate and bit depth are not fabricated.

## Storage integrity

SQLite uses WAL, foreign keys, bound parameters and immediate transactions. Metadata updates preserve earlier values in revisions; file tags remain untouched. Duplicate detection is byte identity, not title equality. An alternate encoding can exist as a separate track; automatic identity merging is not implemented.

Uncommitted staging files are disposable and removed when opening the library. A crash after atomic movement but before the database commit can leave an orphan managed file. A durable import-job journal, recovery UI and referenced security-scoped folders are roadmap items. Library record removal retains managed audio for recovery; it never deletes the original source. A physical-file purge/cleanup flow is not implemented.

## Export and restore

Settings → Export library metadata exports a versioned JSON document with tracks and ordered playlists. Artwork paths are stripped. Audio, artwork, lyrics, tokens and device-specific paths are excluded. Settings → Restore validates schema/project IDs and duplicate record IDs, then adds absent records transactionally and preserves existing records. Restored tracks without files remain unavailable; importing files does not yet automatically relink their restored IDs. Use playlist review to select a playable recording.

A song's menu exports a copy of its audio through the native save dialog. This preview limits in-app audio export to 256 MB to bound FileDocument memory usage. Exports remain separate from managed originals. A streaming full backup archive including audio, migration to another device with automatic file relinking and unrestricted large audio export are not implemented. Do not treat metadata-only JSON as a full music backup.

Playlist JSON, CSV, M3U8 and XSPF exports are available from playlist menus. Paths are references, not permission to read external files. Third-party lyrics/artwork are not silently redistributed in library metadata exports.
