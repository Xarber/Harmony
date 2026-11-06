# PROJECT 05 — HARMONY
## Complete Full-Stack Application Development Specification

**Working name:** Harmony  
**Tagline:** Your music. In perfect harmony.  
**Parent initiative:** OpenRecode  
**Application type:** Music playlist importer, audio downloader, metadata manager, lyrics viewer, and offline music player  
**Primary platform:** iOS  
**Secondary platforms:** iPadOS, macOS, and optional Web management  
**Status:** New project — implement from the ground up

---

# 1. YOUR ROLE AND MISSION

Act as a complete senior software engineering team consisting of:

- Product architect and technical lead.
- Senior Swift and SwiftUI developer.
- iOS audio and media framework specialist.
- Music metadata and audio identification engineer.
- Playlist integration engineer.
- Backend and API engineer.
- FFmpeg and media processing engineer.
- UI/UX and interaction designer.
- Security and privacy engineer.
- Quality assurance engineer.
- DevOps and open-source infrastructure engineer.

Your objective is to **design, implement, test, document, and deliver a complete working music application**.

Do not stop after producing UI mockups, architectural plans, specifications, or disconnected frontend components.

Implement real functionality.

Inspect the existing workspace before beginning.

If Harmony already exists, inspect it and extend its architecture without destroying previous work.

If it does not exist, create a new, properly structured project.

If my Universal Application Development Standards (UADS) document is accessible, read it completely and comply with it.

Preserve its conventions for:

- Application architecture.
- Development practices.
- Developer options.
- Ideas management.
- Changelog maintenance.
- Testing.
- Documentation.
- Release preparation.

If the UADS document is unavailable, implement the equivalent standards described here.

Do not publish repositories, deploy services publicly, incur paid costs, or modify unrelated projects without authorization.

Make reasonable technical decisions independently.

Prioritize reliable, functional software and maintain a transparent record of remaining work.

# 2. PRODUCT VISION

Harmony is an open-source personal music application designed to give users control over their own music libraries.

The application should combine:

1. Playlist imports.
2. Authorized music downloading.
3. Music identification.
4. Automatic metadata enrichment.
5. Album artwork management.
6. Synchronized lyrics.
7. Music library organization.
8. Offline playback.
9. Native iOS integration.
10. Data portability and self-hosting.

The product should feel like a polished modern music player while remaining independent of mandatory subscriptions.

**The user owns the library, controls the files, and chooses how music is organized.**

## Product Philosophy

Most modern music applications prioritize proprietary catalogs, cloud subscriptions, recommendation algorithms, and platform lock-in.

Harmony should prioritize:

- Personal ownership.
- Offline availability.
- High-quality metadata.
- Organized collections.
- Beautiful playback.
- Open standards.
- Transparent integrations.
- Privacy.
- User choice.

Avoid advertisements, forced accounts, unnecessary subscriptions, and invasive listening analytics.

Do not make an external music streaming account mandatory.

The entire local playback and library management experience must function without a network connection.

# 3. PRODUCT BOUNDARIES

Harmony has three distinct responsibilities.

## A. Playlist Import

Import playlist structure and track metadata from supported sources.

This does not automatically provide downloadable copies of the tracks.

## B. Media Acquisition

Obtain audio from user-owned, public-domain, appropriately licensed, or otherwise authorized sources.

Use Fetch-compatible infrastructure where appropriate.

## C. Library and Playback

Organize and play audio files the user has legitimately obtained or imported.

Keep these responsibilities separate internally.

Do not treat a playlist URL from a subscription service as permission or technical capability to extract protected audio.

Do not implement DRM circumvention, subscription-stream decryption, unauthorized cookie extraction, or paywall bypassing.

The application must respect copyright, provider policies, and applicable platform rules.

# 4. MAIN PRODUCT MODULES

Create the following primary modules.

## 4.1 Home

Personalized access to the user's local music library, recent activity, playlists, and unfinished imports.

## 4.2 Library

A complete offline audio collection organized by tracks, albums, artists, genres, and playlists.

## 4.3 Import

Import audio files, playlist definitions, and authorized online media.

## 4.4 Downloads

Manage media acquisition, processing, transfers, and failures.

## 4.5 Now Playing

A polished native music player with artwork, playback controls, queue management, and lyrics.

## 4.6 Metadata Studio

Identify tracks, correct tags, find artwork, and resolve conflicts.

## 4.7 Lyrics

Display, synchronize, import, and manage lyrics.

## 4.8 Settings

Audio preferences, storage, integrations, privacy, appearance, and developer options.

The application must function even when no external metadata or lyrics provider is configured.

# 5. FIRST-LAUNCH EXPERIENCE

Implement a brief, user-friendly onboarding experience.

## Initial Flow

1. Open Harmony.
2. View a short introduction.
3. Choose a library storage location within supported platform constraints.
4. Import existing music or continue with an empty library.
5. Optionally configure a Fetch-compatible server.
6. Optionally configure metadata and lyrics providers.
7. Enter the main application.

Do not require account registration.

Do not require Spotify, Apple Music, or any other streaming subscription.

Do not require the Fetch server for music that is already stored locally.

## Permission Handling

Request permissions only when necessary.

Examples:

- Files access when importing or exporting documents.
- Apple Music authorization when the user explicitly enables that integration.
- Notifications when the user requests download notifications.
- Local network access when discovering a self-hosted server.

Explain why permissions are needed.

Handle denial gracefully.

# 6. MUSIC LIBRARY DATA MODEL

Design a proper music library rather than storing everything as unstructured files.

## Core Entities

- Track.
- Recording.
- Artist.
- Album.
- AlbumArtist.
- Genre.
- Playlist.
- PlaylistItem.
- AudioFile.
- Artwork.
- Lyrics.
- LyricsTiming.
- MetadataSource.
- MetadataRevision.
- SourceReference.
- DownloadJob.
- ImportJob.
- PlaybackQueue.
- PlaybackHistory.
- UserPreferences.

An audio file and its musical identity must be treated as separate concepts.

For example, the user might possess:

- A FLAC copy of a song.
- An MP3 copy of the same recording.
- A live version.
- A remastered version.

Harmony must not automatically treat all four as identical.

## Track Fields

Support:

- Stable internal ID.
- Title.
- Sort title.
- Primary artist.
- Featured artists.
- Album artist.
- Album.
- Disc number.
- Track number.
- Release date.
- Original release date.
- Genre.
- Composer.
- Copyright notice when available.
- ISRC.
- MusicBrainz recording ID.
- MusicBrainz release ID.
- Duration.
- Explicit-content flag where reliably provided.
- User rating.
- Favorite status.
- Play count.
- Last played date.
- Added date.
- User comments.
- Source references.

All fields should be optional where the information may genuinely be unavailable.

Do not fabricate metadata.

# 7. LOCAL AUDIO IMPORT

Provide a reliable way to import existing audio files.

## Supported Import Methods

- iOS Files document picker.
- Share Sheet.
- Files shared from another application.
- ZIP archive imports.
- Folder imports where platform APIs permit.
- Import from a compatible Fetch download.
- Supported remote file transfers.
- Optional self-hosted library synchronization.

