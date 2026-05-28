#!/bin/sh
# Exit on error
set -e
echo "Setting up Docmost MCP..."

# Ensure the data directory exists
mkdir -p /data

# Seed a template config.json on first install. Leaves email/password blank —
# the user fills them in via File Browser before the MCP can authenticate to
# Docmost.
if [ ! -f /data/config.json ]; then
    echo "Config file not found. Generating template..."
    cat > /data/config.json << 'EOF'
{
  "base_url": "http://docmost",
  "email": "",
  "password": "",
  "timeout": 30,
  "page_content_format": "markdown",
  "create_space_conflict_policy": "return_existing",
  "duplicate_page_conflict_policy": "auto_suffix",
  "clear_parent_on_space_move": true
}
EOF
    echo "Template config.json written to /DATA/AppData/docmostmcp/config.json"
    echo "Edit it with your Docmost credentials before first use."
else
    echo "Existing config.json detected — leaving it in place."
fi

# Pre-create the JWT cache file so the upstream symlink target exists.
# The MCP image's entrypoint also does this, but doing it here is harmless.
touch /data/token.json

echo "Docmost MCP setup complete."
