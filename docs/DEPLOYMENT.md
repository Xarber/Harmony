# Builds, release policy and deployment

Repository status: local only, no remote. Branches testing/beta/main exist; main and beta begin at repository foundation, and development work stays on testing. No stable/beta promotion, release, hosted service, external distribution endpoint or paid job has run. Publication was explicitly not authorized in the project brief.

Prepared GitHub Actions workflow triggers manually and on beta/main pushes, not on testing. Independent Mac test, unsigned iOS device and iOS Simulator jobs can run concurrently. Job failures do not cancel successful matrix jobs. Artifacts include version/channel/variant/commit, SHA-256 output and build metadata. The workflow does not publish releases. GitHub runner cost/quota must be evaluated before activation; a configured YAML file is not proof a build succeeded.

Android APK/AAB are not applicable to the chosen native Apple scope. There is no web app; PWA support is required if a web management application is later authorized and implemented. macOS is a local developer app, not yet signed/notarized or distributed.

## Release gate

Before any beta/stable publication: reconnect full Xcode, compile and launch simulator/device, validate architectures/package IDs/version/build/commit/signing, run all relevant tests, verify background/remote controls and restore/import flows on physical devices, audit policies/licenses and review the roadmap. Preserve previous artifacts and state, publish only through specifically authorized channels and verify actual installed behavior. Do not infer App Store/AltStore/Obtainium authorization from a local build.

The unsigned IPA is for external signing; it is not a signed release. Store and extended builds have not been configured. No arbitrary plugin runtime exists to hide or remove for review.

## Updates and changelog

Structured `Sources/HarmonyApp/Resources/releases.json` powers the in-app changelog. Regenerate CHANGELOG.md with `python3 scripts/generate-changelog.py`. First launch does not show What's New; a changed native version does. Current version tracking is hardcoded to 0.1.0 and must be generalized before later versions/OTA support. Skipped-version aggregation and developer commit-log generation remain incomplete.

There is no authorized release repository or update manifest endpoint; automatic GitHub update checks and native update actions are not implemented. Do not embed private GitHub tokens to solve this. Before release, configure channel/variant-safe signed metadata and semantic version/build comparison, exclude mutable source-metadata releases and document the supported install/update route. iOS cannot directly install an unsigned IPA. No OTA mechanism is relevant to this Swift app.

## Rollback

No production deployment exists to roll back. For development, keep the library directory and original files before testing schema changes. Metadata-only backup is not an audio backup. Use atomic Git commits to revert code changes; never delete user audio to roll back an application build. Future migrations require schema-version checks and a recoverable database snapshot.

## X-Center web staging

X-Center is the default hosting target. The web workflow prepares a static artifact with `node web/build.mjs`. The candidate container files live in `infra/xcenter/`. They serve static files and expose `/health`. The Compose port binds to loopback, and the container has a read-only filesystem, resource limits and no mounted library. Browser audio never enters the container.

Before activation, verify the X-Center access scope, select an unused loopback port, pin the approved base image digest and stage the exact tested commit. Validate the Compose configuration, launch the isolated service and check `/health`, `/build.json`, the manifest, audio import and offline reopen through the intended HTTPS ingress. Configure access controls at the existing proxy before sharing a private URL. Preserve the previous image and proxy mapping for rollback. The static service does not own user music backups. Browser users keep original files and export their data locally.

X-Center deployment and container runtime validation are pending. Local browser tests used the loopback Node server. GitHub Actions contains an independent web artifact job. Its remote execution is pending.
