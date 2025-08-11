# Rclone Security and Configuration Rationale

## Security Exceptions

### User Permissions (user: $PUID:$PGID)
**Rationale**: Rclone runs as the system user to ensure proper file ownership and permissions. FUSE mounting is enabled through `SYS_ADMIN` capability and `/dev/fuse` device access.

**Benefits**: 
- Files created/mounted have correct user ownership
- No root-owned files that users cannot modify
- Follows CasaOS security best practices

### Privileged Container
**Rationale**: Required for FUSE mount propagation to work correctly. The `privileged: true` setting is necessary for:
- FUSE filesystem mounting inside containers
- Mount propagation with `:rshared,z` to make mounts visible on the host
- Access to `/dev/fuse` device

**Mitigation**:
- Limited to specific security contexts with `apparmor:unconfined`
- Volumes are specifically mapped and controlled
- Container only exposes web UI port (80)

### Mount Configuration
**Mount Point**: `/DATA/Shared-Rclone:/data:rshared,z`

**Rationale for rshared,z**:
- `:rshared` - Enables recursive mount propagation for FUSE mounts to be visible outside container
- `,z` - SELinux relabeling for proper security context on systems using SELinux

**Important**: Users must mount cloud remotes to `/data` inside the container for files to appear at `/DATA/Shared-Rclone` on the host system.

## Configuration Requirements

### Authentication
- Default authentication enabled via `--rc-user admin --rc-pass $default_pwd`
- Web UI requires login with admin username and generated secure password
- Remote access controlled via `--rc-allow-origin "*"` (necessary for NSL router integration)

### Resource Limits
Standard resource limits applied:
- Memory limit prevents excessive cache usage
- CPU limit ensures fair resource sharing

### Mount Propagation Notes
The FUSE mount setup requires specific Docker configuration:
1. `cap_add: SYS_ADMIN` for mount operations
2. `devices: /dev/fuse:/dev/fuse:rwm` for FUSE access  
3. Mount propagation `rshared,z` for host visibility
4. Users mount remotes to `/data` which maps to `/DATA/Shared-Rclone/` on host