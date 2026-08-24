# MetaWatch (shared backend) — Rationale

## What deviation / exception is being requested

1. `metawatch-app` is **publicly routed with no AppShield sidecar** — it carries the
   `caddy_*` labels itself.
2. `metawatch-search` runs `user: 0:0` and publishes host port `4004/tcp` (libp2p).
3. The stack mounts `/DATA/AppData/metacore/meta-core`, another app's AppData directory.
4. The compose top-level `name:` is `metawatch`, the same project id as the self-contained
   `MetaWatch` app in this store.

## Why it is necessary

1. meta-watch has its **own** authentication: a secp256k1 keypair proven by signing a
   challenge, with invite-only signup. It is enabled by default and cannot be bypassed —
   the "app's own built-in auth" alternative the security checklist accepts. Putting
   AppShield in front would add a second, unrelated identity on top of the keypair the app
   uses to sign records into the swarm.
2. `metawatch-search` writes its service registration into the root-owned
   `/meta-core/services/`. libp2p is not HTTP — Caddy cannot proxy it and remote peers dial
   the advertised multiaddr directly, so the port must be published and inbound-reachable.
   The app carries the reserved `needs-public-ip` tag.
3. This is the point of the variant: it reuses the standalone MetaCore's identity keystore
   and record store rather than bundling a second one. MetaCore and MetaShare are hard
   prerequisites, stated in `tips.before_install`.
4. The two MetaWatch variants are alternatives, not companions — they share the project id
   and the same `/DATA/AppData/metawatch/` paths so that installing one over the other
   reuses the same data. Exactly one may be installed at a time.

## Security mitigations in place

- meta-watch's signature-challenge login is on by default, and signup is invite-only, so a
  stranger reaching the public hostname cannot create an account.
- The `metawatch-search` dashboard *is* behind an AppShield sidecar
  (`ghcr.io/yundera/appshield:2.0.9`) with Authelia SSO; only the meta-watch UI itself uses
  its own gate.
- `metawatch-app` runs unprivileged as `1000:1000` with a 512 MB hard memory cap and swap
  disabled.
- The only published port is raw libp2p TCP; no HTTP port is published to the host.
- No user directories are mounted — no `/DATA/Documents`, `/DATA/Downloads`, `/DATA/Media`
  or `/DATA/Gallery`.
- `cpu_shares` on every service; image tags pinned.

## Alternatives considered and rejected

- **AppShield in front of `metawatch-app`.** Two identities for one user: the OIDC subject
  and the secp256k1 key the app actually signs with. The app's invite model and its swarm
  identity both key off the latter.
- **Proxy libp2p through Caddy.** Not possible; the DHT advertises a raw TCP multiaddr.
- **Bundle a private MetaCore/MetaShare.** That is the self-contained `MetaWatch` app. On a
  box that already runs them it doubles the memory footprint and splits the record store.
- **A distinct project id so both variants coexist.** They would fight over the same public
  hostnames and the same `/DATA/AppData/metawatch/` paths.

## Data protection

My List and Continue Watching persist in `/DATA/AppData/metawatch/data`, and the recovered
poster/thumbnail blockstore and language prefs in `/DATA/AppData/metawatch/search-data` —
both declared in `x-compose-app.folders` and archived by Maison on uninstall. Because both
MetaWatch variants use those paths, switching between them preserves the user's data. The
MetaCore and MetaShare state this variant reads belongs to those apps and is archived with
them.
