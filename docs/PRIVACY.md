# Privacy and ownership

No account, subscription, analytics SDK, ad system or mandatory cloud service is included. Local audio, metadata, artwork, lyrics, playlists, ideas and playback state live on the device. Imported originals stay where the user selected them.

Network activity is explicit: MusicBrainz search sends typed title/artist, and a direct download contacts the source the user authorized. Fetch is not configured. Fingerprints, whole audio files, private playlists and listening history are never automatically uploaded. No streaming-service credentials are required.

Listening history is local. Settings can clear counts and last-played dates. A persistent disable-history toggle, export history and per-field privacy settings are not implemented yet. Deleting a library record removes database ownership but retains the managed audio for recovery; it never removes the source file. A full reset/purge flow is not implemented.

Backups contain metadata and playlists only. They exclude audio, artwork, lyrics, tokens and managed paths. Users deliberately exporting audio/lyrics remain responsible for their rights to that content. Provider-specific caching/export policies must be reviewed before adding further integrations.

Diagnostics show counts, runtime and build metadata, not tokens or private content. The debug-only QA root keeps synthetic test music separate from the normal library. No cross-device sync or automatic Ideas repository retrieval is active.
