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

# Create .env.production file
cat > /DATA/AppData/mastodon/.env.production << EOF
# Mastodon Configuration
# Generated on $(date)

# Federation
LOCAL_DOMAIN=mastodon-${DOMAIN}
SINGLE_USER_MODE=true
WEB_DOMAIN=mastodon-${DOMAIN}

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# PostgreSQL
DB_HOST=db
DB_USER=mastodon
DB_NAME=mastodon_production
DB_PASS=${DB_PASSWORD}
DB_PORT=5432

# Secrets - DO NOT SHARE THESE
SECRET_KEY_BASE=${SECRET_KEY_BASE}
OTP_SECRET=${OTP_SECRET}

# VAPID keys for Web Push
VAPID_PRIVATE_KEY=${VAPID_PRIVATE_KEY}
VAPID_PUBLIC_KEY=${VAPID_PUBLIC_KEY}

# File storage
PAPERCLIP_ROOT_PATH=/mastodon/public/system

# Optional: Email configuration (uncomment and configure if needed)
# SMTP_SERVER=smtp.example.com
# SMTP_PORT=587
# SMTP_LOGIN=notifications@mastodon-${DOMAIN}
# SMTP_PASSWORD=your_smtp_password
# SMTP_FROM_ADDRESS=notifications@mastodon-${DOMAIN}
# SMTP_AUTH_METHOD=plain
# SMTP_OPENSSL_VERIFY_MODE=none

# Optional: S3/Object Storage (uncomment if using)
# S3_ENABLED=true
# S3_BUCKET=mastodon
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# S3_REGION=us-east-1
# S3_PROTOCOL=https
# S3_HOSTNAME=s3.us-east-1.amazonaws.com

# Streaming API configuration
STREAMING_API_BASE_URL=https://mastodon-${DOMAIN}

# Advanced settings
MAX_TOOT_CHARS=500
PREPARED_STATEMENTS=true
EOF

# Set appropriate permissions
chmod 600 /DATA/AppData/mastodon/.env.production

echo "Configuration file created at /DATA/AppData/mastodon/.env.production"
echo "Secrets have been generated successfully!"
echo ""
echo "IMPORTANT: Save these credentials securely!"
echo "Database Password: ${DB_PASSWORD}"
echo "Admin Email: ${EMAIL}"
echo ""
echo "Mastodon configuration complete!"
