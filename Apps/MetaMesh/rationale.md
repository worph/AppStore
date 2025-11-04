# MetaMesh Rationale

## FUSE Capabilities

MetaMesh requires FUSE (Filesystem in Userspace) capabilities to create a virtual filesystem that provides an organized view of media files without moving or duplicating them. This requires:

- Device access: `/dev/fuse`
- Elevated capabilities: `SYS_ADMIN`, `SETPCAP`, `DAC_READ_SEARCH`, `DAC_OVERRIDE`, `CHOWN`, `FOWNER`, `SETUID`, `SETGID`
- Security option: `apparmor:unconfined`

These capabilities are essential for the FUSE driver to mount and manage the virtual filesystem inside the container.

## FUSE Mount Exposure

The virtual filesystem is exposed to the host at `/DATA/MetaMesh` using the `shared` mount propagation mode:

```yaml
- /DATA/MetaMesh:/mnt/virtual:shared
```

The `shared` propagation is critical because:
- The FUSE mount is created **inside** the container by the fuse-driver at `/mnt/virtual`
- With `shared` propagation, this mount becomes visible on the host at `/DATA/MetaMesh`
- Without `shared`, the mount would only exist inside the container

This allows users to browse the organized virtual filesystem directly from the host system at `/DATA/MetaMesh`, showing the automatically organized structure (Anime/Movies/TV Shows) without any file duplication.

## Default Watch Folders

The configuration monitors three default media locations:
- `/DATA/Media/Movies` → `/data/watch/movies`
- `/DATA/Media/TV Shows` → `/data/watch/tvshows`
- `/DATA/Downloads` → `/data/watch/downloads`

Users can customize these mappings by:
1. Adding/modifying volume mounts in the docker-compose.yml
2. Updating the `WATCH_FOLDER_LIST` environment variable to match the internal container paths

This approach provides sensible defaults while allowing full customization for diverse media library structures.

## Authentication

### WebDAV Access
WebDAV provides network file sharing access to the virtual filesystem with default credentials:
- **Username**: `metamesh`
- **Password**: `metamesh`

**Security Note**: These default credentials should be changed in production environments. Users should modify the application configuration after installation to set custom credentials.

### Web UI Access
The monitoring dashboard and management interfaces are accessed without authentication by default. In production deployments, consider:
- Placing MetaMesh behind a reverse proxy with authentication
- Using CasaOS's built-in authentication mechanisms
- Restricting network access to trusted networks only

## Multi-Service Architecture

MetaMesh bundles multiple services in a single container:
- **nginx** (port 80): Reverse proxy and web server
- **etcd**: Distributed metadata storage
- **meta-mesh**: Core file processing engine
- **FUSE driver**: Virtual filesystem
- **WebDAV server**: Network file sharing
- **rclone**: Remote storage support
- **etcdkeeper**: Database management UI

All services are orchestrated by the container's entrypoint script and are accessible through the nginx router on port 80. Different services are accessed via different paths:
- `/monitor` - Monitoring dashboard
- `/webdav` - WebDAV file access
- `/etcdkeeper/` - Database management
- Port 5572 - rclone UI (direct port access)

## Performance Configuration

Default configuration:
- **Worker Threads**: 8 (adjustable via `MAX_WORKER_THREADS`)
- **Memory**: Configured for up to 16GB heap (Node.js)
- **File Limits**: Supports 900k+ files and 100TB+ collections

Users with smaller libraries can reduce `MAX_WORKER_THREADS` to match their CPU core count for optimal performance. Conversely, users with very large libraries (>500k files) may need to increase system limits on the host:

```bash
# Increase inotify watches for large collections
sudo sysctl -w fs.inotify.max_user_watches=1048576
```

## Data Persistence

All application data is stored in `/DATA/AppData/MetaMesh/`:
- `cache/` - Temporary processing cache (can be cleared)
- `index/` - File index (important for virtual filesystem)
- `etcd/` - Metadata database (critical - do not delete)

The etcd database can grow up to 100GB for very large collections. Users should ensure adequate storage space in the `/DATA/AppData/` partition.

## Network Exposure

MetaMesh uses the `expose` directive instead of `ports` to work with CasaOS's mesh-router architecture. External access is managed through the router with automatic HTTPS via nsl.sh domains. Direct port mapping is intentionally avoided to maintain compatibility with the mesh routing system.