## Supported Formats

At minimum, investigate and support:

- MP3.
- M4A.
- AAC.
- ALAC.
- WAV.
- AIFF.
- FLAC where supported by the chosen playback engine.
- Opus.
- Ogg Vorbis where supported through compatible decoding libraries.

Do not claim that every format is supported by AVPlayer on every iOS version.

Provide a codec capability registry.

Where native playback is unsupported, implement a properly licensed decoder or offer explicit conversion through the configured processing backend.

## Import Pipeline

1. User selects files.
2. Harmony validates them.
3. Files are copied into managed storage or referenced through supported file access.
4. Audio properties are extracted.
5. Existing embedded tags are read.
6. A stable database record is created.
7. Duplicates are checked.
8. Album and artist relationships are established.
9. Optional metadata enrichment is suggested.
10. The tracks become playable.

## Reliability

Implement:

- Import progress.
- Cancellation.
- Recoverable failures.
- Duplicate detection.
- Storage checks.
- Atomic file movement.
- Correct security-scoped file handling.
- Batch imports.
- Crash recovery.

Never delete an original imported file without explicit permission.

# 8. PLAYLIST IMPORT SYSTEM

Playlist import is a defining Harmony capability.

Support multiple types of playlist sources.

## 8.1 Local Playlist Files

Support:

- M3U.
- M3U8 as an extended M3U playlist file.
- XSPF.
- PLS where feasible.
- CSV.
- Harmony JSON playlist format.

Distinguish M3U8 playlist files from HLS streaming manifests.

Handle relative paths and missing files safely.

## 8.2 Spotify Playlist Import

Investigate and integrate Spotify's currently supported Web API.

Use official authorization mechanisms and documented scopes.

Important:

Spotify introduced significant Development Mode restrictions in 2026.

The implementation must account for:

- Developer account eligibility.
- Premium requirements for applicable development applications.
- Small authorized-user limits.
- Restricted playlist item visibility.
- Endpoint and field changes.
- Rate limiting.
- OAuth scopes.
- API version changes.

Do not assume every public Spotify playlist can be read through a development application.

Where permitted, import playlist titles, ordering, artists, tracks, albums, durations, and identifiers.

Do not attempt to download encrypted Spotify subscription audio.

If the provider cannot expose playlist items, display a clear limitation and offer file-based import.

## 8.3 Apple Music Playlist Import

Evaluate MusicKit and the Apple Music API.

Support authorized access to available library and playlist metadata.

Use appropriate Apple developer credentials and user authorization.

Do not attempt to export DRM-protected Apple Music subscription media as ordinary audio files.

Keep Apple Music playback, if implemented, separate from Harmony's independently stored local music files.

## 8.4 Other Providers

Architect optional adapters for:

- YouTube playlists where supported.
- SoundCloud playlists where authorized.
- Other compatible online playlist services.
- Self-hosted music services.
- Plain URL lists.

Verify source capabilities and policies before implementing an adapter.

No provider should be a mandatory dependency.

## 8.5 Generic Playlist Import

Allow users to paste a list of track names and artists.

Example:

Artist — Track Title

Artist — Track Title

Harmony should parse these entries into a structured playlist.

This mode must work without connecting to an external music service.

# 9. PLAYLIST IMPORT PREVIEW

Before finalizing an import, show a dedicated preview.

Display:

- Playlist title.
- Description.
- Source.
- Artwork where available.
- Track count.
- Total estimated duration.
- Track order.
- Existing library matches.
- Missing tracks.
- Duplicates.
- Unsupported entries.

## Track Matching Status

Use explicit statuses:

- Already in Library.
- Exact Match.
- Probable Match.
- Multiple Candidates.
- Unmatched.
- Unavailable.

Do not treat a title-only similarity as proof of an exact recording match.

## Import Actions

Allow users to:

- Select all.
- Deselect individual tracks.
- Resolve uncertain matches.
- Import metadata-only entries.
- Add available local files.
- Queue authorized acquisition.
- Save the playlist.
- Cancel.

Preserve the original ordering of imported playlist items.

Preserve duplicate occurrences when they are intentional.

# 10. PLAYLIST MATCHING ENGINE

Create a sophisticated but transparent track matching system.

## Matching Inputs

Use combinations of:

- Track title.
- Artist.
- Album.
- Duration.
- ISRC.
- MusicBrainz recording ID.
- Known source identifiers.
- Audio fingerprint.
- Version descriptors.
- Release metadata.

## Normalize Carefully

Account for:

- Case differences.
- Punctuation differences.
- Featuring credits.
- Alternate artist formatting.
- Unicode normalization.
- Common abbreviations.

Avoid ignoring meaningful distinctions such as:

- Live.
- Acoustic.
- Remix.
- Radio edit.
- Remastered.
- Instrumental.
- Explicit.
- Clean version.

## Confidence Scores

Return a confidence score and explanation.

Examples:

**High confidence:** Matching ISRC and duration.

**Medium confidence:** Matching title, artist, album, and approximate duration.

**Low confidence:** Matching title with incomplete artist information.

Use configurable thresholds.

Do not automatically accept uncertain matches.

## Manual Review

Provide a candidate selection interface.

Display:

- Candidate title.
- Artist.
- Album.
- Duration.
- Version.
- Source.
- Match explanation.

Allow the user to select the correct recording or leave the item unmatched.

# 11. AUTOMATIC MUSIC IDENTIFICATION

Implement optional audio fingerprinting.

## Recommended Technology

Evaluate:

- Chromaprint.
- AcoustID.
- MusicBrainz recording identifiers.
- Equivalent maintained technologies.

## Identification Process

1. Analyze a local audio file.
2. Extract its duration.
3. Generate a fingerprint using a supported implementation.
4. Query an explicitly configured identification service.
5. Retrieve potential recording matches.
6. Rank candidates.
7. Show confidence.
8. Suggest metadata.
9. Let the user accept or reject.

## Privacy

Audio fingerprinting must be optional.

Clearly explain when fingerprints or metadata are sent to an external provider.

Do not upload full audio files merely for identification unless the user explicitly selects a service requiring that behavior.

## Provider Rules

Respect:

- API keys.
- Rate limits.
- Noncommercial-use limitations.
- Authentication.
- Provider attribution.
- Usage restrictions.

Do not hardcode temporary example API keys in production.

# 12. METADATA ENRICHMENT ENGINE

Build a modular metadata lookup system.

## Primary Sources

Evaluate:

- MusicBrainz.
- AcoustID.
- Cover Art Archive.
- Embedded file tags.
- User-provided metadata.
- Other appropriately licensed services.

## Metadata Fields

Retrieve, where available:

- Recording title.
- Artists.
- Album.
- Album artist.
- Release date.
- Track number.
- Disc number.
- Genre.
- Recording identifiers.
- Album artwork.
- Release type.
- Composer credits.

## Source Priorities

Allow users to configure priorities.

Example:

