#!/bin/bash
set -e

# Create directories
mkdir -p /DATA/AppData/casaos/apps/mastodon
mkdir -p /DATA/AppData/mastodon/postgres /DATA/AppData/mastodon/redis /DATA/AppData/mastodon/public/system
chown -R 1000:1000 /DATA/AppData/casaos/apps/mastodon
chown -R 1000:1000 /DATA/AppData/mastodon

# Generate .env if it doesn't exist or is empty
if [ ! -s /DATA/AppData/casaos/apps/mastodon/.env ]; then
  touch /DATA/AppData/casaos/apps/mastodon/.env
  chown 1000:1000 /DATA/AppData/casaos/apps/mastodon/.env

  echo "Generating Mastodon configuration..."

  # Generate secrets
  SECRET_KEY_BASE=$(docker run --rm ghcr.io/mastodon/mastodon:v4.4.4 bundle exec rake secret)
  OTP_SECRET=$(docker run --rm ghcr.io/mastodon/mastodon:v4.4.4 bundle exec rake secret)
  VAPID_OUTPUT=$(docker run --rm ghcr.io/mastodon/mastodon:v4.4.4 bundle exec rake mastodon:webpush:generate_vapid_key)
  VAPID_PRIVATE_KEY=$(echo "$VAPID_OUTPUT" | grep "VAPID_PRIVATE_KEY" | cut -d'=' -f2)
  VAPID_PUBLIC_KEY=$(echo "$VAPID_OUTPUT" | grep "VAPID_PUBLIC_KEY" | cut -d'=' -f2)
  ENCRYPTION_OUTPUT=$(docker run --rm ghcr.io/mastodon/mastodon:v4.4.4 bin/rails db:encryption:init)
  ENCRYPTION_DETERMINISTIC=$(echo "$ENCRYPTION_OUTPUT" | grep "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY" | cut -d'=' -f2)
  ENCRYPTION_SALT=$(echo "$ENCRYPTION_OUTPUT" | grep "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT" | cut -d'=' -f2)
  ENCRYPTION_PRIMARY=$(echo "$ENCRYPTION_OUTPUT" | grep "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY" | cut -d'=' -f2)

  # Write .env file
  cat > /DATA/AppData/casaos/apps/mastodon/.env << 'EOF'
LOCAL_DOMAIN=mastodon-${domain:-localhost}
WEB_DOMAIN=mastodon-${domain:-localhost}
SINGLE_USER_MODE=true
STREAMING_API_BASE_URL=https://mastodon-${domain:-localhost}
REDIS_HOST=redis
REDIS_PORT=6379
DB_HOST=db
DB_USER=mastodon
DB_NAME=mastodon_production
DB_PASS=mastodon_default_password_change_me
DB_PORT=5432
SECRET_KEY_BASE=${SECRET_KEY_BASE}
OTP_SECRET=${OTP_SECRET}
VAPID_PRIVATE_KEY=${VAPID_PRIVATE_KEY}
VAPID_PUBLIC_KEY=${VAPID_PUBLIC_KEY}
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=${ENCRYPTION_DETERMINISTIC}
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=${ENCRYPTION_SALT}
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=${ENCRYPTION_PRIMARY}
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_LEVEL=warn
PAPERCLIP_ROOT_PATH=/mastodon/public/system
PREPARED_STATEMENTS=true
MAX_TOOT_CHARS=500
TRUSTED_PROXY_IP=172.16.0.0/12
RAILS_FORCE_SSL=false
EOF

  chmod 600 /DATA/AppData/casaos/apps/mastodon/.env

  # Write nginx.conf
  cat > /DATA/AppData/mastodon/nginx.conf << 'NGINXEOF'
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

upstream backend {
    server mastodon-backend:3000 fail_timeout=0;
}

upstream streaming {
    server streaming:4000 fail_timeout=0;
}

server {
    listen 80;
    server_name _;

    keepalive_timeout 70;
    client_max_body_size 80M;

    root /dev/null;

    gzip on;
    gzip_disable "msie6";
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml image/x-icon;

    location / {
        try_files $uri @proxy;
    }

    location ~ ^/(system|packs) {
        add_header Cache-Control "public, max-age=2419200, immutable";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
        try_files $uri @proxy;
    }

    location ^~ /api/v1/streaming {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Proxy "";

        proxy_pass http://streaming;
        proxy_buffering off;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        tcp_nodelay on;
    }

    location @proxy {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header Proxy "";

        proxy_pass http://backend;
        proxy_buffering on;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        proxy_cache_bypass $http_upgrade;

        tcp_nodelay on;
    }

    error_page 500 501 502 503 504 /500.html;
}
NGINXEOF

  echo "Configuration generated successfully!"
else
  echo "Configuration already exists, skipping generation."
fi
