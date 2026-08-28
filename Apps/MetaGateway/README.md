# MetaGateway

Source-bridging tier for MetaMesh: ingests content from external sources and
makes it discoverable across the federation, so **MetaWatch** (and other
MetaShare peers) can find and stream it. Unifies the three dev gateway
sub-stacks (`docker-compose.yml` + `.torznab.yml` + `.tribler.yml`) into one
app sharing a single meta-core, ingester and enrichment plugin pair.

## What's in the stack (13 containers)

| Container | Role |
|-----------|------|
| `metagateway-app` | Gateway peer (feeders-only); writes resolved records to meta-core (dashboard behind OIDC) |
| `metagateway-core` | Dedicated meta-core; auto-store target + WebDAV poster store (watcher ON) |
| `metagateway-share` | meta-share **ingester**: announces resolved records on the swarm, seeds blobs |
| `metagateway-prowlarr` | Bundled Prowlarr torznab aggregator (own public route + forms login) |
| `metagateway-torznab-feeder` | torznab feeder → Prowlarr (+ librqbit BT fetch) |
| `metagateway-tribler` | Headless Tribler core (IPv8 overlay) |
| `metagateway-tribler-feeder` | tribler feeder → Tribler core |
| `book-feeder` / `paper-feeder` / `common-feeder` | Gutenberg / arXiv+PubMed / Wikimedia Commons |
| `metagateway-filename-parser` / `metagateway-tmdb` | Reused meta-sort enrichment plugins |
| `metagateway` | nginx-hash-lock OIDC perimeter for the dashboard |

The gateway discovers its feeders from `gateway-config.json` (the `feeders`
map), and `gateway-enabled.json` opts the `torznab` + `tribler` upstreams in.
Both are written by `pre-install-cmd` into `/DATA/AppData/metagateway/state/` —
edit them there and restart `metagateway-app` to change the feeder set.

## Self-contained meta-core

The gateway's meta-core is **private to the gateway** (it holds resolved feeder
records, not your media library), so this app does **not** use the shared
MetaCore app and coexists with MetaWatch + the standalone Meta* apps without
container-name or data-path collisions.

```
/DATA/AppData/metagateway/
├── metacore/    # gateway meta-core (shared by core + ingester)
├── files/       # WebDAV file store (tmdb posters/backdrops, seeded blobs)
├── state/       # gateway-config.json + gateway-enabled.json + redb caches
├── prowlarr/    # Prowlarr config + db
├── tribler/     # Tribler IPv8 identity + metadata db (+ installed config)
└── tmdb-cache/  # tmdb plugin response cache
```

## First-run setup

1. **Prowlarr** — open `https://metagateway-prowlarr-<domain>/`, finish the
   wizard, add indexers, copy the **API Key**.
2. Set `PROWLARR_API_KEY` and `TMDB_TOKEN` (TMDB v4 read token) on this app,
   then restart. Until set, the **torznab feeder reports as degraded** (the
   reason is visible at its `/health` and in the dashboard) but never crashes —
   the rest of the gateway stays healthy and the app boots normally. Optional:
   `GIPHY_API_KEY` (common-feeder), `SCIHUB_MIRRORS` (paper-feeder).
3. **Tribler** needs no setup — the baked config installs on first boot.

## Federation

Two peers join the **public** libp2p swarm, on two different ports:

| Peer | Port | Role |
|------|------|------|
| `metagateway-app` | TCP **4002** | gateway **discovery** — publishes the kad provider record under the `metamesh-gateway` namespace; this is the peer a remote meta-search finds and dials for live fan-out |
| `metagateway-share` | TCP **4005** | the ingester's records + bitswap byte-serving (cohort `metamesh-share-default`) |

Tribler's IPv8 overlay is UDP **8092**.

**Cross-node discovery needs both the port open inbound AND a public address
set.** Without `META_GATEWAY_PUBLIC_ADDR` the gateway starts in local/mDNS-only
mode: it pulls in no kad bootstraps, publishes no provider record, and binds an
ephemeral port — so no off-host MetaWatch can ever find it, however open the
firewall is. The compose sets it from `${APP_PUBLIC_IPV4}`; on a PCS whose
public IP is not the v4 one, override it. Same-host MetaWatch discovery works
over mDNS on `pcs` regardless.

## Images

| Image | Tag |
|-------|-----|
| `ghcr.io/worph/meta-gateway` | `1.0.25` |
| `ghcr.io/worph/meta-share` | `1.0.26` |
| `ghcr.io/worph/meta-core` | `1.0.12` |
| `ghcr.io/worph/meta-feeder-card` | `1.0.1` |
| `ghcr.io/yundera/appshield` | `2.0.9` |

No feeder images are listed here any more: every content source is a **separate
store app** (MetaFeeder · Books / Papers / Commons / Torznab / Tribler), each
pinning its own images. The gateway discovers them by URL over `pcs` and
soft-skips any that aren't installed.
| `lscr.io/linuxserver/prowlarr` | `latest` |
| `ghcr.io/yundera/nginx-hash-lock` | `1.0.7` |

**Tribler** uses the upstream `ghcr.io/tribler/tribler` image directly (there is
no custom `meta-tribler` image). `pre-install-cmd` fetches the complete REST
config (bound to `0.0.0.0:8085`, key `changeme`) to
`/DATA/AppData/metagateway/tribler-config/configuration.json` and bind-mounts it
at `/seed/configuration.json`; the entrypoint installs it into `/root/.Tribler`
on first boot.

## Resilience notes

- **Feeders run as `user: "0:0"`.** Their image bakes a non-root uid (10001) as
  owner of the state dir, but the platform injects `user: 1000:1000` on services
  without an explicit `user:`; running as root avoids a state-dir permission
  crash.
- **A misconfigured feeder never crash-loops.** The feeder SDK keeps a
  feeder whose config is bad/incomplete *running* and reports it as **degraded**
  via `/health` (with the reason) rather than exiting — so one bad key can't take
  the gateway down. The app gates torznab on `service_started`, not
  `service_healthy`, for the same reason.
