#!/bin/bash
set -e

echo "=== Mastodon Post-Install Script ==="
echo "Running idempotent initialization tasks..."

# Check required PCS environment variables
if [ -z "$PCS_DOMAIN" ]; then
  echo "Error: PCS_DOMAIN is not set"
  exit 1
fi

if [ -z "$PCS_EMAIL" ]; then
  echo "Error: PCS_EMAIL is not set"
  exit 1
fi

# Wait for database to be ready
echo "Waiting for database to be ready..."
until docker compose exec -T db pg_isready -U mastodon > /dev/null 2>&1; do
    echo "Database not ready, waiting..."
    sleep 2
done
echo "Database is ready!"

# Check if database is initialized
echo "Checking database initialization..."
DB_INITIALIZED=$(docker compose exec -T db psql -U mastodon -d mastodon_production -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null || echo "0")

if [ "$DB_INITIALIZED" -eq "0" ]; then
    echo "Database not initialized. Running schema load..."
    docker compose run --rm mastodon-backend bundle exec rails db:schema:load
    echo "Database schema loaded!"
else
    echo "Database already initialized (found $DB_INITIALIZED tables), skipping schema load."
fi

# Run migrations (idempotent - only runs pending migrations)
echo "Running database migrations..."
docker compose run --rm mastodon-backend bundle exec rails db:migrate
echo "Migrations complete!"

# Check if admin user exists (idempotent)
echo "Checking for admin user..."
ADMIN_EXISTS=$(docker compose exec -T mastodon-backend bin/tootctl accounts list --limit 1 | grep -c "admin" || echo "0")

if [ "$ADMIN_EXISTS" -eq "0" ]; then
    echo "Creating admin user..."
    ADMIN_PASSWORD=$(docker compose exec -T mastodon-backend bin/tootctl accounts create admin --email $PCS_EMAIL --confirmed | grep "New password:" | awk '{print $3}')
    docker compose exec -T mastodon-backend bin/tootctl accounts modify admin --approve
    echo ""
    echo "=== Admin User Created! ==="
    echo "Email: $PCS_EMAIL"
    echo "Password: $ADMIN_PASSWORD"
    echo ""
else
    echo "Admin user already exists, skipping creation."
fi

echo ""
echo "=== Post-Install Complete! ==="
echo "Your Mastodon instance should be accessible at: https://mastodon-${PCS_DOMAIN}"
echo ""
