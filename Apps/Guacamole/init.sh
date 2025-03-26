#!/bin/bash
# Script to initialize PostgreSQL for Guacamole

# Start PostgreSQL service
docker-entrypoint.sh postgres &

# Wait for PostgreSQL to start
until PGPASSWORD=some_password psql -h localhost -U guacamole_user -d guacamole_db -c 'SELECT 1' &>/dev/null; do
  echo 'Waiting for PostgreSQL to start...'
  sleep 2
done

# Check if database is already initialized
if ! PGPASSWORD=some_password psql -h localhost -U guacamole_user -d guacamole_db -c 'SELECT 1 FROM guacamole_connection_group LIMIT 1' &>/dev/null; then
  echo 'Database not initialized. Running initialization scripts...'
  # Create init directory if it doesn't exist
  mkdir -p /init

  # Download initialization scripts
  apt-get update && apt-get install -y curl
  curl -o /init/initdb.sql https://raw.githubusercontent.com/apache/guacamole-client/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/upgrade/upgrade-pre-0.9.14.sql
  curl -o /init/001_create_schema.sql https://raw.githubusercontent.com/apache/guacamole-client/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/001-create-schema.sql
  curl -o /init/002_create_admin_user.sql https://raw.githubusercontent.com/apache/guacamole-client/master/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/002-create-admin-user.sql

  # Run initialization scripts
  PGPASSWORD=some_password psql -h localhost -U guacamole_user -d guacamole_db -f /init/001_create_schema.sql
  PGPASSWORD=some_password psql -h localhost -U guacamole_user -d guacamole_db -f /init/002_create_admin_user.sql
  echo 'Database initialization complete'
else
  echo 'Database already initialized. Skipping initialization.'
fi

# Keep container running
wait