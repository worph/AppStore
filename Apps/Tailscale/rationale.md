# Tailscale Security Rationale

## Userspace Networking Mode

This application runs in userspace networking mode (`TS_USERSPACE=true`) with the following security considerations:

### User Permissions
- Runs as `user: $PUID:$PGID` (non-root) for enhanced security
- No special capabilities or privileges required
- Uses userspace networking instead of kernel TUN/TAP interfaces

### Security Benefits
- Reduced attack surface by avoiding root privileges
- No access to kernel networking interfaces
- All operations contained within user permissions
- Persistent data stored in user-owned directories under `/DATA/AppData/tailscale/`

### Functional Limitations
Userspace mode has some limitations compared to kernel mode:
- Slightly reduced network performance
- Some advanced networking features may be limited
- Exit node functionality available but with userspace constraints

### Design Decision
Userspace mode was chosen to:
- Maximize security by avoiding root privileges
- Ensure compatibility with container security policies
- Provide stable operation in diverse container environments
- Follow container security best practices

This configuration prioritizes security while maintaining core Tailscale functionality for most use cases.