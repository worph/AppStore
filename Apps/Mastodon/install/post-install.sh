#!/bin/bash
set -e

# Use PCS environment variables with fallbacks
PCS_DOMAIN="${PCS_DOMAIN:-localhost}"
PCS_DEFAULT_PASSWORD="${PCS_DEFAULT_PASSWORD:-changeme}"
PCS_EMAIL="${PCS_EMAIL:-admin@${PCS_DOMAIN}}"

echo "Waiting for database to be ready..."
sleep 10

# Check if database is initialized
DB_INITIALIZED=$(docker exec mastodon-backend bundle exec rails runner "puts ActiveRecord::Base.connection.table_exists?('users')" 2>/dev/null || echo "false")

if [ "$DB_INITIALIZED" != "true" ]; then
  echo "Initializing database..."
  docker exec mastodon-backend bundle exec rails db:migrate
  docker exec mastodon-backend bundle exec rails db:seed
fi

# Check if admin user exists
ADMIN_EXISTS=$(docker exec mastodon-backend bundle exec rails runner "puts User.where(admin: true).exists?" 2>/dev/null || echo "false")

if [ "$ADMIN_EXISTS" != "true" ]; then
  echo "Creating admin user..."

  docker exec mastodon-backend bundle exec bin/tootctl accounts create admin \
    --email "$PCS_EMAIL" \
    --confirmed \
    --role Owner || true

  docker exec mastodon-backend bundle exec bin/tootctl accounts modify admin \
    --email "$PCS_EMAIL" \
    --confirm || true

  echo ""
  echo "=== Admin Account Created ==="
  echo "Email: $PCS_EMAIL"
  echo "Password: $PCS_DEFAULT_PASSWORD"
  echo "============================="
else
  echo "Admin user already exists, skipping creation."
fi

echo ""
echo "=== Installation Complete! ==="
echo "Your Mastodon instance: https://mastodon-${PCS_DOMAIN}"
echo ""
