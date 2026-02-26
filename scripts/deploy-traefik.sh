#!/usr/bin/env bash
# Deploy/update Traefik reverse proxy to VPS
# Usage: bash scripts/deploy-traefik.sh [--swap]
#   --swap: Switch from temp ports (8080/8443) to production (80/443)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -z "${VPS_HOST:-}" ]]; then
    echo "[ERROR] VPS_HOST env var is required"
    exit 1
fi

SERVER="root@${VPS_HOST}"
REMOTE_DIR="/opt/services/traefik"
COMPOSE_SRC="${SCRIPT_DIR}/../compose/traefik"

SWAP_MODE=false
if [[ "${1:-}" == "--swap" ]]; then
    SWAP_MODE=true
fi

echo "=== Deploy Traefik ==="

# Render traefik.yml with envsubst (requires ACME_EMAIL)
if [[ -z "${ACME_EMAIL:-}" ]]; then
    echo "[ERROR] ACME_EMAIL env var is required (Let's Encrypt contact email)"
    echo "  export ACME_EMAIL=you@example.com"
    exit 1
fi

RENDERED_TRAEFIK="$(mktemp)"
trap 'rm -f "${RENDERED_TRAEFIK}"' EXIT
envsubst '${ACME_EMAIL}' < "${COMPOSE_SRC}/traefik.yml" > "${RENDERED_TRAEFIK}"

# Upload config files
echo "[*] Uploading Traefik config..."
rsync -avz --delete \
    "${RENDERED_TRAEFIK}" \
    "${SERVER}:${REMOTE_DIR}/traefik.yml"

rsync -avz --delete \
    "${COMPOSE_SRC}/docker-compose.yml" \
    "${SERVER}:${REMOTE_DIR}/"

rsync -avz --delete \
    "${COMPOSE_SRC}/dynamic/" \
    "${SERVER}:${REMOTE_DIR}/dynamic/"

if $SWAP_MODE; then
    echo "[*] Switching to production ports (80/443)..."
    echo "[*] Stopping nginx..."
    ssh "$SERVER" "systemctl stop nginx && systemctl disable nginx || true"

    echo "[*] Updating Traefik ports..."
    ssh "$SERVER" "cd ${REMOTE_DIR} && \
        sed -i 's/8080:80/80:80/' docker-compose.yml && \
        sed -i 's/8443:443/443:443/' docker-compose.yml"

    echo "[*] Removing temp firewall rules..."
    ssh "$SERVER" "ufw delete allow 8080/tcp || true; ufw delete allow 8443/tcp || true"
fi

echo "[*] Starting Traefik..."
ssh "$SERVER" "cd ${REMOTE_DIR} && docker compose pull && docker compose up -d"

echo "[*] Checking health..."
sleep 3
ssh "$SERVER" "docker ps --filter name=traefik --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

if $SWAP_MODE; then
    echo ""
    echo "[OK] Traefik is now on production ports 80/443"
    echo "[!] Verify: curl -I https://syncapp.tech"
    echo "[!] Rollback: docker compose down && systemctl start nginx"
else
    echo ""
    echo "[OK] Traefik deployed on temp ports 8080/8443"
    echo "[!] Test: curl -k https://localhost:8443 --resolve syncapp.tech:8443:127.0.0.1"
    echo "[!] When ready: bash scripts/deploy-traefik.sh --swap"
fi
