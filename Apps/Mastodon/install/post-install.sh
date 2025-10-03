#!/bin/bash
set -e

# Check required PCS environment variables
if [ -z "$PCS_DOMAIN" ]; then
  echo "Error: PCS_DOMAIN is not set"
  exit 1
fi

if [ -z "$PCS_DEFAULT_PASSWORD" ]; then
  echo "Error: PCS_DEFAULT_PASSWORD is not set"
  exit 1
fi

if [ -z "$PCS_EMAIL" ]; then
  echo "Error: PCS_EMAIL is not set"
  exit 1
fi

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
