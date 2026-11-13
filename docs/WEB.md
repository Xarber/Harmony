# Harmony Web

Build with Node 22 or newer using `node web/build.mjs`. Run `node web/server.mjs` and open http://127.0.0.1:4175/. Node 24 was used for validation. The runtime uses browser APIs and has no package dependencies.

The first visit at `/` shows the landing page. Entering the library records a local preference. Subsequent visits go directly to `/app/`. The logo returns to the landing at `/` and browser history follows both views. The same document keeps playback and editor drafts alive. A deliberate return to the landing survives reload for that history entry. Deep links to `/app/` open the library directly. If browser storage is unavailable, the landing remains available on a fresh visit. Native builds use their existing SwiftUI entry and onboarding.

IndexedDB separates track metadata, file blobs, playlists, Ideas and playback state. Track and file writes share one transaction. A unique SHA-256 index identifies duplicate files. Imports validate decoding and duration using the browser. Original files stay intact. The 256 MB per-file limit bounds memory used by hashing. The app supports search, favorites, editable metadata, local LRC, playlist ordering, match review, individual file export and metadata export. Browser data is scoped to its origin. Native storage and browser storage are independent. Ideas can be moved manually through the shared JSON format.

The service worker precaches versioned static files and updates on explicit approval. Applying an update requires paused playback and completed edits/imports. Audio and private records remain in IndexedDB. The manifest includes standalone launch, a library shortcut, standard and maskable icons, and an Apple touch icon. HTTPS is required outside loopback. Browser installation, media session controls and storage retention depend on the platform.

Use `node --test web/tests/*.test.mjs` for domain checks. To include the browser test runner, use `node web/build.mjs --qa`, then open `/tests/browser.html`. Use `/app/?qa=1` for an isolated manual test library. Generate original fixtures with `python3 scripts/make-test-library.py`. The normal build excludes the test runner.

SwiftUI remains the native Apple implementation because it already provides AVFoundation, MediaPlayer and iOS lifecycle integration. The PWA provides browser access on Android and other desktop platforms. Evaluate Expo and React Native when there is a requirement for an Android native package, sustained background audio or tighter OS integration. React Native macOS/Windows, Tauri and Electron were considered as ways to reach more desktop users. The current browser version provides that reach without duplicating the existing Mac player or introducing a second desktop runtime.

Remaining gaps include embedded tag and artwork editing on web, full audio backup, cross-device sync and physical phone installation tests. See [validation](reports/2026-11-13-uads.md).
