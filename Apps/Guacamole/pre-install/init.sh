#!/bin/bash
# Script to initialize PostgreSQL for Guacamole

echo "Starting PostgreSQL initialization..."

# Start PostgreSQL in background
docker-entrypoint.sh postgres &
PG_PID=$!

# Wait for PostgreSQL to be ready
until PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c 'SELECT 1' &>/dev/null; do
  echo 'Waiting for PostgreSQL to start...'
  sleep 2
done

# Check if database is already initialized
if ! PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c 'SELECT 1 FROM guacamole_connection_group LIMIT 1' &>/dev/null; then
  echo 'Database not initialized. Running initialization scripts...'
  
  # Run schema initialization script
  if [ -f /init/001-create-schema.sql ]; then
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /init/001-create-schema.sql
  else
    echo 'Warning: Schema file not found, downloading...'
    wget -O /init/001-create-schema.sql "https://raw.githubusercontent.com/apache/guacamole-client/main/extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/schema/001-create-schema.sql"
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /init/001-create-schema.sql
  fi
  
  # Create admin user with CasaOS default password instead of using the default guacadmin/guacadmin
  echo 'Creating admin user with default CasaOS password...'
  
  # Generate password hash for the default password
  # Using a simple approach that Guacamole can handle
  DEFAULT_PWD="${POSTGRES_PASSWORD:-casaos}"
  
  # Create custom admin user with the default password
  PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" << EOF
-- Create admin user entity
INSERT INTO guacamole_entity (name, type) VALUES ('admin', 'USER');

-- Get the entity ID for the admin user
INSERT INTO guacamole_user (entity_id, password_hash, password_salt, password_date)
SELECT entity_id, 
       encode(digest('$DEFAULT_PWD' || chr(0) || 'FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264', 'sha256'), 'hex'),
       encode('FE24ADC5E11E2B25288D1704ABE67A79E342ECC26064CE69C5B3177795A82264', 'hex'),
       CURRENT_TIMESTAMP
FROM guacamole_entity WHERE name = 'admin' AND type = 'USER';

-- Grant admin permissions
INSERT INTO guacamole_user_permission (entity_id, affected_user_id, permission)
SELECT entity_id, entity_id, permission::guacamole_object_permission
FROM guacamole_entity, (VALUES ('UPDATE')) AS perms(permission)
WHERE name = 'admin' AND type = 'USER';

-- Grant system permissions
INSERT INTO guacamole_system_permission (entity_id, permission)
SELECT entity_id, permission::guacamole_system_permission
FROM guacamole_entity, (VALUES ('CREATE_CONNECTION'), ('CREATE_CONNECTION_GROUP'), ('CREATE_SHARING_PROFILE'), ('CREATE_USER'), ('CREATE_USER_GROUP'), ('ADMINISTER')) AS perms(permission)
WHERE name = 'admin' AND type = 'USER';
EOF

  echo 'Admin user created with username: admin and your CasaOS default password'
  
  echo 'Database initialization complete'
else
  echo 'Database already initialized. Skipping initialization.'
fi

# Set up trap for clean shutdown
trap 'kill -TERM $PG_PID; exit 0' TERM INT

# Wait for PostgreSQL process
echo "PostgreSQL ready with PID $PG_PID"
wait $PG_PID