1. User-edited metadata.
2. Verified recording identifiers.
3. Embedded tags.
4. Selected external database.
5. Filename parsing.

Do not overwrite manual corrections automatically.

## Provenance

Track where important metadata originated.

For example:

Album title: MusicBrainz  
Cover art: Cover Art Archive  
Genre: User edited

Store lookup timestamps and provider identifiers.

## Conflict Resolution

When providers disagree:

- Preserve existing data.
- Show alternatives.
- Highlight differences.
- Explain confidence.
- Allow selective field replacement.

Never silently replace the entire library's tags following a bulk scan.

# 13. METADATA STUDIO

Create a dedicated advanced metadata editor.

## Editing Features

Support:

- Single-track editing.
- Multi-track editing.
- Album-level editing.
- Batch metadata lookup.
- Filename-based tag extraction.
- Tag-based filename generation.
- Artwork selection.
- Genre normalization.
- Track numbering.
- Disc numbering.
- Artist separation.
- Metadata conflict review.

## Batch Editing

Example:

The user imports twelve files from the same album.

Harmony identifies the album.

It proposes:

- Correct album artist.
- Album title.
- Release year.
- Track order.
- Album artwork.

The user reviews and applies the changes.

## File Tag Writing

Support writing metadata into compatible formats.

Investigate:

- ID3 for MP3.
- MP4 atoms for M4A/ALAC.
- Vorbis Comments where applicable.
- FLAC metadata blocks.
- RIFF INFO or other supported WAV metadata.

Use mature maintained libraries.

Do not implement unsafe binary tagging from scratch.

## Write Safety

Before modifying a file:

- Validate format.
- Check available storage.
- Preserve a recoverable original or backup where appropriate.
- Write safely.
- Verify the result.
- Roll back if verification fails.

Separate database metadata changes from actual file-tag modifications.

Offer both modes.

# 14. ALBUM ARTWORK

Artwork is an essential part of Harmony's design.

## Artwork Sources

Support:

- Embedded artwork.
- User-selected images.
- Cover Art Archive.
- Other providers with appropriate permissions.

## Artwork Matching

Prefer release-specific artwork rather than unrelated images that happen to have similar titles.

Use MusicBrainz release identifiers where available.

Provide candidate selection when multiple releases exist.

## Artwork Features

- View artwork.
- Replace artwork.
- Crop artwork.
- Choose resolution.
- Embed artwork into files when supported.
- Save artwork locally.
- Clear artwork.
- Restore previous artwork.
- Generate thumbnails.

## Image Quality

Prefer high-resolution images when available.

Cache appropriately sized versions for:

- Lists.
- Album details.
- Full-screen player.
- Lock-screen Now Playing metadata.

Avoid decoding full-resolution images repeatedly during scrolling.

## Copyright and Attribution

Do not assume album covers are public-domain merely because a public API serves them.

Respect provider terms and artwork rights.

Maintain attribution or licensing metadata where required.

Do not scrape unrelated image search results as the default artwork pipeline.

# 15. SYNCHRONIZED LYRICS SYSTEM

This is one of Harmony's signature features.

Implement a complete lyrics experience.

## 15.1 Lyrics Types

Support:

- Plain text lyrics.
- Line-synchronized lyrics.
- Word-synchronized lyrics where compatible data is available.
- Instrumental track indicators.

## 15.2 Supported Formats

Implement robust parsers for:

- LRC.
- Enhanced LRC where relevant.
- A structured internal timing format.
- Other formats such as TTML only where legally and technically appropriate.

Support common LRC metadata and timing constructs.

## 15.3 Lyrics Providers

Create a modular lyrics-provider interface.

Investigate LRCLIB as one potential source.

Support:

- Search by title and artist.
- Search using album and duration.
- Retrieve available synchronized lyrics.
- Retrieve plain lyrics where available.
- Identify instrumental tracks.

Respect each provider's:

- Terms of use.
- Copyright obligations.
- Attribution rules.
- Caching policies.
- API limits.
- Redistribution restrictions.

Do not assume a publicly readable API grants unlimited redistribution rights.

## 15.4 Local Lyrics Import

Allow users to import their own:

- .lrc files.
- Plain text lyrics.
- Supported structured lyrics files.

Allow selecting which track receives the lyrics.

## 15.5 Embedded Lyrics

Read embedded lyrics when available.

Offer embedding or exporting lyrics only where technically supported and permitted by the rights attached to the content.

Do not automatically republish third-party lyrics in exports or public APIs.

# 16. LYRICS PLAYBACK EXPERIENCE

Create a beautiful, synchronized lyrics interface.

## Full-Screen Lyrics

Display:

- Album artwork or suitable background.
- Large readable lyrics.
- Current line emphasized.
- Previous lines visually de-emphasized.
- Upcoming lines.
- Smooth transitions.
- Playback controls.
- Current time.

## Automatic Scrolling

Follow playback position.

The currently active line should remain comfortably visible.

Avoid abrupt scrolling or excessive animation.

## Interaction

Allow users to tap a timestamped line to seek to its position.

Support:

- Automatic scrolling.
- Manual scrolling.
- Return to current line.
- Adjustable text size.
- High contrast.
- Reduced motion.

## Timing

Use the actual playback clock as the timing source.

Do not advance lyrics using independent timers that drift from playback.

Synchronize correctly after:

- Seeking.
- Pausing.
- Resuming.
- Changing tracks.
- Playback speed changes where supported.
- Audio interruptions.

## Word-Level Lyrics

If word-level timings are available, provide optional karaoke-style highlighting.

Do not fabricate word timing by spreading timestamps uniformly across a line and labeling it accurate synchronization.

Provide a fallback to line-level synchronization.

# 17. LYRICS EDITOR

Create an optional advanced lyrics synchronization editor.

## Features

- Import plain lyrics.
- View waveform where feasible.
- Play audio.
- Add timestamps.
- Adjust line timing.
- Offset all timestamps.
- Correct individual timestamps.
- Preview synchronization.
- Save.
- Export LRC.
- Undo and redo.

## Timing Offset

Support:

- Positive offset.
- Negative offset.
- Fine-grained adjustments.

Persist user corrections.

## Editing Safety

Never overwrite imported lyrics silently.

Maintain provenance and a revision or recoverable original where appropriate.

## Rights

Allow users to edit lyrics they own or are authorized to use.

Do not automatically upload edited copyrighted lyrics to public services.

# 18. NATIVE MUSIC PLAYER

Implement a complete native audio player.

This is a primary feature, not a secondary preview.

## Basic Playback

Support:

- Play.
- Pause.
- Previous.
- Next.
- Seek.
- Scrubbing.
- Shuffle.
- Repeat off.
- Repeat playlist.
- Repeat track.
- Volume control through supported system mechanisms.
- Playback queue.
- Background playback.
- Playback progress.
- Track transitions.

## Queue Management

Support:

- Play Now.
- Play Next.
- Add to Queue.
- Reorder Queue.
- Remove from Queue.
- Clear Queue.
- Save Queue as Playlist.
- View Up Next.

## Playback Restoration

Persist:

