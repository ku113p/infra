#!/usr/bin/env bash
# Shared functions for deploy scripts
# Usage: source "$(dirname "$0")/lib.sh"

set -euo pipefail

require_env() {
    local var_name="$1"
    local hint="${2:-}"
    if [[ -z "${!var_name:-}" ]]; then
        echo "[ERROR] ${var_name} env var is required"
        [[ -n "$hint" ]] && echo "  ${hint}"
        exit 1
    fi
}

init_server() {
    require_env "VPS_HOST"
    SERVER="root@${VPS_HOST}"
    export SERVER
}

render_template() {
    local input="$1"
    local vars="$2"
    envsubst "${vars}" < "${input}"
}

verify_containers() {
    local filter="$1"
    local expected="${2:-1}"
    echo "[*] Verifying containers (filter: ${filter})..."
    local running
    running=$(ssh "${SERVER}" "docker ps --filter 'name=${filter}' --format '{{.Names}}' | grep -c '.' || true")
    if [[ "${running}" -ge "${expected}" ]]; then
        echo "[OK] ${running}/${expected} containers running"
        ssh "${SERVER}" "docker ps --filter 'name=${filter}' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
        return 0
    else
        echo "[FAIL] Only ${running}/${expected} containers running"
        ssh "${SERVER}" "docker ps -a --filter 'name=${filter}' --format 'table {{.Names}}\t{{.Status}}'"
        return 1
    fi
}
