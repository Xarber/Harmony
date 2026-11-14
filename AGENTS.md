# Harmony agent entry point

Read `docs/INDEX.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, and `docs/IDEAS.json` before meaningful changes. The complete original product brief is in `docs/PROJECT_SPECIFICATION.md`. Apply the user's Universal Application Development Standards; project-specific decisions and truthful implementation status are recorded here.

## Authorized scope and workflow

- Native Swift/SwiftUI; iOS/iPadOS 17+, macOS 14+. Web PWA lives in `web/`. Preserve the native SwiftUI targets. Evaluate Expo/React Native for future native Android requirements. See `docs/WEB.md`.
- AGPL-3.0-only for original source. Do not relicense without explicit authorization. Media and external provider content retain their own rights.
- Work on `testing` or a temporary isolated branch; promotion is `testing → beta → main`. Do not promote this development preview as stable.
- The public source repository is `Xarber/Harmony` and the production PWA runs at `https://harmony.xcenter.it` on the X-Center appliance. This authorization covers the source and the hosted web app. Native release publication, external stores, paid infrastructure and modifications to unrelated projects require separate authorization.
- Conventional Commits, atomic changes, documentation and a truthful test report are required. Prefer configured hardware signing. If unavailable, commit unsigned without changing identity. Obtain approval before rewriting existing commits. Never discard user changes.
- Consult relevant design and motion skills before substantial UI work. See `docs/DESIGN.md` for Harmony’s tokens, contrast, and accessibility behavior.
- Run `scripts/check.sh`. It selects an existing stable SDK on this machine when the new CLT SDK lacks SwiftUI macros; it installs nothing. Use full Xcode for iOS validation.
- Do not add dummy screens or claim mocked integrations work. Check `docs/ROADMAP.md` before assuming a provider or feature is implemented.

## Architecture and safety

- `HarmonyCore/LibraryStore` owns SQLite and managed files. Its actor owns one SQLite connection; no raw handle escapes. All queries bind values. Keep file copies separate from recording identity.
- `PlaybackController` is the single playback authority. Screens must not instantiate their own AVPlayer. Keep lyric timing tied to the real player clock.
- Imported originals must remain intact. Library record removal deliberately retains managed audio for recovery.
- Do not write binary audio tags by hand. Database edits currently do not modify embedded tags.
- No automatic external lookups, fingerprinting or uploads. MusicBrainz is explicit opt-in per search. No credentials in logs, source or backups.
- Tests generate original audio in per-test temporary roots. GUI QA must use `scripts/run-mac.sh --qa-library "$PWD/.build/QA-Library"`. Never insert fixtures into the normal library.
- Playlist paths are untrusted metadata, never automatic file-access permission. Preserve order and duplicate occurrences. Never automatically accept title-only matches.
- Any new provider, codec or dependency requires version, license, policy and platform verification.
- Future extensions must use the documented provider/backend capability boundaries. A full arbitrary-code plugin runtime is not authorized or implemented.

## Ideas retrieval

1. Read and validate `docs/IDEAS.json`; count pending, approved and deferred entries.
2. Summarize relevant ideas, newly recorded entries and any apparently already implemented features.
3. Offer relevant optional ideas for now or later without interrupting unrelated work repeatedly. Do not implement unselected ideas automatically.
4. Preserve deferred entries, history and IDs. Mark implemented only after verification and link commits/version/changelog.
5. On-device Ideas are private SQLite records. They are NOT automatically accessible here. Ask for/use an authorized JSON export when needed; do not claim retrieval from the device without actually reading it.
6. Imports preserve existing IDs; conflicting entries need a deliberate review rather than silent replacement.

## Known environment limit

During initial development, `/Applications/Xcode-beta.app` was a broken symlink to the disconnected external disk. CLT Swift 6.4 and macOS SDK 26.5 were available. iOS compilation, simulator, physical-device background audio, remote controls and signing remain unverified. Recheck live tools before continuing.
