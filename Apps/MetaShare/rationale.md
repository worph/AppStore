# MetaShare — Rationale

## What deviation / exception is being requested

1. `metashare-app` runs `user: 0:0`.
2. It publishes host port `4001/tcp` (libp2p).
3. It mounts `/DATA/AppData/metacore/meta-core` — another app's AppData directory.
4. Six HTTP paths bypass the SSO gate and are proxied straight to the backend:
   `/health`, `/api/peers*`, `/api/peer/*`, `/api/file/*`, `/api/search*` and
   `/api/services`.

## Why it is necessary

1. MetaShare writes its service registration into `/meta-core/services/`, a directory
   created and owned by MetaCore's root-running container.
2. libp2p is **not HTTP**. Caddy is an HTTP reverse proxy and cannot carry it, and remote
   peers resolve this node's public multiaddr from the kad-DHT and dial it directly. Without
   a published, inbound-reachable TCP port the node can only make outbound connections and
   never serves bytes to the swarm. The app therefore carries the reserved
   `needs-public-ip` tag so a user behind CGNAT or the mesh-router tunnel can see the
   limitation before installing.
3. `/meta-core` is the shared leader-election and service-discovery directory. MetaCore is
   a hard prerequisite of this app.
4. Those are the **federation surface**: remote MetaShare peers call them to enumerate
   peers, resolve records, search, and fetch blocks. A remote peer is a machine client with
   no cookie jar and no way to complete an interactive OIDC redirect, so gating them makes
   the app unable to federate at all — which is its only function. Every other path,
   including the whole dashboard, stays behind the gate.

## Security mitigations in place

- Public ingress terminates at the AppShield sidecar (`ghcr.io/yundera/appshield:2.0.9`),
  which gates every path behind the PCS's Authelia SSO over OIDC. The backend carries no
  Caddy labels and publishes no HTTP port to the host, so it is reachable only from the
  `pcs` Docker network.
- Every service declares `cpu_shares`, and the memory-heavy ones a hard `mem_limit` with
  `memswap_limit` equal to it (swap disabled, so the container is OOM-killed rather than
  pushing the host into swap).
- Image tags are pinned; no `:latest` anywhere in the stack.

- The bypassed paths are read-only federation endpoints scoped to content the user has
  explicitly shared. They expose no configuration, no dashboard and no write operation, and
  they serve exactly what this node already publishes to the public swarm over libp2p — so
  gating them would protect nothing that the DHT does not already carry.
- The published port speaks libp2p only. libp2p transport is authenticated and encrypted
  (Noise) and peer identity is a public key, so an unauthenticated dial cannot read
  anything the node has not chosen to publish to the swarm. The HTTP API stays on
  `expose:` behind AppShield.

## Alternatives considered and rejected

- **Proxy libp2p through Caddy.** Not possible: Caddy fronts HTTP, and the DHT advertises a
  raw TCP multiaddr.
- **Outbound-only / relayed transport.** Works for reachability but not for serving: a node
  nobody can dial contributes no bytes, which is the app's entire function.
- **Run as `$PUID:$PGID`.** Fails writing into MetaCore's root-owned
  `/meta-core/services/`.

## Data protection

MetaShare's own store lives under `/DATA/AppData/metashare/{config,data}/`, declared in
`x-compose-app.folders` and archived by Maison on uninstall. Only content the user has
explicitly shared is published to the swarm; nothing under `/DATA/Documents`,
`/DATA/Downloads` or `/DATA/Media` is mounted into this container at all.
