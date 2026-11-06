# Metadata and artwork

Import reads common embedded title, artist, album and artwork; filename is the fallback title and has explicit provenance. The database stores optional recording IDs, ISRC, album artist, genre, composer, numbering, release date, rating, comments, favorites, counts and timestamps. Not every stored field currently has a dedicated editor control.

Metadata & Lyrics edits title/artist/album/album artist/genre/composer/release date/ISRC/recording ID/comments and favorite state. Manual artwork selection stores a new managed raster file and retains earlier metadata revisions. Automatic file tagging, batch editing, cropping, restore-artwork controls and Cover Art Archive lookup are not implemented. Existing files are never modified by database edits.

## MusicBrainz

An explicit user action sends title and artist to the official recording search API. A shared actor reserves request slots at least 1.1 seconds apart, uses an identifying User-Agent, caps response bytes and treats failures/rate limiting as recoverable. Returned recording title, artist credit, ID and duration are suggestions. Selecting a candidate updates editor values; saving is an explicit second step. Existing manual values are never changed by a background scan because no automatic scan exists.

The adapter compiles but has not been tested against a live MusicBrainz response in this initial run. It is not a fingerprint identifier. AcoustID/Chromaprint and external artwork/lyrics services remain unimplemented. A production deployment must verify service usage and content terms for its use case; API access does not grant rights to all associated content.

References:
- https://musicbrainz.org/doc/MusicBrainz_API
- https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting
- https://developer.apple.com/documentation/avfoundation/retrieving-media-metadata

## Provenance and conflicts

Track provenance maps important fields to embedded, filename, user or user-approved provider sources. Prior database metadata values are retained. The current editor presents alternative candidates but lacks a full per-field conflict comparison and revision-restore UI. Safe embedded tag writing must use an evaluated maintained library with backup, verification and rollback; it must never be implemented as ad-hoc binary rewriting.
