#!/bin/bash
# Fix workspace ownership to match PUID/PGID on every start
chown "${PUID:-1000}:${PGID:-1000}" /workspace

# Install uv (Python manager) if not present
UV_BIN="/config/.local/bin/uv"
if [ ! -f "$UV_BIN" ]; then
    s6-setuidgid "${PUID:-1000}:${PGID:-1000}" \
        sh -c 'curl -LsSf https://astral.sh/uv/install.sh | XDG_BIN_HOME=/config/.local/bin sh'
fi

# Install Node.js LTS if not present
NODE_BIN="/config/.local/bin/node"
if [ ! -f "$NODE_BIN" ]; then
    NODE_VERSION="22.14.0"
    s6-setuidgid "${PUID:-1000}:${PGID:-1000}" \
        sh -c "curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz | tar -xz --strip-components=1 -C /config/.local/"
fi

# Always apply VS Code settings from defaults
SETTINGS_DIR="/config/data/User"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"
mkdir -p "${SETTINGS_DIR}"
cp /defaults/settings.json "${SETTINGS_FILE}"
chown "${PUID:-1000}:${PGID:-1000}" "${SETTINGS_DIR}" "${SETTINGS_FILE}"

# Strip all Copilot/Chat AI properties from product.json
PRODUCT_JSON="/app/code-server/lib/vscode/product.json"
if [ -f "$PRODUCT_JSON" ]; then
    jq '
      del(.defaultChatAgent) | del(.chatWelcomeView) | del(.chatParticipantAdditions)
      | if .extensionEnabledApiProposals then
          .extensionEnabledApiProposals |= with_entries(select(.key | test("copilot"; "i") | not))
        else . end
      | if .builtInExtensions then
          .builtInExtensions |= map(select(.name | test("copilot"; "i") | not))
        else . end
    ' "$PRODUCT_JSON" > /tmp/product.json.tmp \
        && mv /tmp/product.json.tmp "$PRODUCT_JSON"
fi

# Disable built-in Copilot/Chat extensions
EXTENSIONS_DIR="/app/code-server/lib/vscode/extensions"
for ext_dir in "$EXTENSIONS_DIR"/github.copilot* "$EXTENSIONS_DIR"/copilot*; do
    if [ -d "$ext_dir" ] && [[ "$ext_dir" != *.disabled ]]; then
        mv "$ext_dir" "${ext_dir}.disabled"
    fi
done

# Remove user-installed Copilot extensions
USER_EXT_DIR="/config/extensions"
for ext_dir in "$USER_EXT_DIR"/github.copilot* "$USER_EXT_DIR"/copilot*; do
    if [ -d "$ext_dir" ]; then
        rm -rf "$ext_dir"
    fi
done
