#!/bin/bash
set -e

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
  ADMIN_EMAIL="admin@mastodon-${domain}"
  ADMIN_PASSWORD="${default_pwd}"

  docker exec mastodon-backend bundle exec bin/tootctl accounts create admin \
    --email "$ADMIN_EMAIL" \
    --confirmed \
    --role Owner || true

  docker exec mastodon-backend bundle exec bin/tootctl accounts modify admin \
    --email "$ADMIN_EMAIL" \
    --confirm || true

  echo ""
  echo "=== Admin Account Created ==="
  echo "Email: $ADMIN_EMAIL"
  echo "Password: $ADMIN_PASSWORD"
  echo "============================="
else
  echo "Admin user already exists, skipping creation."
fi

echo ""
echo "=== Installation Complete! ==="
echo "Your Mastodon instance: https://mastodon-${domain}"
echo ""
