# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Infrastructure-as-code repository managing Docker Compose stacks, deployment scripts, and CI/CD for multiple projects. Deployed to a single VPS with Traefik as the reverse proxy. All web services run under `syncapp.tech` domain.

## Architecture

```
┌─────────────────────┐     ┌──────────────────────┐
│  interview repo     │     │  infra repo (this)    │
│  push → build images│     │  push → sync configs  │
│  → push to GHCR     │     │  → restart services   │
└────────┬────────────┘     └────────┬─────────────┘
         │                           │
         v                           v
   GHCR registry              GitHub Actions
         │                    (rsync + SSH)
         v                           │
   Watchtower (auto-pull)            │
         │                           v
         └──────────┬───────────────┘
                    v
              VPS (/opt/services/)
              ┌─────────────────┐
              │    Traefik      │ ← TLS termination, host routing
              │   (port 80/443) │
              └───────┬─────────┘
                      │ proxy network
         ┌──────┼────────────┼────────────┬──────────────┐
         v      v            v            v              v
      landing  interview    monitoring   watchtower   price-alert-bot
      (React   ┌──────────┐ (uptime-kuma (image       (Telegram bot +
       SPA)    │ promo    │  + dozzle)    updater)     Postgres +
               │ backend  │                            PgBouncer)
               │ mcp      │                            price-alert-bot-
               └──────────┘                            internal network
                 interview-internal network
```

**Compose stacks** live in `compose/<service>/docker-compose.yml`. Each maps to `/opt/services/<service>/` on the VPS.

**Landing** stack (`syncapp.tech`, `www.syncapp.tech`):
- **landing** — React/Vite SPA personal brand page, built from Dockerfile (multi-stage: node build → nginx serve). Personal info injected via `VITE_*` build args from `.env` on VPS.

**Key services** in the interview stack:
- **promo** — landing page (HTTP healthcheck)
- **backend** — API server, 1 CPU / 1GB RAM limit (process healthcheck on `main.py`)
- **mcp** — MCP server, 0.5 CPU / 512MB RAM limit (process healthcheck on `mcp_server.py`)
- backend and mcp share a `backend-data` volume and read from `.env` on the VPS

**Key services** in the price-alert-bot stack:
- **app** — Telegram bot for crypto price alerts (CoinMarketCap API), 0.5 CPU / 256MB RAM limit (process healthcheck on `server`)
- **db** — PostgreSQL 17.4 with PgBouncer connection pooling
- Reads from `.env` on the VPS (`TG_API_TOKEN`, `CMC_API_KEY`, `DATABASE_URL`, `UPDATE_INTERVAL_MS`)

**Networking**: Web-facing stacks join the external `proxy` network for Traefik discovery. Interview services also have an `interview-internal` network. Price-alert-bot uses its own `price-alert-bot-internal` network (no web traffic, Telegram polling only).

## Deployment

Fully automated via per-stack GitHub Actions workflows on push to `master` (`.github/workflows/deploy-<stack>.yml`). Each workflow triggers only when its `compose/<stack>/` directory changes:
1. Syncs compose files to VPS via rsync
2. Renders templates where needed (traefik.yml with `ACME_EMAIL`)
3. Runs `docker compose up -d` via SSH
4. Verifies containers are healthy

**Required GitHub secrets**: `VPS_HOST`, `VPS_SSH_KEY` (ed25519), `ACME_EMAIL`, `DOZZLE_PASSWORD_HASH`, `LANDING_NAME`, `LANDING_TITLE`, `LANDING_BIO`, `LANDING_EMAIL`, `LANDING_TELEGRAM`, `LANDING_LINKEDIN`

Scripts in `scripts/`:
- `setup-vps.sh` — one-time VPS provisioning (Docker, firewall, directory structure, log rotation)

A `Makefile` provides shortcuts for common operations (`make help`).

## Conventions

- **Commit messages**: conventional commits (`fix:`, `feat:`, `chore:`)
- **Watchtower opt-in**: services use `com.centurylinklabs.watchtower.enable=true` label
- **Traefik labels**: services declare their own routing rules via Docker labels (host rules, entrypoints, middleware)
- **Healthchecks**: HTTP-based for web servers, process-based (`pgrep`) for backend services without HTTP health endpoints
- **Templating**: `traefik.yml` uses envsubst (`${ACME_EMAIL}`); all other config is static. Dozzle users.yml is seeded on first deploy via `DOZZLE_PASSWORD_HASH` secret

## Project Rules

### Git Commits
- Do not add Co-Authored-By lines to commit messages

### Pull Requests
- Do not add Claude as co-author or mention Claude in PR descriptions
