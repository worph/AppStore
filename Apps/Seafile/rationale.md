# Seafile Rationale

## User Permissions

Seafile runs as root (`user: 0:0`) because the official `seafileltd/seafile-mc` Docker image contains multiple integrated processes that require elevated permissions:

- Nginx web server for HTTP/HTTPS handling
- Seafile server processes for file management
- Database connectivity and management processes
- File system operations and permission management

Similar to Nextcloud, some Seafile processes break when not run as root due to the complex multi-process architecture within the container.

## Volume Usage

Seafile follows the AppData-only usage pattern:
- Primary storage: `/DATA/AppData/seafile/` (container-managed data)
- Database storage: `/DATA/AppData/seafile/db/` (container-managed data)

This is acceptable for root containers according to CasaOS guidelines since users should not directly modify these system-managed files.

## Media Access

The additional volume mappings to `/DATA/Media` and `/DATA/Documents` are read-only or controlled access patterns that don't require user-level permissions, as Seafile manages file access through its own permission system.

## Authentication

Authentication is directly managed by Seafile itself through its built-in user management system with secure login functionality.