#!/usr/bin/env bash
# setup-tools-secrets.sh — Generate auth tokens for tools services on VPS
# Usage: ssh root@VPS 'bash -s' < scripts/setup-tools-secrets.sh
set -euo pipefail

SERVICES_DIR="/opt/services"

# Generate a shared AUTH_TOKEN for short-links, landing-pages, message
AUTH_TOKEN=$(openssl rand -hex 32)

# Generate MCP_AUTH_TOKEN for Claude Code → MCP server
MCP_AUTH_TOKEN=$(openssl rand -hex 32)

echo "=== Generating auth tokens for tools services ==="

# Ensure directories exist
for svc in short-links landing-pages message tools-mcp cryo-pay; do
    mkdir -p "${SERVICES_DIR}/${svc}"
done

# Write AUTH_TOKEN to backend services
for svc in short-links landing-pages message; do
    ENV_FILE="${SERVICES_DIR}/${svc}/.env"
    # Remove old AUTH_TOKEN/CONTACT_TOKEN lines if present
    if [ -f "$ENV_FILE" ]; then
        sed -i '/^AUTH_TOKEN=/d' "$ENV_FILE"
        sed -i '/^CONTACT_TOKEN=/d' "$ENV_FILE"
    fi
    echo "AUTH_TOKEN=${AUTH_TOKEN}" >> "$ENV_FILE"
    echo "  [OK] ${svc}/.env updated with AUTH_TOKEN"
done

# Generate REDIS_PASSWORD for each Redis-backed service
for svc in short-links landing-pages cryo-pay; do
    ENV_FILE="${SERVICES_DIR}/${svc}/.env"
    # Skip if REDIS_PASSWORD already set
    if grep -q '^REDIS_PASSWORD=' "$ENV_FILE" 2>/dev/null; then
        echo "  [SKIP] ${svc}/.env already has REDIS_PASSWORD"
        continue
    fi
    REDIS_PW=$(openssl rand -hex 32)
    # Remove ALLOW_EMPTY_PASSWORD if present
    if [ -f "$ENV_FILE" ]; then
        sed -i '/^ALLOW_EMPTY_PASSWORD=/d' "$ENV_FILE"
    fi
    echo "REDIS_PASSWORD=${REDIS_PW}" >> "$ENV_FILE"
    echo "  [OK] ${svc}/.env updated with REDIS_PASSWORD"
done

# Write MCP server .env
MCP_ENV="${SERVICES_DIR}/tools-mcp/.env"
cat > "$MCP_ENV" <<EOF
MCP_AUTH_TOKEN=${MCP_AUTH_TOKEN}
SHORT_LINKS_URL=https://links.tools.syncapp.tech
SHORT_LINKS_TOKEN=${AUTH_TOKEN}
LANDING_PAGES_URL=https://pages.tools.syncapp.tech
LANDING_PAGES_TOKEN=${AUTH_TOKEN}
MESSAGE_URL=https://msg.tools.syncapp.tech
MESSAGE_TOKEN=${AUTH_TOKEN}
EOF
echo "  [OK] tools-mcp/.env created"

echo ""
echo "=== Done ==="
echo ""
echo "AUTH_TOKEN (shared across services): ${AUTH_TOKEN}"
echo ""
echo "MCP_AUTH_TOKEN (for .mcp.json):      ${MCP_AUTH_TOKEN}"
echo ""
echo "Add to your .mcp.json:"
echo '{'
echo '  "mcpServers": {'
echo '    "tools": {'
echo '      "type": "streamable-http",'
echo "      \"url\": \"https://mcp.tools.syncapp.tech/mcp\","
echo '      "headers": {'
echo "        \"Authorization\": \"Bearer ${MCP_AUTH_TOKEN}\""
echo '      }'
echo '    }'
echo '  }'
echo '}'
echo ""
echo "Now restart all 4 services:"
echo "  cd ${SERVICES_DIR}/short-links && docker compose up -d"
echo "  cd ${SERVICES_DIR}/landing-pages && docker compose up -d"
echo "  cd ${SERVICES_DIR}/message && docker compose up -d"
echo "  cd ${SERVICES_DIR}/tools-mcp && docker compose up -d"
