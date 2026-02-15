#!/bin/sh
# Initialize WireGuard Easy environment
# Called by pre-install-cmd with APP_DEFAULT_PASSWORD as argument

PASSWORD="$1"
WIREGUARD_DIR="/DATA/AppData/wgeasy/wireguard"

# Generate bcrypt hash for v14
HASH=$(docker run --rm ghcr.io/wg-easy/wg-easy:14 wgpw "$PASSWORD" 2>/dev/null | grep '^\$')

# Escape $ as $$ for docker-compose env file
ESCAPED_HASH=$(echo "$HASH" | sed 's/\$/\$\$/g')

# Write to env file
echo "PASSWORD_HASH=${ESCAPED_HASH}" > "${WIREGUARD_DIR}/.env"

echo "Password hash generated successfully"
