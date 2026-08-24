# MetaMCP — Rationale

## What deviation / exception is being requested

Authentication is the application's **own** login (better-auth), configured during
first-launch onboarding, rather than the recommended AppShield + Authelia OIDC sidecar.

## Why it is necessary

MetaMCP is an MCP aggregator with a first-class multi-user model of its own: it issues API
keys, scopes MCP namespaces per user, and signs machine clients in with those keys. Its
session cookie and its API-key auth are the same subsystem. Fronting it with a second,
outer SSO gate would break API-key access for the MCP clients that are the point of the app,
while duplicating the human login it already performs. This is the "app handles
authentication configuration on first launch via an onboarding process" exception the
guidelines list (the same one Jellyfin and Immich take).

## Security mitigations in place

- Auth is **enabled by default**, not opt-in: the first request redirects to signup, and
  `BETTER_AUTH_SECRET` is seeded from `$APP_DEFAULT_PASSWORD` — the platform-generated
  secret — never a hardcoded literal.
- The Postgres credentials come from `$APP_DEFAULT_PASSWORD` too; nothing is hardcoded.
- `metamcp-postgres` is on the app-private `metamcp` bridge network only. It carries no
  Caddy labels, publishes no host port, and is not reachable from the shared `pcs` network,
  so no sibling app can resolve or dial it.
- `pgdata` is declared in `x-compose-app.folders` with `mode: "0700"`; Postgres refuses to
  start on a data directory with group or world permissions, so this is both a hardening
  measure and a correctness one.
- No service runs as root by choice; image tags pinned; `cpu_shares` on both services and a
  2 GB memory limit on the app.

## Alternatives considered and rejected

- **AppShield in front of MetaMCP.** Breaks API-key and MCP-client access, which cannot
  complete an interactive OIDC redirect, and double-prompts humans.
- **AppShield with `OAUTH_RESOURCE` on the MCP paths.** The right shape for an MCP server
  with no auth of its own; MetaMCP already brokers its own per-user keys, so this would put
  two independent authorization systems on one endpoint.
- **Disabling MetaMCP's own auth and relying on the gate.** Not supported upstream — the
  user model is what scopes namespaces.

## Data protection

All state is in Postgres under `/DATA/AppData/metamcp/pgdata/`, declared in
`x-compose-app.folders` and archived by Maison on uninstall, so an uninstall/reinstall with
"keep user data" returns servers, namespaces and API keys intact. Nothing under
`/DATA/Documents`, `/DATA/Downloads`, `/DATA/Media` or `/DATA/Gallery` is mounted.
