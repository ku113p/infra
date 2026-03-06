#!/bin/bash
# Fix workspace ownership to match PUID/PGID on every start
chown "${PUID:-1000}:${PGID:-1000}" /workspace

# Always apply VS Code settings from defaults
SETTINGS_DIR="/config/data/User"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"
mkdir -p "${SETTINGS_DIR}"
cp /defaults/settings.json "${SETTINGS_FILE}"
chown "${PUID:-1000}:${PGID:-1000}" "${SETTINGS_DIR}" "${SETTINGS_FILE}"

# Remove defaultChatAgent from product.json to disable Copilot/Chat UI at product level
# (prevents Command Palette "Use AI features" from re-enabling via settings override)
PRODUCT_JSON="/app/code-server/lib/vscode/product.json"
if [ -f "$PRODUCT_JSON" ] && jq -e '.defaultChatAgent' "$PRODUCT_JSON" > /dev/null 2>&1; then
    jq 'del(.defaultChatAgent)' "$PRODUCT_JSON" > /tmp/product.json.tmp \
        && mv /tmp/product.json.tmp "$PRODUCT_JSON"
fi
