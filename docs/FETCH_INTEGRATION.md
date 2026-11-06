# Proposed Fetch protocol v1

Status: compiled adapter and documented contract; no live interoperability test and no configured Fetch server. Harmony does not claim an existing Fetch implementation uses this API. The client remains independent of a worker for local music.

`AcquisitionBackend` defines capabilities, create, job and cancel. `FetchAdapter` accepts an HTTPS base URL and a runtime bearer token supplied by its caller. It rejects redirects so a credential cannot be forwarded to a different host. Tokens are private in memory. There is no settings/pairing UI or Keychain credential integration yet.

## Endpoints

- GET `api/v1/capabilities`: `{"protocolVersion":1,"audioFormats":["mp3","m4a"],"cancellation":true}`
- POST `api/v1/downloads`: `{"sourceURL":"https://authorized.example/recording","format":"m4a","authorized":true}`
- GET `api/v1/downloads/{id}`: job status.
- DELETE `api/v1/downloads/{id}`: cancel.

Job shape: `{"id":"opaque-safe-id","status":"queued","progress":null,"artifactPath":null}`. Job IDs allow only alphanumeric, dash and underscore, under 128 characters. Client checks protocol version and requested format. Response status must be successful and metadata responses under 5 MB. These are client bounds; they do not replace server limits.

Artifact fetching, checksums, capability-safe output paths, polling persistence, reconnection, discovery and completion/import are not wired into UI. They are required before calling Fetch support complete. No server, Docker stack or start-worker command is delivered because duplicating an unknown Fetch backend would not establish interoperability.

## Required worker controls before connection

Implement authentication/authorization, TLS, source allowlisting, public-IP/redirect/DNS-rebinding SSRF defenses, private-network denial for untrusted media sources, quotas, response/processing size/time limits, safe subprocess argument arrays, unprivileged containers, artifact integrity and access-controlled expiring transfer URLs. Never accept shell commands from a source URL. Never claim the client-side URL checks protect a server from SSRF.

Integrate against Fetch's actual owning API once available. Adapt this interface and add deterministic protocol tests plus authorized live transfer evidence. Do not silently deploy a public worker or incur infrastructure costs.