- Last track.
- Queue.
- Playback position.
- Shuffle state.
- Repeat state.

After restarting, restore a sensible playback state without unexpectedly beginning audio.

## Unsupported Media

Clearly identify files that cannot be played.

Do not silently skip unsupported files without explanation.

# 19. AUDIO PLAYBACK ENGINE

Prefer native Apple frameworks for the iOS application.

Evaluate:

- AVFoundation.
- AVPlayer.
- AVQueuePlayer.
- AVAudioEngine where advanced processing is needed.
- MediaPlayer.
- Core Audio where appropriate.

Use a unified playback controller as the authoritative owner of player state.

Avoid creating a separate player instance for every screen.

## Engine Responsibilities

- Track loading.
- Playback lifecycle.
- Queue advancement.
- Audio session configuration.
- Interruption handling.
- Route changes.
- Now Playing metadata.
- Remote controls.
- Error recovery.
- Resource cleanup.

## Format Support

Validate actual format support on target iOS versions.

Do not assume every imported codec works automatically.

Where necessary, provide a compatible conversion workflow.

## Audio Quality

Avoid unnecessary transcoding.

Respect source bit depth, sample rate, and codec information where meaningful.

Do not claim bit-perfect output when the playback pipeline performs resampling, volume adjustment, equalization, or other processing.

# 20. BACKGROUND PLAYBACK AND IOS INTEGRATION

Harmony must behave like a genuine music application.

## Background Audio

Configure the appropriate AVAudioSession playback category and required background audio mode.

Ensure playback continues when:

- The device is locked.
- The application enters the background.
- The screen turns off.

Respect operating-system resource management.

## Lock Screen

Integrate:

- Track title.
- Artist.
- Album artwork.
- Playback position.
- Play/pause.
- Previous.
- Next.
- Seeking where supported.

Use MPNowPlayingInfoCenter and MPRemoteCommandCenter or the current supported equivalents.

## Control Center

Provide accurate system media controls.

Avoid duplicate or stale Now Playing sessions.

## Headphones

Support:

- Wired headphones.
- Bluetooth headphones.
- AirPods.
- Audio route changes.
- Headphone disconnection.
- Appropriate auto-pause behavior.

## Interruptions

Handle:

- Incoming calls.
- Siri interruptions.
- Other audio sessions.
- Bluetooth reconnection.
- Audio route changes.

Resume only when appropriate.

## Additional Features

Investigate:

- AirPlay output selection.
- System audio output controls.
- Audio handoff.
- CarPlay support as a later feature, subject to entitlements and testing.
- Live Activities only when they add genuine functionality and are supported.

Do not implement features using unsupported private APIs.

# 21. ADVANCED AUDIO FEATURES

Provide an optional advanced audio settings section.

## Audio Normalization

Support metadata-driven loudness adjustment where feasible.

Consider ReplayGain or equivalent recognized loudness metadata.

Do not apply destructive normalization to source files by default.

## Equalizer

Investigate a configurable equalizer with presets such as:

- Flat.
- Bass Boost.
- Treble Boost.
- Vocal.
- Acoustic.
- Custom.

Implement only if the selected audio architecture can support it reliably.

## Crossfade

Offer optional crossfade.

Document limitations for:

- Lossless playback.
- Gapless albums.
- Certain codecs.
- Audio engine transitions.

## Gapless Playback

Prioritize correct track boundaries where supported.

Do not insert audible silence unnecessarily between gapless album tracks.

## Playback Speed

Support speed adjustment where technically feasible.

This is optional and should not delay core playback.

## Sleep Timer

Implement a sleep timer.

Allow:

- Stop after duration.
- Stop after current track.
- Stop after playlist.

The timer should terminate playback rather than merely hiding the player interface.

# 22. NOW PLAYING USER INTERFACE

The Now Playing screen should be one of Harmony's strongest visual experiences.

## Required Elements

- Large album artwork.
- Track title.
- Artist.
- Album.
- Playback progress.
- Time remaining.
- Previous.
- Play/pause.
- Next.
- Shuffle.
- Repeat.
- Queue.
- Lyrics button.
- Favorite button.
- More actions.

## Design

Use smooth, restrained transitions.

Consider artwork-derived color accents.

Ensure sufficient contrast.

Provide:

- Compact mini-player.
- Expanded player.
- Full-screen lyrics.
- Queue panel.

## Mini-Player

Display at the bottom of library screens where appropriate.

Support:

- Play/pause.
- Tap to expand.
- Track details.
- Smooth state synchronization.

Do not create inconsistent playback state between the mini-player and full player.

# 23. MUSIC LIBRARY INTERFACE

Provide the following views.

## Songs

Searchable and sortable full track list.

## Albums

Artwork grid and album detail pages.

## Artists

Artist directory and artist detail pages.

## Playlists

User-created and imported playlists.

## Genres

Browse genre-based collections.

## Favorites

Tracks explicitly marked as favorites.

## Recently Added

Recently imported music.

## Recently Played

Optional local playback history.

## Downloads

Active and completed downloads.

## Unmatched

Tracks or playlist items requiring identification or acquisition.

## Search

Unified search across:

- Songs.
- Albums.
- Artists.
- Playlists.
- Genres.
- Local filenames.
- Available metadata.

All core searches should work offline.

# 24. PLAYLIST MANAGEMENT

Provide robust playlist management.

## Actions

- Create.
- Rename.
- Edit description.
- Add artwork.
- Add tracks.
- Remove tracks.
- Reorder tracks.
- Duplicate.
- Merge.
- Sort.
- Export.
- Delete.

## Playlist Types

Support:

- Manual playlists.
- Imported playlists.
- Smart playlists.
- Temporary playback queues.

## Smart Playlists

Examples:

- Recently Added.
- Most Played.
- Favorites.
- Never Played.
- High Quality.
- Recently Downloaded.

Allow simple filter rules.

Examples:

Genre = Electronic

Rating >= 4

Added in last 30 days

Avoid creating an unnecessarily complex rules engine in the MVP.

## Missing Tracks

Do not remove missing playlist items automatically.

Show them as unavailable placeholders.

Allow users to locate or replace the corresponding local file.

# 25. MUSIC DOWNLOAD ENGINE

Harmony should support authorized audio acquisition.

Do not duplicate all of Fetch's infrastructure unnecessarily.

## Preferred Approach

Create a reusable download engine interface.

Potential implementations:

- Fetch-compatible remote worker.
- Standalone Harmony worker.
- Direct HTTP file download for explicitly authorized file URLs.
- Import existing local files.

## Responsibilities

- Inspect an authorized source.
- Identify available audio formats.
- Select output quality.
- Download media.
- Convert when necessary.
- Attach metadata.
- Transfer finished audio.
- Import into Harmony's library.

## Source Policies

Do not extract DRM-protected subscription audio.

Do not circumvent access controls.

Only support sources the user is authorized to download.

Avoid presenting the app as a tool for bypassing streaming-service subscriptions.

## Download Completion

After acquisition:

