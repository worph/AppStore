# MetaSort - MetaMesh Ecosystem

MetaSort is part of the **MetaMesh ecosystem**, a suite of 4 interconnected apps that work together to organize and serve your media library.

## The MetaMesh Ecosystem

| App | Role | Port | Dependency |
|-----|------|------|------------|
| **MetaCore** | Leader election, Redis, WebDAV, Authelia SSO | 80, 9091 | None (install first) |
| **MetaSort** | Metadata extraction, file indexing, plugin system | 80 | Requires MetaCore |
| **MetaFuse** | Virtual filesystem (FUSE + WebDAV) | 80 | Requires MetaCore |
| **MetaStremio** | Stremio addon with HLS transcoding | 7000 | Requires MetaCore |

```
┌─────────────────────────────────────────────────────────────┐
│                     User's Media Files                       │
│              /DATA/Downloads, /DATA/Media                    │
└──────────────────────────┬──────────────────────────────────┘
                           │ (read-only bind mounts at /files/watch/*)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                       MetaCore                               │
│  • Leader election (flock)                                   │
│  • Redis (metadata storage)                                  │
│  • Authelia OIDC (single sign-on for all dashboards)         │
│  • WebDAV file serving + dynamic mount management            │
└──────────────────────────┬──────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
      /DATA/AppData/metacore/meta-core    pcs (Yundera platform network)
      (bind mount)              (inter-container comms)
           │                           │
     ┌─────┴─────┐  ┌─────────────┐  ┌─────────────┐
     ▼           ▼  ▼             ▼  ▼             ▼
┌─────────┐ ┌─────────┐  ┌─────────────┐
│MetaSort │ │MetaFuse │  │ MetaStremio │
└─────────┘ └─────────┘  └─────────────┘
```

## Shared Infrastructure

### MetaCore Directory (`/DATA/AppData/metacore/meta-core`)

A **bind mount** shared by all MetaMesh apps. Contains:

```
/DATA/AppData/metacore/meta-core/
├── db/redis/          # Redis database (metadata storage)
├── locks/             # Leader election lock files (kv-leader.info)
└── services/          # Service discovery JSON files
```

**Why a bind mount?**
- Persists independently of Docker volume lifecycle
- Predictable location for debugging/backup
- Survives app reinstalls

### User media directories — only mounted into MetaCore

User media is bind-mounted **only into the MetaCore container**:

```
/files/                       (inside MetaCore container)
└── watch/
    ├── downloads/            # ← /DATA/Downloads (host bind, read-only)
    └── media/                # ← /DATA/Media     (host bind, read-only)
```

**MetaSort, MetaFuse, and MetaStremio do not mount `/files` at all.** They reach files through MetaCore's WebDAV endpoint (`http://metacore/webdav/*`), discovering the URL at runtime from the leader-info file in `/meta-core/locks/kv-leader.info`.

This matches the dev stack (Architecture V3) — MetaCore is the single source of truth for media files; siblings are stateless w.r.t. file storage.

Earlier versions had two problems here:
1. A `metamesh-files` named volume mounted at `/files` with the user's media bind-mounted as subpaths. `docker volume rm metamesh-files` then recursively traversed the bind-mount targets (which shared inodes with the host paths) and **deleted everything in `/DATA/Downloads` and `/DATA/Media`**.
2. Even after dropping the named volume, every sibling app duplicated the bind mounts of `/DATA/Downloads` and `/DATA/Media` — multiplying the blast radius of any future bind-mount footgun and breaking the "MetaCore owns files" architectural promise.

Mounting media only into MetaCore eliminates both issues.

### Network (`pcs`)

All MetaMesh containers attach to the Yundera platform network `pcs` (declared `external: true` everywhere). No app-private docker network — services discover each other by container hostname over `pcs`.

## Installation Order

**MetaCore must be installed first** — it provisions the Authelia secrets and OIDC clients that the other apps depend on.

1. **Install MetaCore** → Creates Authelia secrets and OIDC clients (`metasort`, `metafuse`, `metacore`)
2. **Install MetaSort, MetaFuse, MetaStremio** in any order

Each app's `pre-install-cmd` checks for `/DATA/AppData/metacore/authelia/secrets/client-<app>.plain` and aborts with an error if MetaCore hasn't been installed.

## Volume Permissions

| Resource | MetaCore | MetaSort | MetaFuse | MetaStremio |
|----------|----------|----------|----------|-------------|
| `/DATA/AppData/metacore/meta-core` | rw | rw | rw | rw |
| `/DATA/Downloads`, `/DATA/Media` | ro (mounts at `/files/watch/*`) | — (WebDAV) | — (WebDAV) | — (WebDAV) |
| `/DATA/AppData/<app>/cache` | rw (own) | rw (own) | — | rw (own) |
| `/DATA/AppData/metafuse/config` | — | — | rw | — |
| `/DATA/MetaFuse/Library` | — | — | rw (FUSE mount) | — |
| `/DATA/AppData/metacore/authelia/secrets` | rw (creates) | ro (oauth sidecar) | ro (oauth sidecar) | — |
| `pcs` network (Yundera platform) | external | external | external | external |

## Developer Notes

### Adding a New MetaMesh App

1. Add `pre-install-cmd` that checks for `/DATA/AppData/metacore/authelia/secrets/client-<app>.plain`
2. Bind-mount `/DATA/AppData/metacore/meta-core:/meta-core:rw` for leader info / service registration
3. **Do NOT bind-mount user media** — read files via MetaCore's WebDAV (`http://metacore/webdav/*`), URL discovered from `/meta-core/locks/kv-leader.info`
4. Join the `pcs` network as `external: true` (Yundera platform-managed; do not declare an app-private network)
5. Add an `oauth2-proxy` sidecar that reads its client secret from `/DATA/AppData/metacore/authelia/secrets/client-<app>.plain`
6. Discover Redis at runtime by reading `/meta-core/locks/kv-leader.info`

### Debugging

```bash
# Check Redis data (Redis runs in MetaCore)
docker exec metacore redis-cli keys '*'

# Check leader election
cat /DATA/AppData/metacore/meta-core/locks/kv-leader.info

# Check service discovery
ls /DATA/AppData/metacore/meta-core/services/

# Check what's mounted into a service
docker exec metasort ls -la /files/watch/
```

### Testing Locally

The MetaMesh dev environment (`meta-root-v2/dev/`) mirrors this architecture: direct bind mounts of `${DATA_WATCH_PATH}`, `./cache/test/files`, and `./cache/meta-sort/plugin-output` at `/files/watch`, `/files/test`, `/files/plugin` — no parent named volume.
