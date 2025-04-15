#!/bin/sh
# Exit on error
set -e
echo "Setting up Hysteria..."

# 1. Create required directories if they don't exist
mkdir -p /data/config
mkdir -p /data/acme

# 2. Create config file only if it doesn't exist
if [ ! -f /data/config/config.yaml ]; then
    echo "Config file not found. Generating config file..."
    cat > /data/config/config.yaml << 'EOF'
listen: :443
# Using TLS with self-signed certificates
tls:
  cert: /acme/cert.pem
  key: /acme/key.pem
  sniGuard: disable
auth:
  type: password
  password: $PASSWORD
# Maximum upload and download speeds per client
bandwidth:
  up: 50 mbps
  down: 100 mbps
# Logging level (debug, info, warn, error)
logging:
  level: info
EOF

    # 3. Replace $PASSWORD with actual environment variable
    if [ -z "$PASSWORD" ]; then
        echo "Warning: PASSWORD environment variable is not set. Using default password."
        DEFAULT_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
        sed -i "s|\$PASSWORD|$DEFAULT_PASSWORD|g" /data/config/config.yaml
        echo "Generated password: $DEFAULT_PASSWORD"
    else
        sed -i "s|\$PASSWORD|$PASSWORD|g" /data/config/config.yaml
        echo "Password set from environment variable."
    fi
    echo "Configuration saved to /data/config/config.yaml"
else
    echo "Config file already exists. Skipping config generation."
fi

# 4. Generate self-signed certificate only if they don't exist
if [ ! -f /data/acme/cert.pem ] || [ ! -f /data/acme/key.pem ]; then
    echo "SSL certificates not found. Generating new certificates..."
    openssl req -x509 -newkey rsa:4096 \
      -keyout /data/acme/key.pem \
      -out /data/acme/cert.pem \
      -days 365 -nodes \
      -subj "/CN=hysteria.internal"

    # Set appropriate permissions
    chmod 600 /data/acme/key.pem
    chmod 644 /data/acme/cert.pem
    echo "Certificates generated in /data/acme/"
else
    echo "SSL certificates already exist. Skipping certificate generation."
fi

echo "Setup complete!"