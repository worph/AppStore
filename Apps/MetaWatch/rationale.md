# MetaWatch — Rationale

## What deviation / exception is being requested

1. `metawatch-core`, `metawatch-search` and `metawatch-share` run `user: 0:0`, and
   `metawatch-core` runs `privileged: true`.
2. The stack publishes two host ports: `4003/tcp` and `4004/tcp` (libp2p).
3. The app exposes **three** public hostnames — `metawatch-`, `metawatchshare-` and
   `metawatchsearch-` — each with its own AppShield sidecar, so two sidecar
   `container_name`s differ from the compose top-level `name:`.

## Why it is necessary

1. `metawatch-core` is a bundled MetaCore: rclone remote mounts need a mount namespace
   (`SYS_ADMIN` + `/dev/fuse` + an unconfined AppArmor profile), plus nginx and Redis.
   `metawatch-search` and `metawatch-share` write service registrations into the root-owned
   `/meta-core/services/`.
2. libp2p is **not HTTP** — Caddy cannot proxy it, and remote peers resolve this node's
   public multiaddr from the kad-DHT and dial it directly. Without inbound reachability the
   node never serves bytes to the swarm. The app therefore carries the reserved
   `needs-public-ip` tag.
3. Each hostname is a distinct UI, and `auth-registrar` derives an app's OIDC `client_id`
   from the sidecar's container name via PTR lookup, so three routes need three stable,
   distinct names. `x-casaos.main` points at `metawatch`, the sidecar carrying the primary
   route.

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
- **One sidecar with path-based routing.** The three backends generate absolute URLs and
  set cookies on their own hostnames; path-mounting them breaks both.
- **Drop `privileged` from `metawatch-core` for a `cap_add` list.** Same container as
  MetaCore; the reduced form was tried and still failed to bring up the supervised daemons.
- **Use the shared-backend variant instead.** That is `MetaWatchShared`, for a box that
  already runs MetaCore and MetaShare. This app is the self-contained one.

## Data protection

All state lives under `/DATA/AppData/metawatch/`, declared in `x-compose-app.folders` and
archived by Maison on uninstall, so an uninstall/reinstall with "keep user data" returns My
List and Continue Watching intact. No user media directory is mounted into any service;
bytes are served through the app's own transport peer.