1. Verify the output file.
2. Read technical metadata.
3. Match the intended track.
4. Obtain optional enrichment.
5. Propose artwork and lyrics.
6. Import into managed storage.
7. Update playlist availability.
8. Mark download complete.

Do not mark a track available merely because a remote worker finished downloading; ensure the audio is actually accessible to Harmony.

# 26. FETCH INTEROPERABILITY

Harmony and Fetch are separate OpenRecode projects.

Harmony should reuse Fetch's media-processing capabilities where suitable.

## Shared Protocol

Design a versioned interface supporting:

- Server discovery.
- Authentication.
- Capability negotiation.
- Source inspection.
- Format selection.
- Download creation.
- Job progress.
- Output transfer.
- Cancellation.
- Error reporting.

Use the existing Fetch API if available.

If Fetch does not yet exist, implement a compatible standalone adapter with a documented contract.

Do not fabricate a live Fetch service or report interoperability as tested without connecting to a working implementation.

## Capabilities

Harmony should be able to request:

- Audio-only output.
- Original audio stream where appropriate.
- MP3.
- M4A/AAC.
- Opus.
- FLAC where genuinely lossless source data is available.
- Metadata embedding.
- Artwork embedding when supported.

## Independence

Harmony must remain usable without Fetch.

Core local playback, imports, playlist management, and metadata editing must not depend on a remote worker.

# 27. DOWNLOAD MANAGEMENT

Create a download queue optimized for music.

## Statuses

- Queued.
- Inspecting.
- Downloading.
- Converting.
- Tagging.
- Transferring.
- Importing.
- Completed.
- Failed.
- Cancelled.

## Features

- Individual progress.
- Playlist progress.
- Speed.
- Estimated time remaining where calculable.
- Retry.
- Cancel.
- Pause when supported.
- Duplicate detection.
- Priority.
- Concurrency limits.

## Playlist Download View

Display:

- Total tracks.
- Completed tracks.
- Pending tracks.
- Failed tracks.
- Unmatched tracks.
- Total downloaded size.

Allow retrying only failed items.

Preserve playlist order independently of download completion order.

## Server Independence

A server-side job should continue according to its lifecycle even when the iOS app is suspended.

The application should recover job state after reconnection.

# 28. AUDIO QUALITY MANAGEMENT

Users should understand the actual quality of their library.

## Technical Information

Display:

- Codec.
- Container.
- Bitrate.
- Sample rate.
- Bit depth where available.
- Channel count.
- Duration.
- File size.
- Lossless/lossy classification.
- Source encoding where known.

## Quality Presets

Offer:

- Best Original.
- High Quality.
- Balanced.
- Storage Saver.
- Custom.

Do not describe a converted MP3-to-FLAC file as newly lossless audio.

## Duplicate Quality Comparison

When the same recording exists in multiple formats, show available copies.

Allow users to choose the preferred version.

Example:

Track A:
- MP3 320 kbps.
- AAC 256 kbps.
- FLAC 16-bit/44.1 kHz.

Do not automatically delete alternate versions.

## Audio Verification

Use FFprobe or equivalent trusted media inspection where appropriate.

Avoid relying only on filename extensions.

# 29. FILE MANAGEMENT AND STORAGE

Create a reliable local storage architecture.

## Managed Library

Organize imported audio through a stable internal storage layer.

Support:

- File references.
- Managed copies.
- Storage usage.
- Duplicate file detection.
- Deletion.
- Reimport.
- Missing file recovery.

## Folder Organization

Provide optional export templates.

Example:

Artist/Album/Disc-Track - Title.ext

Another:

Genre/Artist - Title.ext

Normalize paths safely.

## Storage Settings

Show:

- Total library size.
- Number of tracks.
- Artwork cache size.
- Lyrics cache size.
- Temporary files.
- Available device storage.

## Cleanup

Support:

- Clear artwork cache.
- Clear temporary files.
- Remove failed imports.
- Delete unused downloaded artifacts.
- Remove duplicate files after user review.

Never automatically delete unique user-owned music files.

# 30. LIBRARY SYNCHRONIZATION

Harmony should be local-first.

Synchronization is optional.

## Supported Model

Start with an authoritative local library.

Add a synchronization architecture supporting:

- Library metadata.
- Playlists.
- User ratings.
- Favorites.
- Playback preferences.
- Optional audio file transfers.

## Self-Hosted Synchronization

Investigate a self-hosted service compatible with OpenRecode principles.

Possible storage backends:

- WebDAV.
- S3-compatible object storage.
- A dedicated Harmony API.

Choose an architecture based on reliability and maintainability.

## Multi-Device Behavior

Support stable identifiers and conflict detection.

Do not overwrite one device's playlists silently.

Keep audio file synchronization separate from lightweight metadata synchronization.

## Offline Operation

Without a network connection, users must still be able to:

- Browse locally available music.
- Play music.
- Edit playlists.
- Edit database metadata.
- Search the library.
- View cached lyrics.
- View artwork.
- Export files.

# 31. IMPORT AND EXPORT PORTABILITY

Data portability is mandatory.

## Playlist Export

Support:

- M3U.
- M3U8 playlist format.
- XSPF.
- CSV.
- JSON.

## Library Export

Support:

- Library metadata JSON.
- Playlist definitions.
- Track references.
- Artwork metadata.
- User-created annotations.
- Local lyrics files where export rights permit.

## Full Library Backup

Provide a portable backup archive.

Allow users to choose whether to include audio files.

For large libraries, provide size estimates.

## Restoration

Implement:

- Backup validation.
- Schema version checks.
- Duplicate detection.
- Missing-file handling.
- Import progress.
- Recoverable failures.

Do not execute arbitrary imported data.

Prevent path traversal and archive decompression attacks.

## External Service Data

Do not include third-party lyrics, artwork, or restricted provider metadata in exports contrary to their terms.

Document any excluded content.

# 32. APPLICATION ARCHITECTURE

The primary iOS application should use a native-focused architecture.

## Preferred Stack

- Swift.
- SwiftUI.
- Swift Concurrency.
- AVFoundation.
- MediaPlayer.
- FileManager and document APIs.
- SQLite through a maintained wrapper such as GRDB, or an equivalent carefully evaluated persistence layer.
- URLSession.
- Keychain.
- Background URLSession for supported transfers.

Evaluate current platform compatibility before finalizing dependencies.

## Architectural Modules

- AppShell.
- DesignSystem.
- MusicLibrary.
- PlaylistManager.
- AudioPlayer.
- PlaybackQueue.
- MediaImporter.
- MusicIdentifier.
- MetadataEngine.
- ArtworkManager.
- LyricsEngine.
- LyricsEditor.
- DownloadManager.
- FetchAdapter.
- FileTransfer.
- LocalDatabase.
- Settings.
- DeveloperTools.

Use protocol-based abstractions where appropriate.

Do not create unnecessary abstraction layers that make ordinary functionality difficult to maintain.

## UI State

Use one authoritative playback state.

Keep the audio engine independent from individual screens.

Avoid race conditions caused by multiple view models mutating playback independently.

# 33. BACKEND ARCHITECTURE

