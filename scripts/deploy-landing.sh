#!/usr/bin/env bash
# Build and deploy landing page (syncapp.tech)
# Requires the interview repo to be cloned as a sibling directory.
# Usage: bash scripts/deploy-landing.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -z "${VPS_HOST:-}" ]]; then
    echo "[ERROR] VPS_HOST env var is required"
    exit 1
fi

SERVER="root@${VPS_HOST}"
REMOTE_DIR="/opt/services/landing"
COMPOSE_SRC="${SCRIPT_DIR}/../compose/landing"

# Landing uses a separate frontend build — adjust this path if needed
FRONTEND_DIR="${REPO_ROOT}/../interview/frontend"

echo "=== Deploy Landing Page ==="

if [ ! -d "${FRONTEND_DIR}" ]; then
    echo "[ERROR] Frontend directory not found: ${FRONTEND_DIR}"
    echo "[!] Clone the interview repo as a sibling directory"
    exit 1
fi

# Build frontend
echo "[*] Building Astro site..."
cd "${FRONTEND_DIR}"
pnpm install --frozen-lockfile
pnpm build
cd "${REPO_ROOT}"

if [ ! -d "${FRONTEND_DIR}/dist" ]; then
    echo "[ERROR] Build failed: dist/ not found"
    exit 1
fi

# Upload compose file + nginx config
echo "[*] Uploading compose config..."
rsync -avz \
    "${COMPOSE_SRC}/docker-compose.yml" \
    "${SERVER}:${REMOTE_DIR}/"

# Landing uses volume-mounted nginx.conf — upload it from compose dir
if [ -f "${COMPOSE_SRC}/nginx.conf" ]; then
    rsync -avz \
        "${COMPOSE_SRC}/nginx.conf" \
        "${SERVER}:${REMOTE_DIR}/nginx.conf"
fi

# Upload built site
echo "[*] Uploading static files..."
rsync -avz --delete \
    "${FRONTEND_DIR}/dist/" \
    "${SERVER}:${REMOTE_DIR}/dist/"

# Restart container
echo "[*] Restarting landing container..."
ssh "$SERVER" "cd ${REMOTE_DIR} && docker compose up -d"

echo ""
echo "[OK] Landing page deployed"
echo "[!] Verify: curl -I https://syncapp.tech"
