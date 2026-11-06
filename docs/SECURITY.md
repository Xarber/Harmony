# Security controls and remaining work

This is selected-module development review, not a full security audit.

Implemented: actor-confined SQLite with bound parameters, transactions, foreign keys and rejection of newer schema versions; managed-path containment including symlink resolution; local file regularity/size/free-space checks; incremental hashes; AVFoundation audio/playability validation; preserved originals; bounded playlist/lyrics imports; disabled XML external entities and rejected declarations; conservative recording matches; private offline Ideas; no hardcoded credentials.

Direct HTTPS download rejects embedded credentials and redirects, uses ephemeral session storage and bounds received bytes. Fetch accepts HTTPS and runtime tokens, rejects redirects, validates safe IDs, negotiates protocol/format and checks successful responses. These client checks are not a server SSRF defense. No processing backend has been exposed.

Playback does not execute metadata. User artwork is raster-only in the picker. Imported playlist paths are not dereferenced. Metadata restore strips artwork paths, validates IDs and schema and preserves existing records. No ZIP extraction is implemented, so no unvalidated archive extraction is enabled.

Gaps before production: durable import transaction journal; image pre-decode/decompression limits; storage reservation for network transfers; streaming backup/export; stricter model validation/field limits across every public mutation; future schema migration/recovery tooling; bounded provider streaming responses; file-protection policy/device tests; credential pairing and Keychain if Fetch is connected; network protocol integration tests; signing/notarization, dependency/release provenance and device QA.

The system SQLite binding uses a narrow C interop region for SQLITE_TRANSIENT. No third-party packages/decoders are linked. Swift/Apple frameworks retain their platform licensing; original Harmony code uses AGPL-3.0-only. Distribution through stores and future FFmpeg/decoder libraries require a separate compatibility evaluation before publication.