The backend is optional for existing local files, but required for server-backed media processing.

## Preferred Components

- Python.
- FastAPI.
- yt-dlp.
- FFmpeg.
- FFprobe.
- Mutagen or an equivalent mature tagging library.
- PostgreSQL or SQLite as appropriate.
- Redis or another queue backend if necessary.
- Docker Compose.

## Backend Responsibilities

- Authorized source inspection.
- Download jobs.
- Format selection.
- Transcoding.
- Tagging.
- Metadata enrichment where configured.
- Audio fingerprinting where appropriate.
- Secure artifact transfer.
- Job progress.
- Resource limits.
- Cleanup.

## Deployment

Support:

- Linux.
- macOS with Docker.
- ARM64.
- x86-64.
- NAS environments where compatible.
- Personal VPS deployments.

## Operational Controls

Implement:

- Authentication.
- HTTPS configuration.
- Job concurrency.
- Resource limits.
- Storage quotas.
- Health checks.
- Retry policies.
- Persistent job records.
- Backup documentation.

Do not make a third-party paid hosted service a hard dependency.

# 34. DATABASE DESIGN

Create a normalized and extensible schema.

Suggested entities:

- LibraryTrack
- RecordingIdentity
- AudioFile
- Artist
- Album
- AlbumArtist
- TrackArtist
- Genre
- Playlist
- PlaylistEntry
- PlaylistImport
- PlaylistSource
- Artwork
- LyricsDocument
- LyricsRevision
- MetadataRecord
- MetadataCandidate
- MetadataRevision
- AudioFingerprint
- ImportJob
- DownloadJob
- DownloadArtifact
- PlaybackQueue
- QueueEntry
- PlaybackHistory
- UserRating
- Favorite
- SyncOperation
- LibrarySettings
- DeveloperIdea

## Database Requirements

- Stable IDs.
- Foreign keys.
- Transactions.
- Migration support.
- Efficient indexes.
- Full-text search.
- Revision handling.
- Correct deletion semantics.
- Clear ownership of file references.

## Duplicate Handling

A track may appear in multiple playlists.

Do not duplicate the underlying audio file for each playlist entry.

Allow multiple distinct audio files to reference the same musical recording identity.

# 35. API DESIGN

If a Harmony backend is used, expose a documented, versioned API.

Illustrative endpoints:

## Status

GET /api/v1/status  
GET /api/v1/capabilities

## Downloads

POST /api/v1/downloads  
GET /api/v1/downloads  
GET /api/v1/downloads/:id  
POST /api/v1/downloads/:id/cancel

## Metadata

POST /api/v1/metadata/search  
POST /api/v1/metadata/identify  
GET /api/v1/metadata/candidates/:id

## Lyrics

GET /api/v1/lyrics/search  
GET /api/v1/lyrics/:id

## Artwork

GET /api/v1/artwork/search  
GET /api/v1/artwork/:id

## Library Sync

POST /api/v1/sync/push  
GET /api/v1/sync/pull

## Transfers

POST /api/v1/transfers  
GET /api/v1/transfers/:id/file

These are illustrative contracts.

Do not implement unnecessary backend requests for operations that can be performed locally.

Enforce authorization and input validation.

Provider-facing operations must respect rate limits and usage policies.

# 36. SECURITY ARCHITECTURE

Harmony processes external URLs, local audio files, imported metadata, and optional remote credentials.

Implement robust security controls.

## Client Security

- Secure Keychain storage.
- File access restrictions.
- Safe imports.
- No hidden tracking.
- No credentials in logs.
- Protected local data where appropriate.
- Secure server pairing.

## Backend Security

- Authentication.
- Authorization.
- TLS.
- Rate limiting.
- Request validation.
- SSRF defenses.
- Redirect validation.
- File size limits.
- Processing timeouts.
- Disk quotas.
- Safe FFmpeg invocation.
- Safe filename normalization.
- No arbitrary shell command execution.
- No privileged containers by default.

## Provider Credentials

Never expose Spotify, Apple Music, or other provider credentials in:

- Source repositories.
- Exported backups.
- Diagnostic logs.
- Public API responses.

Use provider-appropriate OAuth flows and secure token storage.

## Imported Metadata

Treat externally supplied metadata as untrusted.

Sanitize text for display.

Avoid executing scripts embedded in imported documents, SVG artwork, or HTML fields.

# 37. PRIVACY AND DATA OWNERSHIP

Harmony must be privacy-respecting by default.

## Requirements

- No advertisements.
- No hidden analytics.
- No listening-history sale.
- No invasive tracking.
- No mandatory cloud accounts.
- No automatic upload of a user's music files.
- No automatic submission of private playlists to external services.
- No external fingerprinting without authorization.

## Listening History

Keep playback history local by default.

Allow users to:

- Disable history.
- Clear history.
- Export history.
- Reset play counts.

## External Lookups

Explain what data each external provider receives.

For example:

Metadata search may disclose title and artist.

Fingerprint lookup may disclose fingerprint and duration.

Playlist import may require account authorization.

Provide clear, independent controls.

## Data Deletion

Support:

- Delete track.
- Delete playlist.
- Delete cache.
- Remove metadata.
- Delete downloads.
- Revoke connected accounts.
- Clear provider tokens.
- Reset application data.

Do not assume deleting a library record means the original audio file should also be deleted.

# 38. USER INTERFACE DESIGN

Build a visually polished music application.

It should compete in usability and visual quality with established music players without copying their proprietary assets or branding.

## Visual Direction

Use:

- Large artwork.
- Clean typography.
- Smooth transitions.
- Elegant player controls.
- Minimal clutter.
- Rich album views.
- Subtle artwork-based color accents.
- Clear download and matching statuses.

Initial accent color: **#6269F5**.

Support:

- Dark theme.
- Light theme.
- System theme.
- Dynamic Type.
- Reduced Motion.
- VoiceOver.
- High contrast.
- Accessible controls.

## Navigation

Recommended main tabs:

- Home.
- Library.
- Search.
- Downloads.

Expose Playlists as a prominent Library destination or dedicated tab when justified by usability testing.

The mini-player should remain accessible across major library screens.

## Required Screens

1. Welcome.
2. Home.
3. Library.
4. Songs.
5. Artists.
6. Artist Details.
7. Albums.
8. Album Details.
9. Playlists.
10. Playlist Details.
11. Playlist Import.
12. Playlist Matching.
13. Music Import.
14. Downloads.
15. Download Details.
16. Now Playing.
17. Full-Screen Lyrics.
18. Lyrics Editor.
19. Metadata Studio.
20. Artwork Picker.
21. Playback Queue.
22. Search.
23. Storage Management.
24. Provider Integrations.
25. Audio Settings.
26. Appearance.
27. Privacy.
28. Developer Options.

All screens need real loading, empty, error, and offline states.

# 39. ACCESSIBILITY

Implement:

- VoiceOver labels.
- Accessible playback controls.
- Dynamic Type.
- Adequate contrast.
- Reduced Motion.
- Larger touch targets.
- Clear status labels.
- Keyboard accessibility where appropriate.
- Accessible lyrics presentation.
- Non-color-only download states.

