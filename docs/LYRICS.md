# Local synchronized lyrics

A LyricsDocument stores original raw text, an independent correction offset, source label and modified timestamp. Saving preserves the prior document in SQLite revisions. Local import accepts UTF-8 text/LRC under 2 MB. It never uploads content.

The LRC parser supports repeated line timestamps, one-to-three digit minute fields, one-to-three fractional second digits, metadata lines and signed millisecond offset headers. Seconds outside 0–59 are rejected. Repeated timestamps create separate lines sorted stably. Plain text is supported when no valid timed lines exist. Timing is derived from the real player clock plus correction offset; positive offsets delay presentation.

The player allows follow scrolling to be disabled and timed lines to seek. Reduced Motion disables scroll animation. Plain lines are read-only text rather than fabricated timing. The editor supports direct raw LRC editing, import, global offset, a current-clock timestamp button, one-step text swap undo and raw LRC export. It is not yet a full waveform synchronization editor with multi-step undo/redo or per-word timing.

Enhanced word-level LRC and TTML are not implemented; no word timing is invented. Instrumental provider flags, embedded lyrics reading, LRCLIB and other lyrics services are not connected. Only import/export lyrics you own or are permitted to use. Metadata-only library backups deliberately exclude lyrics and external artwork.

Parser/offset/selection/export tests passed on macOS. A GUI test saved original LRC text in the isolated QA library. Accurate native lyrics UI after seek/pause and long device playback still require further testing. Revision storage has no user-facing recovery browser yet.
