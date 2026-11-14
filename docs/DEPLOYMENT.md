# Builds, release policy and deployment

The public repository is [Xarber/Harmony](https://github.com/Xarber/Harmony). Development goes to `testing`. `beta` and `main` currently point at the repository foundation. Native distribution and release publication require separate authorization.

The build workflow supports manual runs and automatic validation on pushes to `beta` and `main` after promotion. Independent jobs produce the production web export, run Swift tests and package macOS, an unsigned iOS device IPA and an iOS Simulator app. Native packages include SHA-256 checksums. The workflow publishes build artifacts only. Android uses the PWA in this project, so APK and AAB outputs are outside the native scope.

## Release gate

Before any beta/stable publication: reconnect full Xcode, compile and launch simulator/device, validate architectures/package IDs/version/build/commit/signing, run all relevant tests, verify background/remote controls and restore/import flows on physical devices, audit policies/licenses and review the roadmap. Preserve previous artifacts and state, publish only through specifically authorized channels and verify actual installed behavior. Do not infer App Store/AltStore/Obtainium authorization from a local build.

The unsigned IPA is for external signing; it is not a signed release. Store and extended builds have not been configured. No arbitrary plugin runtime exists to hide or remove for review.

## Updates and changelog

Structured `Sources/HarmonyApp/Resources/releases.json` powers the in-app changelog. Regenerate CHANGELOG.md with `python3 scripts/generate-changelog.py`. First launch does not show What's New; a changed native version does. Current version tracking is hardcoded to 0.1.0 and must be generalized before later versions/OTA support. Skipped-version aggregation and developer commit-log generation remain incomplete.

There are no published native release artifacts or a configured update manifest endpoint; automatic GitHub update checks and native update actions are not implemented. Do not embed private GitHub tokens to solve this. Before release, configure channel/variant-safe signed metadata and semantic version/build comparison, exclude mutable source-metadata releases and document the supported install/update route. iOS cannot directly install an unsigned IPA. No OTA mechanism is relevant to this Swift app.

## X-Center production

[Harmony](https://harmony.xcenter.it/) uses the appliance's existing Nginx and TLS infrastructure. Its dedicated virtual host uses the same layout as the other appliance sites. Nginx serves files from `/srv/xcenter/apps/harmony/current`, a link to a complete directory under `releases/`. The app keeps audio and metadata in browser storage. It requires no API instance, database, container or server URL input.

Build a production export from the repository root:

```sh
HARMONY_PUBLIC_URL=https://harmony.xcenter.it HARMONY_COMMIT="$(git rev-parse HEAD)" node web/build.mjs --production
```

The origin is a public build setting with the same default in source. Production disables the developer UI and browser QA mode. Stage `web/dist/` under the commit SHA, verify the manifest and build metadata, then switch `current` atomically. On first activation or a virtual-host change, install `infra/xcenter/harmony.vhost.conf` in the appliance's existing Nginx include directory and validate with `nginx -t` before reload. Keep the previous link target and config. Verify HTTPS `/health`, the exact commit in `/build.json`, the manifest, service worker and a browser journey. Allow for a brief interval while Nginx workers pick up configuration changes.

For rollback, restore the previous link target and recheck health and build metadata. If the initial activation has no previous link, restore the prior Nginx configuration and disable the new virtual host. Web rollback does not delete local browser libraries. The Compose files are an optional staging configuration.