Synchronized lyric animation must not prevent users from reading at their own pace.

Allow automatic scrolling to be disabled.

# 40. DEVELOPER OPTIONS — UADS

Every OpenRecode application must have developer options.

Harmony should provide:

- Application version.
- Build identifier.
- Database version.
- Library index status.
- Audio engine diagnostics.
- Current codec information.
- Playback state.
- Current audio route.
- Metadata provider status.
- Lyrics provider status.
- Fetch server connection.
- Download worker status.
- Cache usage.
- Library statistics.
- Import diagnostics.
- Sanitized error logs.
- Changelog.
- Developer Ideas.

Never expose credentials or private media content through diagnostics.

## Developer Ideas Page

Implement the standard UADS Ideas system.

This is separate from ordinary music playlists, library notes, and user data.

Each idea must contain:

- Stable ID.
- Title.
- Description.
- Category.
- Priority.
- Status.
- Created timestamp.
- Updated timestamp.
- Optional screenshots.
- Related application feature.
- Optional implementation notes.

Statuses:

- New.
- Under consideration.
- Approved.
- In progress.
- Implemented.
- Deferred.
- Rejected.

Support:

- Create.
- Edit.
- Delete.
- Search.
- Filter.
- Sort.
- Import JSON.
- Export JSON.
- Duplicate detection.
- Changelog linking.

## Changelog

Maintain a structured changelog with:

- Added.
- Changed.
- Fixed.
- Security.
- Removed.

Link implemented ideas where appropriate.

# 41. OPENRECODE STANDARDS

Harmony belongs to the OpenRecode initiative.

It must be:

- Open-source.
- Self-hostable where server features are required.
- Free to use.
- Forkable.
- Extensible.
- Community-maintainable.
- Free of advertisements.
- Free of mandatory subscriptions for core functionality.
- Independent of proprietary cloud services for local playback.

## Licensing

Evaluate license compatibility.

Consider AGPLv3 for application-owned code if appropriate.

Review licenses for:

- Audio decoders.
- FFmpeg builds.
- yt-dlp.
- Metadata libraries.
- Audio fingerprinting tools.
- Third-party UI dependencies.
- Fonts.
- Icons.

Music recordings, album artwork, and lyrics retain their own applicable rights.

Do not include copyrighted music or unlicensed lyrics as public repository fixtures.

## Required Repository Files

README.md  
LICENSE  
CONTRIBUTING.md  
CODE_OF_CONDUCT.md  
SECURITY.md  
CHANGELOG.md  
.env.example  
docs/ARCHITECTURE.md  
docs/IOS.md  
docs/PLAYER.md  
docs/LIBRARY.md  
docs/PLAYLISTS.md  
docs/METADATA.md  
docs/LYRICS.md  
docs/DOWNLOADS.md  
docs/FETCH_INTEGRATION.md  
docs/DEPLOYMENT.md  
docs/PRIVACY.md  
docs/ROADMAP.md

Document how to run Harmony entirely offline with imported files.

# 42. TESTING REQUIREMENTS

Build a meaningful test suite.

## Unit Tests

Cover:

- Music library model.
- Playlist parsing.
- Playlist ordering.
- Metadata normalization.
- Track matching.
- Confidence scoring.
- Audio file identification.
- Lyrics parsing.
- Lyric timestamp resolution.
- Queue management.
- Shuffle and repeat.
- Duplicate detection.
- File naming.
- Import validation.

## Integration Tests

Cover:

- Audio import.
- Database persistence.
- File tagging.
- Metadata lookup.
- Artwork lookup.
- Lyrics lookup.
- Playlist import.
- Fetch-compatible job creation.
- Download transfer.
- Track availability updates.
- Backup and restore.
- Provider authentication.

Use mocked services for deterministic tests.

Separately test actual external integrations where credentials and access are available.

## Playback Tests

Verify:

- Start.
- Pause.
- Resume.
- Seek.
- Next.
- Previous.
- Shuffle.
- Repeat.
- Queue reordering.
- Background playback.
- Audio interruption.
- Headphone disconnection.
- Playback restoration.

## Lyrics Tests

Verify:

- Plain lyrics display.
- LRC parsing.
- Repeated timestamps.
- Offset handling.
- Seeking.
- Pausing.
- Timing accuracy.
- Missing lyrics.
- Instrumental tracks.
- Manual timing corrections.

## Metadata Tests

Verify:

- Correct matches.
- Incorrect matches.
- Ambiguous matches.
- Version distinctions.
- Manual overrides.
- Batch updates.
- File-tag round trips.
- Album art changes.
- Duplicate recording IDs.

## Security Tests

Verify:

- Unauthorized file access rejection.
- SSRF protection.
- Malicious playlist files.
- Path traversal.
- Unsafe metadata input.
- Expired credentials.
- Rate limiting.
- Oversized imports.
- Archive extraction limits.

# 43. IMPORTANT END-TO-END SCENARIOS

## Scenario A — Import Existing Music

1. User opens Harmony.
2. User selects Import Music.
3. User selects several audio files.
4. Harmony reads their embedded tags.
5. Files appear in the library.
6. Albums and artists are grouped correctly.
7. User opens an album.
8. User plays a song.
9. Audio plays through the device.
10. User locks the screen.
11. Playback continues.
12. Lock-screen controls work.

## Scenario B — Import a Playlist

1. User imports an authorized playlist through a supported provider or local file.
2. Harmony reads the available track metadata.
3. Harmony identifies existing local matches.
4. The user reviews ambiguous matches.
5. Missing tracks remain visible.
6. The playlist is created.
7. Existing matched tracks are playable immediately.
8. The user may separately acquire missing tracks from authorized sources.
9. Playlist order is preserved.

## Scenario C — Download and Enrich

1. User selects an authorized downloadable recording.
2. Harmony sends the request to a configured worker.
3. The worker retrieves the audio.
4. The output is processed.
5. The file transfers to iOS.
6. Harmony imports the file.
7. Metadata candidates are identified.
8. The user approves the correct recording.
9. Artwork is attached.
10. Compatible lyrics are associated.
11. The track becomes available offline.

## Scenario D — Synchronized Lyrics

1. User selects a locally stored song.
2. The song begins playing.
3. The user opens Lyrics.
4. Existing synchronized lyrics appear.
5. The current line follows playback.
6. The user seeks forward.
7. Lyric highlighting updates immediately.
8. The user pauses.
9. Lyric progression stops.
10. Playback resumes without timing drift.

## Scenario E — Wrong Metadata

1. Harmony identifies a recording incorrectly.
2. The user opens Metadata Studio.
3. The user inspects alternative matches.
4. The user selects the correct version.
5. Harmony updates the database.
6. The original audio remains intact.
7. Embedded tags are updated only after explicit approval.

## Scenario F — No Network

1. User opens Harmony in airplane mode.
2. The library loads.
3. Artwork is visible from cache.
4. Downloaded lyrics are available.
5. Music plays normally.
6. Playlists can be edited.
7. New local music can be imported.
8. External provider actions show an offline state without breaking the app.

