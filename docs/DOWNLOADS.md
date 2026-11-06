# Authorized acquisition

The Downloads tab offers one active direct HTTPS audio-file download. Users must confirm they own or are permitted to download the recording. This is distinct from playlist metadata import and from a Fetch worker.

DirectDownload uses an ephemeral URLSession, no cookie/credential store, rejects redirects and URL-embedded credentials, limits received bytes to 2 GB, reports actual received/expected byte counts, supports cancellation and times out stalled/overlong transfers. Candidate file extensions are checked; the completed file must pass the normal runtime audio import. Completed means imported locally, not merely downloaded remotely. Temporary output is removed on completion/failure. Source URL and authorization stay in memory, never in backup or diagnostics.

Known gaps: the one transfer view is in-memory, not a persistent background download queue; pause/resume/range requests, storage reservations, connectivity recovery and durable jobs are not implemented. No speed/ETA is invented. Cancellation from URLSession may surface as a failed/cancelled network message. A physical-device HTTP transfer and live direct-audio server were not tested in this run. Constructor security rejection is covered by automated tests.

The Fetch adapter is separate. No standalone FFmpeg/yt-dlp worker, transcoding pipeline, fingerprint service or download notification permission is introduced. Do not use subscription cookies or bypass DRM. See FETCH_INTEGRATION.md for the proposed API and server responsibilities that remain unimplemented.
