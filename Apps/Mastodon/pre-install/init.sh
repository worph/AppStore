#!/bin/bash
# Mastodon pre-install script - Generates required secrets and configuration
set -e

echo "Initializing Mastodon configuration..."

# Create config directory if it doesn't exist
mkdir -p /DATA/AppData/mastodon

# Check if .env.production already exists
if [ -f /DATA/AppData/mastodon/.env.production ]; then
    echo ".env.production already exists. Skipping generation."
    exit 0
fi

echo "Generating Mastodon secrets..."

# Generate SECRET_KEY_BASE
echo "Generating SECRET_KEY_BASE..."
SECRET_KEY_BASE=$(docker run --rm ghcr.io/mastodon/mastodon:v4.4.4 bundle exec rake secret)

# Generate OTP_SECRET
echo "Generating OTP_SECRET..."
OTP_SECRET=$(docker run --rm ghcr.io/mastodon/mastodon:v4.4.4 bundle exec rake secret)

# Generate VAPID keys
echo "Generating VAPID keys..."
VAPID_OUTPUT=$(docker run --rm ghcr.io/mastodon/mastodon:v4.4.4 bundle exec rake mastodon:webpush:generate_vapid_key)
VAPID_PRIVATE_KEY=$(echo "$VAPID_OUTPUT" | grep "VAPID_PRIVATE_KEY" | cut -d'=' -f2)
VAPID_PUBLIC_KEY=$(echo "$VAPID_OUTPUT" | grep "VAPID_PUBLIC_KEY" | cut -d'=' -f2)

# Get domain from environment or use default
DOMAIN=${domain:-"localhost"}

# Get email from environment or use default
EMAIL=${email:-"admin@${DOMAIN}"}

# Get default password from environment or generate one
if [ -z "$default_pwd" ]; then
    DB_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    echo "Generated database password: $DB_PASSWORD"
else
    DB_PASSWORD="$default_pwd"
fi

# Store email for post-install use
echo "$EMAIL" > /DATA/AppData/mastodon/.admin_email

# Create secrets file (only contains SECRET_KEY_BASE, OTP_SECRET, and VAPID keys)
cat > /DATA/AppData/mastodon/.secrets.env << EOF
export SECRET_KEY_BASE="${SECRET_KEY_BASE}"
export OTP_SECRET="${OTP_SECRET}"
export VAPID_PRIVATE_KEY="${VAPID_PRIVATE_KEY}"
export VAPID_PUBLIC_KEY="${VAPID_PUBLIC_KEY}"
EOF

# Set appropriate permissions
chmod 600 /DATA/AppData/mastodon/.secrets.env

# Also create a backup configuration file for reference
cat > /DATA/AppData/mastodon/config-reference.txt << EOF
# Mastodon Configuration Reference
# Generated on $(date)

Domain: mastodon-${DOMAIN}
Admin Email: ${EMAIL}
Database Password: ${DB_PASSWORD}

Secrets (stored in .secrets.env):
- SECRET_KEY_BASE
- OTP_SECRET
- VAPID_PRIVATE_KEY
- VAPID_PUBLIC_KEY

Optional Email Configuration:
To enable email notifications, you can add these to the container environment:
  SMTP_SERVER=smtp.example.com
  SMTP_PORT=587
  SMTP_LOGIN=notifications@mastodon-${DOMAIN}
  SMTP_PASSWORD=your_smtp_password
  SMTP_FROM_ADDRESS=notifications@mastodon-${DOMAIN}
EOF

chmod 644 /DATA/AppData/mastodon/config-reference.txt

echo "Configuration file created at /DATA/AppData/mastodon/.secrets.env"
echo "Secrets have been generated successfully!"
echo ""
echo "IMPORTANT: Save these credentials securely!"
echo "Database Password: ${DB_PASSWORD}"
echo "Admin Email: ${EMAIL}"
echo ""
echo "Mastodon configuration complete!"
