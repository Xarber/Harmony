# Feature status and remaining roadmap

Status date: 2026-11-06. This is a functioning local-first development slice, **not the complete Harmony product and not release-ready**. The brief explicitly prioritizes phases 1–3, then metadata, lyrics, playlist imports and downloads when the whole scope cannot be completed in one execution. Native iOS validation is blocked by unavailable full Xcode, not by a demonstrated successful iOS build.

| Area | Status | Evidence and limits |
| --- | --- | --- |
| SwiftUI app and shared Apple core | Implemented and tested on macOS | App builds, launches and shows working library/player/editor flows. iOS target prepared; not compiled here. |
| Persistent music library | Implemented and tested | SQLite reopening, edits, search, copies and hashes tested. Full normalized artist/album model and large-library benchmarks pending. |
| Files audio importer | Implemented and tested on macOS | Real WAV and tagged M4A imports, duplicate hashing, preserved originals, invalid-media rejection; GUI picker import verified. ZIP/folder/share-extension flows pending. |
| Songs, albums, artists, genres, favorites | Implemented but not fully tested | UI derives groups from stored fields. Album count changes after GUI metadata edit. Comprehensive browsing/large-text/device checks pending. |
| Local audio playback | Implemented and tested on macOS | AVPlayer clock advancement, pause, seek, resume and paused restoration tested; GUI playback reached 0:08 of a 0:12 WAV. |
| Background, Lock Screen, Control Center, AirPlay | Implemented but not fully tested | iOS audio mode/session and media commands configured; physical iOS validation unavailable. |
| Queue, shuffle, repeat | Implemented; core tested | Occurrence-aware queue and lifecycle assertions pass. All runtime multi-track transition permutations not tested. |
| Sleep timer | Implemented but not fully tested | Duration/current-track stop configured; background execution unverified. |
| Playlist management | Partially implemented | Create, rename, description, add/remove/reorder, duplicate and exports present. Merge/artwork/editable smart rules pending. |
| Playlist parsing and export | Implemented and tested | M3U/M3U8, PLS, CSV, XSPF, JSON and pasted text; order, duplicates, malicious XML and round trips tested. |
| Matching and preview | Partially implemented | Conservative identifier/duration/title/artist candidates, manual review and missing entries. Full release/fingerprint/source matching and full GUI import E2E pending. |
| Embedded tags and metadata editor | Implemented and tested in part | Tagged M4A reading tested; GUI artist/album edits persisted across restart. Batch studio/conflict diff and numbering controls pending. |
| Fingerprinting/identification | Not implemented | No Chromaprint/AcoustID integration or credentials. |
| MusicBrainz enrichment | Implemented but not fully tested | Explicit search adapter and candidate editor; no live service request/response verified. |
| Album artwork | Partially implemented | Embedded reading, raster selection, managed copies and bounded UI thumbnails; crop/restore/CAA and complete tests pending. |
| File-tag writing | Not implemented | All edits currently database-only; no binary tag rewriting. |
| Local lyrics | Implemented and tested in part | LRC/plain parser/offset/export tests; GUI saved LRC, restored it and sought to 0:04 by tapping a line. Word sync/TTML/provider integrations pending. |
| Lyrics editor | Partially implemented | Import/raw editing/global correction/stamp/export/one-step undo. Waveform and complete undo/redo/timing editor pending. |
| Authorized direct download | Partially implemented | HTTPS transfer/progress/cancel/size cap/import wired; constructor safety tested, no live transfer or durable background queue verified. |
| Fetch | Partially implemented | Versioned client capabilities/create/poll/cancel contract. No configured server, transfer UI or verified interoperability. |
| Spotify/Apple Music/other playlist providers | Blocked by external access and unimplemented | Official current policy/auth requirements investigated; no provider app registration or authorized integration. File import remains independent. |
| Metadata backup/restore and audio export | Partially implemented | Transactional metadata restore and byte-identical individual export tested. No full audio archive, automatic restored-file relinking or streaming large export. |
| Developer options and Ideas | Partially implemented | Triple-tap/inactivity model, persistent CRUD, history, JSON safe merge tested. Bulk actions, screenshots, conflict UI and automatic repository sync pending. |
| Changelog/What's New | Partially implemented | Structured bundled notes and generated Markdown; no first-install popup. Skipped release aggregation and generated developer commit history pending. |
| Automatic application updates | Not implemented | No authorized release repository/update endpoint; no embedded private credentials. Required before public release. |
| Advanced audio | Not implemented | EQ, crossfade, ReplayGain, guaranteed gapless, speed and quality comparison pending. |
| Cross-device sync | Not implemented | No background P2P/cloud sync claim; local data stays on-device. |
| Branding | Partially implemented | Layered editable SVG, reproducible opaque PNGs and iOS asset catalog. Full tinted/dark/platform-layered variants, banners and store visuals pending. |
| iOS device IPA / simulator build | Blocked by platform tools | Project/scripts/parallel workflow prepared. Full Xcode unavailable; no artifact built here. |
| Android / Web | Not implemented; outside chosen initial scope | No APK/AAB/PWA claimed. A future web app must meet PWA requirements. |
| Release/deployment | Not implemented and not authorized | Local Git only; no remote job, published release, public worker or paid infrastructure. |

## Essential next validation

1. Restore full Xcode availability; build and launch on an iPhone/iPad simulator and a physical device.
2. Verify background/lock-screen/remote commands, route loss, interruptions, restoration and lyrics after seeks across device lifecycle.
3. Exercise playlist preview/save/play order and native import/export dialogs on all supported targets.
4. Harden import crash journals, field/image/network bounds and durable download recovery before trusting a large real collection.

## Subsequent implementation

Add a maintained safe tagging library after license/version review; complete metadata conflict review, artwork revisions and backup with streaming audio/relinking. Implement live Fetch against its real API before introducing a separate worker. Evaluate fingerprint and lyrics providers with explicit privacy and content rights. Complete Ideas bulk/conflict/export tooling, structured update manifests and distribution-specific update actions before any release. Add store/alternative channels only after scoped authorization.

No pending/approved/deferred user idea was discovered in the initially empty repository collection. Roadmap entries above are specification gaps, not fabricated user Ideas or completed release notes.