## Scenario G — Restore Library

1. User exports a library backup.
2. The backup contains the selected library information and optional audio files.
3. Harmony is installed on another device.
4. The user imports the backup.
5. Albums, artists, and playlists are restored.
6. Missing audio is identified if excluded.
7. Duplicates are handled safely.
8. The restored library is functional.

# 44. PERFORMANCE REQUIREMENTS

Optimize for large personal music collections.

Aim to support:

- Thousands of songs.
- Hundreds of albums.
- Large playlist imports.
- Responsive library search.
- Smooth scrolling.
- Efficient album artwork caching.
- Low memory consumption.
- Reliable background playback.
- Incremental library indexing.
- Efficient metadata batching.
- Minimal unnecessary network requests.

## Technical Expectations

Use:

- Lazy database queries.
- Indexes.
- Incremental scanning.
- Background tasks where supported.
- Image caching.
- Batch operations.
- Efficient audio file access.

Do not load the entire audio library into memory unnecessarily.

Do not repeatedly decode full-resolution album artwork for list items.

Measure performance where possible.

Do not fabricate benchmarks.

# 45. IMPLEMENTATION PHASES

Execute development in the following order.

## Phase 1 — Project Foundation

- Inspect workspace.
- Select architecture.
- Initialize Xcode project.
- Configure Swift tooling.
- Create design system.
- Implement database.
- Implement navigation.
- Create settings.
- Establish dependency injection and service interfaces.

## Phase 2 — Local Music Library

- File import.
- Audio inspection.
- Database persistence.
- Songs.
- Albums.
- Artists.
- Search.
- Playlists.
- File management.

This phase must produce a functioning offline library.

## Phase 3 — Real Music Player

- Audio engine.
- Play/pause.
- Queue.
- Shuffle.
- Repeat.
- Seeking.
- Background playback.
- Lock-screen controls.
- Control Center integration.
- Audio route handling.

This phase must produce a genuinely functional iOS music player.

## Phase 4 — Metadata System

- Embedded tag reading.
- Metadata editing.
- MusicBrainz integration.
- AcoustID integration where configured.
- Album artwork.
- Confidence-based matching.
- Batch editing.
- Safe file-tag writing.

## Phase 5 — Lyrics

- Lyrics data model.
- Local LRC import.
- Plain lyrics.
- Synchronized lyrics.
- Lyrics provider interface.
- Full-screen lyrics.
- Timing correction.
- Lyrics editor.

## Phase 6 — Playlist Import

- M3U/M3U8.
- CSV.
- XSPF.
- JSON.
- Playlist preview.
- Track matching.
- Missing-track states.
- Provider adapters where API access permits.

## Phase 7 — Downloads

- Fetch protocol.
- Authorized source inspection.
- Audio download jobs.
- Format selection.
- Transfers.
- Tagging.
- Library integration.
- Playlist progress.

## Phase 8 — Advanced Features

- Smart playlists.
- Audio quality comparison.
- Equalizer where feasible.
- Crossfade.
- Loudness normalization.
- Library backup.
- Optional synchronization.
- Advanced storage management.

## Phase 9 — Production Readiness

- Security hardening.
- Privacy checks.
- Accessibility.
- Unit and integration tests.
- Physical device testing.
- Performance optimization.
- Documentation.
- CI.
- Open-source preparation.

Complete fully functional vertical slices.

If the entire scope cannot be completed in one execution, prioritize Phases 1–3 first, followed by metadata, lyrics, playlist imports, and downloads.

Do not create all screens as nonfunctional placeholders.

# 46. FINAL DELIVERABLES

Deliver:

1. Functional iOS application.
2. Music library database.
3. Local audio importer.
4. Native playback engine.
5. Background playback.
6. Lock-screen and Control Center integration.
7. Playlist management.
8. Playlist import engine.
9. Metadata identification.
10. Metadata Studio.
11. Album artwork management.
12. Synchronized lyrics.
13. Lyrics editor.
14. Download manager.
15. Fetch-compatible integration.
16. File management.
17. Library export/import.
18. Audio quality information.
19. Search.
20. Settings.
21. Developer options.
22. UADS Ideas page.
23. Changelog.
24. Automated tests.
25. Documentation.
26. Self-hosted processing configuration.
27. Build instructions.
28. Known limitations.
29. Remaining roadmap.

## Build and Run Instructions

Provide exact commands or documented Xcode steps to:

- Install dependencies.
- Open the project.
- Build for the simulator.
- Build for a physical iPhone.
- Configure code signing.
- Run tests.
- Start an optional download worker.
- Configure metadata services.
- Configure lyrics services.
- Connect a Fetch server.
- Import a sample library.
- Create a production build.
- Export a library backup.
- Restore a backup.

Clearly identify external credentials and platform entitlements.

# 47. DEFINITION OF DONE

Harmony is not complete merely because it displays music artwork or a player interface.

The minimum functional acceptance criteria are:

- A user can import real audio files.
- Audio files persist in the library.
- Songs are grouped into albums and artists.
- The user can create and edit playlists.
- The player can play local music.
- Playback continues when the application is backgrounded, subject to supported iOS behavior.
- Lock-screen playback controls work.
- A playlist file can be imported.
- Tracks can be matched with appropriate confidence handling.
- Metadata can be edited.
- Album artwork can be displayed and changed.
- Local synchronized lyrics can be loaded and displayed accurately.
- Library search works offline.
- The user can export music files and playlist data.
- The application remains usable without a streaming subscription.
- Core functionality has automated tests.
- The codebase is buildable and documented.

The broader release goals additionally include real provider-backed enrichment, downloadable authorized media, Fetch interoperability, and full library backup/restore.

Do not label mocked integrations as complete.

Report each major feature as:

- Implemented and tested.
- Implemented but not fully tested.
- Partially implemented.
- Not implemented.
- Blocked by external access or platform requirements.

# 48. EXECUTION DIRECTIVE

Begin implementation immediately.

Inspect the workspace.

Select the final technical architecture.

Start by implementing the local music library and playback engine.

Verify that real imported music can play correctly before spending time on advanced provider integrations.

Then implement metadata management, synchronized lyrics, playlist imports, and Fetch-compatible download infrastructure.

Use actual audio test fixtures that are original, freely licensed, or otherwise authorized.

Do not use copyrighted commercial recordings or lyrics as bundled test fixtures without permission.

Run available builds and tests.

Fix compilation errors, runtime crashes, incorrect playback states, and broken import flows.

Document genuine limitations.

Do not stop after creating a plan.

Do not build a static player UI that cannot play real music.

Do not require external services for basic playback.

Do not duplicate Fetch's backend unnecessarily.

Do not implement DRM circumvention.

Prioritize correctness, reliability, privacy, audio quality, and user ownership.

**Final objective: deliver a beautiful, complete, open-source iOS music application that can import playlists, manage legitimately acquired audio, identify recordings, organize metadata, display synchronized lyrics, and provide an excellent offline listening experience without mandatory subscriptions or proprietary lock-in.**