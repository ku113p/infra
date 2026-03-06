#!/bin/bash
# Fix workspace ownership to match PUID/PGID on every start
chown "${PUID:-1000}:${PGID:-1000}" /workspace

# Always apply VS Code settings from defaults
SETTINGS_DIR="/config/data/User"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"
mkdir -p "${SETTINGS_DIR}"
cp /defaults/settings.json "${SETTINGS_FILE}"
chown "${PUID:-1000}:${PGID:-1000}" "${SETTINGS_DIR}" "${SETTINGS_FILE}"
