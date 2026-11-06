# ADR 0001: native Apple local-first core

Date: 2026-11-06. Status: adopted for the development preview.

The explicit Harmony brief prioritizes SwiftUI, real local playback and iOS integrations. Use SwiftUI/AVPlayer with actor-owned SQLite rather than introducing React Native, a mandatory backend or a web application. macOS shares the same UI and core; Android and web are outside this initial supported scope. This specializes the universal multiplatform defaults without silently promising unsupported platforms.

Avoid a third-party database dependency for this slice: system SQLite provides durable transactions and indexed queries while allowing compilation with the installed tools. The wrapper stays private and small. The schema is deliberately narrower than the final normalized model and must migrate safely as the library expands.

Use AVPlayer for proven system playback, audio sessions and media controls. Do not claim EQ, crossfade, bit-perfect or seamless gapless playback; those require further architecture evaluation and evidence. Keep server processing optional and Fetch behind a capability interface. Never implement unauthorized subscription extraction.
