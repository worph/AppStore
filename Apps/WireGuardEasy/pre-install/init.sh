#!/bin/sh
# Initialize WireGuard Easy environment
# Arguments: $1 = password, $2 = app name for casaos path

PASSWORD="$1"
APP_NAME="$2"
WIREGUARD_DIR="/DATA/AppData/wgeasy/wireguard"
CASAOS_APP_DIR="/DATA/AppData/casaos/apps/${APP_NAME}"

# Generate bcrypt hash for v14
HASH=$(docker run --rm ghcr.io/wg-easy/wg-easy:14 wgpw "$PASSWORD" 2>/dev/null | grep '^\$')

if [ -z "$HASH" ]; then
    echo "Failed to generate password hash"
    exit 1
fi

# Escape $ as $$ for docker-compose
ESCAPED_HASH=$(echo "$HASH" | sed 's/\$/\$\$/g')

# Write to env file
echo "PASSWORD_HASH=${ESCAPED_HASH}" > "${WIREGUARD_DIR}/.env"

# Create symlink in casaos apps folder
mkdir -p "${CASAOS_APP_DIR}"
ln -sf "${WIREGUARD_DIR}/.env" "${CASAOS_APP_DIR}/.env"

echo "Password hash generated and linked successfully"
