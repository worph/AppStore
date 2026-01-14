# MetaSort - MetaMesh Ecosystem

MetaSort is part of the **MetaMesh ecosystem**, a suite of 3 interconnected apps that work together to organize and serve your media library. This is the first "composed app" in the store - multiple independent apps sharing infrastructure.

## The MetaMesh Ecosystem

| App | Role | Port | Dependency |
|-----|------|------|------------|
| **MetaSort** | Metadata extraction, file indexing, plugin system, Redis leader | 80 | None (install first) |
| **MetaFuse** | Virtual filesystem (FUSE + WebDAV) | 80 | Requires MetaSort |
| **MetaStremio** | Stremio addon with HLS transcoding | 7000 | Requires MetaSort |

```
┌─────────────────────────────────────────────────────────────┐
│                     User's Media Files                       │
│              /DATA/Downloads, /DATA/Media, etc.              │
└──────────────────────────┬──────────────────────────────────┘
                           │ (read-only bind mounts)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                        MetaSort                              │
│  • Watches folders for new files                             │
│  • Extracts metadata via container plugins                   │
│  • Stores metadata in Redis                                  │
│  • Runs Redis as leader                                      │
│  • Manages /files volume (plugin output, posters, etc.)      │
└──────────────────────────┬──────────────────────────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    metamesh-files   /DATA/Apps/MetaCore   metamesh (network)
    (named volume)   (bind mount)          (docker network)
           │               │               │
           │               │               │
     ┌─────┴─────┐   ┌─────┴─────┐   ┌─────┴─────┐
     ▼           ▼   ▼           ▼   ▼           ▼
┌─────────┐ ┌─────────┐
│MetaFuse │ │MetaStremio│  (connect to shared resources)
└─────────┘ └─────────┘
```

## Shared Infrastructure

### 1. MetaCore Directory (`/DATA/Apps/MetaCore`)

A **bind mount** (not a named volume) shared by all MetaMesh apps. Contains:

```
/DATA/Apps/MetaCore/
├── db/redis/          # Redis database (metadata storage)
├── locks/             # Leader election lock files
└── services/          # Service discovery JSON files
```

**Why a bind mount?**
- Persists independently of Docker volume lifecycle
- Predictable location for debugging/backup
- Survives app reinstalls

### 2. Files Volume (`metamesh-files`)

A **named volume** created by MetaSort, used read-only by other apps:

```
/files/                      (inside container)
├── watch/                   # User media (bind mount overlays)
│   ├── downloads/           # → /DATA/Downloads
│   └── media/               # → /DATA/Media
├── plugin/                  # Plugin-generated files
│   ├── subtitles/
│   └── metadata/
├── poster/                  # Downloaded poster images
└── <remote>/                # rclone remote mounts (optional)
```

**Why a named volume?**
- Plugin output needs to be written by MetaSort
- Other apps need read access to plugin output
- Separates internal data from user's media

### 3. Network (`metamesh`)

Docker bridge network for inter-container communication:
- MetaFuse/MetaStremio connect to `redis://metasort:6379`
- All apps can discover each other by container name

## Installation Order

**MetaSort must be installed first** - it creates the shared resources:

1. **Install MetaSort** → Creates `metamesh-files` volume, `metamesh` network
2. **Install MetaFuse** and/or **MetaStremio** → Connect to existing resources

If MetaFuse/MetaStremio are installed without MetaSort, they will fail to start (external volume/network not found).

## Volume Permissions

| Resource | MetaSort | MetaFuse | MetaStremio |
|----------|----------|----------|-------------|
| `/DATA/Apps/MetaCore` | rw (leader) | rw (follower) | rw (follower) |
| `metamesh-files` | rw (creates) | ro | ro |
| User media dirs | ro | ro | ro |
| `metamesh` network | creates | external | external |

## Why This Architecture?

### Problem
A media organization system needs multiple specialized services:
- **Indexing** (CPU-intensive, runs plugins)
- **Virtual filesystem** (needs FUSE, privileged)
- **Streaming** (needs FFmpeg, transcoding cache)

Running all in one container means:
- Huge image size
- Can't scale services independently
- Single point of failure
- Complex privilege requirements

### Solution
Split into 3 focused apps that share:
- **Data** via named volume (`metamesh-files`)
- **State** via bind mount (`/DATA/Apps/MetaCore`)
- **Communication** via Docker network (`metamesh`)

Users can install only what they need:
- Just indexing? → MetaSort only
- Want organized folders? → MetaSort + MetaFuse
- Want Stremio streaming? → MetaSort + MetaStremio
- Want everything? → All three

## Developer Notes

### Adding a New MetaMesh App

1. Use `external: true` for volumes/networks
2. Mount `/DATA/Apps/MetaCore:/meta-core:rw`
3. Mount `metamesh-files:/files:ro`
4. Join `metamesh` network
5. Connect to Redis at `redis://metasort:6379`

### Debugging

```bash
# Check Redis data
docker exec metasort redis-cli keys '*'

# Check leader election
cat /DATA/Apps/MetaCore/locks/kv-leader.lock

# Check service discovery
ls /DATA/Apps/MetaCore/services/

# Check files volume content
docker exec metasort ls -la /files/
```

### Testing Locally

The MetaMesh dev environment in the source repo (`meta-root-v2/dev/`) mirrors this architecture for testing.
