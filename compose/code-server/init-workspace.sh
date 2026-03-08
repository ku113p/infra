#!/bin/bash
# Fix workspace ownership to match PUID/PGID on every start
chown "${PUID:-1000}:${PGID:-1000}" /workspace

# Install uv (Python manager) if not present
UV_BIN="/config/.local/bin/uv"
if [ ! -f "$UV_BIN" ]; then
    s6-setuidgid "${PUID:-1000}:${PGID:-1000}" \
        sh -c 'curl -LsSf https://astral.sh/uv/install.sh | XDG_BIN_HOME=/config/.local/bin sh'
fi

# Install Node.js via fnm if not present
FNM_DIR="/config/.local/share/fnm"
if [ ! -d "$FNM_DIR" ]; then
    s6-setuidgid "${PUID:-1000}:${PGID:-1000}" \
        sh -c 'curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir /config/.local/share/fnm --skip-shell'
    export PATH="$FNM_DIR:$PATH"
    eval "$(${FNM_DIR}/fnm env --shell bash)"
    s6-setuidgid "${PUID:-1000}:${PGID:-1000}" \
        sh -c "export PATH=$FNM_DIR:\$PATH && eval \"\$($FNM_DIR/fnm env --shell bash)\" && fnm install --lts"
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
