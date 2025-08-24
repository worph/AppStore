# Tailscale Security Rationale

## Root User Requirement

This application runs as `user: 0:0` (root) for the following technical reasons:

### Network Operations Requirement
Tailscale requires root privileges to:
- Create and manage TUN/TAP network interfaces (`/dev/net/tun`)
- Modify routing tables and network configuration
- Set up mesh VPN connections at the kernel level
- Configure IP forwarding and NAT traversal

### Container Capabilities
The container also requires:
- `NET_ADMIN` capability for network interface management
- `NET_RAW` capability for raw socket operations
- System control parameters (`net.ipv4.ip_forward=1`)

### Security Considerations
- Root access is confined to the container environment
- Network operations are isolated within the container's network namespace
- Tailscale's security model is based on cryptographic authentication, not filesystem permissions
- All persistent data is stored in user-owned directories under `/DATA/AppData/tailscale/`

### Alternative Considered
Running as non-root user with userspace networking (`TS_USERSPACE=true`) was considered but rejected because:
- Reduces performance significantly
- Limits exit node functionality
- May cause compatibility issues with advanced Tailscale features

This follows Tailscale's official Docker documentation recommendations for VPN server deployments.