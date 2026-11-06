# Build, run and signing

## Requirements

Swift 6.2+; full Xcode with a compatible iOS SDK for iPhone/iPad builds. Deployment minimums are iOS/iPadOS 17 and macOS 14. No package-manager install step or external dependency is required. The initial local toolchain was Swift 6.4 from Command Line Tools; the existing macOS 26.5 SDK was used because the 27.0 CLT SDK references a missing SwiftUIMacros plugin. This workaround does not prove Xcode/iOS compilation.

The Xcode app at `/Applications/Xcode-beta.app` was a symlink to a disconnected external disk during initial work. Reconnect that disk and verify the toolchain. Use a per-command developer directory rather than changing the machine globally:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcodebuild -version
```

## macOS

From the repository root:

```sh
scripts/run-mac.sh
scripts/check.sh
```

The launcher builds a local unsigned `.build/Harmony.app` and opens it. It embeds the checked-out commit in bundle metadata and appends -dirty when there are uncommitted changes; such builds must not be treated as release artifacts. The CLI workaround uses the already installed SDK, Foundation Testing framework and native SwiftPM build system. Native SwiftPM is deprecated in this toolchain; full Xcode is the preferred normal environment.

## iOS Simulator

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer scripts/build-ios.sh simulator
```

Or open Harmony.xcodeproj, select Harmony, choose an iPhone/iPad simulator and run. No Metro server exists or is required. Build outputs are `.app.zip`, never simulator IPAs. Initial execution was unavailable; simulator launch, rotations, keyboard/safe areas and large text still need verification.

## Physical iPhone/iPad

Open the project in full Xcode. Select the Harmony target, Signing & Capabilities, your authorized development team and a unique bundle ID if your team cannot register the current one. Preserve that identifier and signing identity once distributed. Select a trusted physical device and Run. Automatic signing requires your own Apple developer setup; no signing credentials are included.

For an unsigned device package:

```sh
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer scripts/build-ios.sh unsigned-device
```

This compiles physical-device binaries with signing disabled, then packages Payload/Harmony.app. An unsigned IPA cannot install on an ordinary device without a compatible signing/install workflow. Store/TestFlight submission is not configured or authorized.

## Testing

`./scripts/check.sh` runs Swift Testing on the Mac. It includes generated WAV import and real AVPlayer-clock assertions. There is no iOS UI test target yet. Run the device checklist in docs/PLAYER.md and the validation report before beta promotion. Passing Mac tests does not prove iPhone behavior.

## Project regeneration

```sh
python3 scripts/generate-project.py
plutil -lint Harmony.xcodeproj/project.pbxproj Config/Info.plist
```

The committed Xcode project is a standard project using a local HarmonyCore Swift package. Regeneration updates source references; no project-generator package is installed. A successful plist parse is only structural validation, not an Xcode build.

## Original sample library

```sh
python3 scripts/make-test-library.py
scripts/run-mac.sh --qa-library "$PWD/.build/QA-Library"
```

Import First Light.wav and Quiet Current.wav through Files. They are original, low-volume synthesized fixtures. Import the fixture M3U8 separately, review matches, and add original LRC text via Metadata & Lyrics. QA storage is separate from the normal library. The `--qa-library` override is honored in DEBUG builds only.

## Services and credentials

MusicBrainz search needs no key; use the explicit action in Metadata Studio. No lyrics service, Spotify OAuth, Apple Music authorization or AcoustID credentials are configured. Local LRC works without them. No Fetch server is running and no standalone worker start command is supplied: a worker has not been implemented in this slice. Fetch integration is an adapter contract, documented separately.
