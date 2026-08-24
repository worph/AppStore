# MetaGateway — Rationale

## What deviation / exception is being requested

1. `metagateway-core` and `metagateway-share` run `user: 0:0`, and `metagateway-core` runs
   `privileged: true`.
2. The stack publishes two host ports: `4002/tcp` (gateway discovery) and `4005/tcp`
   (meta-share ingester bitswap).
3. The app exposes **three** public hostnames — `metagateway-`, `metagatewaycore-` and
   `metagatewayshare-` — each with its own AppShield sidecar, so two sidecar
   `container_name`s differ from the compose top-level `name:`.

## Why it is necessary

1. `metagateway-core` is a bundled MetaCore: it runs rclone remote mounts, which need a
   mount namespace (`SYS_ADMIN` + `/dev/fuse` + an unconfined AppArmor profile), plus nginx
   and Redis. `metagateway-share` writes its service registration into the root-owned
   `/meta-core/services/`.
2. libp2p is **not HTTP** — Caddy cannot proxy it, and remote peers resolve this node's
   public multiaddr from the kad-DHT and dial it directly. Without inbound reachability the
   node makes outbound connections only and never serves bytes, which is the app's function.
   The app therefore carries the reserved `needs-public-ip` tag.
3. Each hostname is a distinct UI (gateway dashboard, core dashboard, share dashboard) and
   `auth-registrar` derives an app's OIDC `client_id` from the sidecar's container name via
   PTR lookup. Three routes need three stable, distinct names; only one of them can equal
   the top-level `name:`. `x-casaos.main` points at `metagateway`, the sidecar carrying the
   primary route.

## Security mitigations in place

- Every publicly-routed hostname terminates at its own AppShield sidecar
  (`ghcr.io/yundera/appshield:2.0.9`) behind the PCS's Authelia SSO. Each sidecar sets
  `hostname:` equal to its `container_name` so `auth-registrar` can attest it via PTR and
  accept its redirect URIs; the names are app-prefixed, so they cannot collide with another
  app's services in the shared `pcs` DNS namespace.
- The backends carry no Caddy labels and publish **no HTTP port** to the host. The only
  published ports are raw libp2p TCP.
- libp2p transport is authenticated and encrypted (Noise) and peer identity is a public
  key, so an unauthenticated dial cannot read anything the node has not chosen to publish
  to the swarm.
- No user directories are mounted — no `/DATA/Documents`, `/DATA/Downloads`, `/DATA/Media`
  or `/DATA/Gallery`.
- `cpu_shares` on every service; memory-heavy services carry a hard `mem_limit` with
  `memswap_limit` equal to it. All image tags pinned.

## Alternatives considered and rejected

- **Proxy libp2p through Caddy.** Not possible; the DHT advertises a raw TCP multiaddr.
- **One sidecar with path-based routing to all three UIs.** The three backends generate
  absolute URLs and set cookies on their own hostnames; path-mounting them breaks both.
- **Drop `privileged` from `metagateway-core` for a `cap_add` list.** The reduced form is
  most of what `privileged` grants and still failed to bring up the supervised daemons —
  see `Apps/MetaCore/rationale.md`, which is the same container.
- **Split into separate store apps.** That is exactly what MetaCore / MetaShare /
  MetaGatewayShared are. This app is the self-contained variant, for a box that wants the
  gateway without the rest of the ecosystem installed.

## Data protection

All state lives under `/DATA/AppData/metagateway/`, declared in `x-compose-app.folders` and
archived by Maison on uninstall. The two operator-editable config seeds
(`gateway-config.json`, `gateway-enabled.json`) are written only when absent, so a reinstall
or version upgrade preserves the feeder map the user configured from the dashboard. Only
content published to the swarm leaves the box.
