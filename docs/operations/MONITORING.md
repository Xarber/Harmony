# X-Center web operations

The static Nginx virtual host has no account service or server-side library. Check `/health` for ingress health and `/build.json` for deployed commit identity. Confirm `/app/`, the manifest and worker respond, and exercise playback using an isolated browser fixture for functional verification.

Proposed alert thresholds are three successive failures with one-minute spacing and fewer than 14 days to TLS expiry. The X-Center operator owns escalation. Harmony-specific scheduled alerts and log retention have not been verified.

Classify a full outage or confirmed compromise as SEV1, a major flow failure as SEV2, limited degradation as SEV3 and a minor defect as SEV4. Record timestamps, affected commit, impact and redacted evidence. Follow the [deployment rollback procedure](../DEPLOYMENT.md) and recheck ingress and function after recovery.

Target recovery time is 30 minutes with a working prior release directory. The hosted application has no mutable user data, so an RPO for user records does not apply to this host. Recovery requires the source revision, static export, Nginx configuration and appliance TLS. Browser libraries need separate user-managed backups. An isolated timed restore has not been run.
