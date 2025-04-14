#!/bin/sh

# Exit on error
set -e

echo "Setting up Hysteria..."

# 1. Create required directories
mkdir -p /DATA/AppData/hysteria/config
mkdir -p /DATA/AppData/hysteria/acme

# 2. Create config file with password replacement
echo "Generating config file..."
cat > /DATA/AppData/hysteria/config/config.yaml << 'EOF'
listen: :443

# Using TLS with self-signed certificates
tls:
  cert: /acme/cert.pem
  key: /acme/key.pem
  sniGuard: disable

auth:
  type: password
  password: $PWD

# Maximum upload and download speeds per client
bandwidth:
  up: 50 mbps
  down: 100 mbps

# Logging level (debug, info, warn, error)
logging:
  level: info
EOF

# 3. Replace $PWD with actual environment variable
if [ -z "$PWD" ]; then
  echo "Warning: PWD environment variable is not set. Using default password."
  DEFAULT_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
  sed -i "s/\$PWD/$DEFAULT_PASSWORD/g" /DATA/AppData/hysteria/config/config.yaml
  echo "Generated password: $DEFAULT_PASSWORD"
else
  sed -i "s/\$PWD/$PWD/g" /DATA/AppData/hysteria/config/config.yaml
  echo "Password set from environment variable."
fi

# 4. Generate self-signed certificate
echo "Generating SSL certificates..."
# Remove any existing certificates first
rm -f /DATA/AppData/hysteria/acme/key.pem /DATA/AppData/hysteria/acme/cert.pem

openssl req -x509 -newkey rsa:4096 \
  -keyout /DATA/AppData/hysteria/acme/key.pem \
  -out /DATA/AppData/hysteria/acme/cert.pem \
  -days 365 -nodes \
  -subj "/CN=hysteria.internal" \
  2>/dev/null

# Set appropriate permissions
chmod 600 /DATA/AppData/hysteria/acme/key.pem
chmod 644 /DATA/AppData/hysteria/acme/cert.pem

echo "Setup complete!"
echo "Certificates regenerated in /DATA/AppData/hysteria/acme/"
echo "Configuration saved to /DATA/AppData/hysteria/config/config.yaml"