# MetaMesh Security Rationale

## Why Root Access is Required

MetaMesh requires root privileges (`user: 0:0`) due to the following technical requirements:

### 1. FUSE Filesystem Operations
MetaMesh creates a virtual filesystem using FUSE (Filesystem in Userspace) to provide an organized view of media files without moving them. FUSE operations require:
- `SYS_ADMIN` capability for mounting filesystems
- `DAC_READ_SEARCH` and `DAC_OVERRIDE` for filesystem access control
- Root privileges to manage the FUSE mount at `/DATA/MetaMesh`

### 2. Nginx Web Server
The application runs an embedded nginx server for the web UI and API. Nginx typically requires root privileges to:
- Bind to port 80 (though in this case it's exposed internally)
- Manage worker processes with proper privilege separation
- Handle file operations across different user contexts

### 3. etcd Distributed Database
MetaMesh uses etcd for distributed metadata storage. The etcd process requires elevated privileges to:
- Manage persistent data storage reliably
- Handle network operations and cluster communication
- Ensure data consistency across restarts

### 4. File Ownership Management
While the container runs as root, the entrypoint script uses the provided `PUID` and `PGID` environment variables to ensure that:
- Files created in AppData directories have correct ownership
- Hash cache and database files are accessible to the host user
- The application can read from user directories (Downloads, Media)

### 5. Security Options
The `apparmor:unconfined` security option is required because:
- FUSE operations are restricted by default AppArmor profiles
- The virtual filesystem needs unrestricted access to perform mount operations
- Standard container security would prevent the core functionality

## CPU Share Allocation

MetaMesh is assigned `cpu_shares: 20` (Heavy Background Processing) because:
- It performs intensive hash computation for duplicate detection
- Handles large-scale media indexing (900k+ files supported)
- Processes FFmpeg metadata extraction in the background
- Does not require low-latency user interaction
- Runs continuous monitoring and indexing tasks

This low CPU priority ensures MetaMesh doesn't interfere with interactive applications while still processing large media libraries efficiently.

## Data Access Pattern

MetaMesh follows the recommended permission strategy:
- **Read-only access** to user directories (`/DATA/Downloads`, `/DATA/Media`)
- **Full access** to AppData (`/DATA/AppData/MetaMesh/`) for application data
- **Shared mount** at `/DATA/MetaMesh` for the FUSE virtual filesystem
- Uses `PUID`/`PGID` environment variables for proper file ownership

## Pre-Install Cleanup

The pre-install command performs cleanup operations that require root:
```bash
umount -l /DATA/MetaMesh 2>/dev/null || true
```

This is necessary because:
- Previous FUSE mounts may not have been cleanly unmounted
- Stale mount points prevent new installations
- The lazy unmount (`-l`) ensures cleanup even if the mount is busy
