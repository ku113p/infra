# Infra — Operations Guide

Infrastructure for multiple projects: compose files, deploy scripts, and ops tooling. Deployed to a single VPS with Traefik as the reverse proxy.

## Architecture

```
app repos                           infra repo
  git push master                     git push master
       |                                   |
       v                                   v
  GitHub Actions                      GitHub Actions
  (build Docker images)              (sync compose files to VPS)
       |                                   |
       v                                   v
  GHCR (image registry)            rsync + docker compose up
       |                                   |
       v                                   v
  Watchtower (polls GHCR)                Live
       |
       v
      Live
```

Both repos auto-deploy on push to master. No manual SSH needed.

## Services

| Stack | Service | Image | URL |
|-------|---------|-------|-----|
| landing | landing | built from Dockerfile | https://syncapp.tech |
| short-links | app + redis | `ghcr.io/ku113p/short-links` | https://links.tools.syncapp.tech |
| landing-pages | app + redis | `ghcr.io/ku113p/landing-pages` | https://pages.tools.syncapp.tech |
| message | app + postgres | `ghcr.io/ku113p/message` | https://msg.tools.syncapp.tech |
| tools-mcp | app | `ghcr.io/ku113p/tools-mcp` | https://mcp.tools.syncapp.tech |
| cryo-pay | api + web + nginx + postgres + redis | `ghcr.io/digitalscyther/cryo-pay-*` | https://pay.syncapp.tech |
| interview | promo + backend + mcp | `ghcr.io/ku113p/interview-*` | https://*.interview.syncapp.tech |
| price-alert-bot | app + db + pgbouncer | `ghcr.io/ku113p/price-alert-bot` | — (Telegram only) |
| monitoring | uptime-kuma + dozzle | `louislam/uptime-kuma`, `amir20/dozzle` | https://monitor.syncapp.tech, https://logs.syncapp.tech |
| watchtower | watchtower | `containrrr/watchtower` | — |
| traefik | traefik | `traefik` | — (reverse proxy) |

## VPS Layout

```
/opt/services/
├── traefik/            # reverse proxy (manages TLS)
├── landing/            # personal landing page
├── short-links/        # URL shortener + Redis
├── landing-pages/      # HTML page hosting + Redis
├── message/            # contact form API + Postgres
├── tools-mcp/          # MCP aggregator server
├── cryo-pay/           # crypto payment service
├── interview/          # interview project (promo + backend + mcp)
├── price-alert-bot/    # Telegram bot + Postgres + PgBouncer
├── monitoring/         # uptime-kuma + dozzle
└── watchtower/         # auto-update Docker images
```

## Traefik Routing

Traefik runs as a separate compose stack and handles:
- TLS termination via Let's Encrypt (`certresolver=letsencrypt`)
- Host-based routing (each service gets its own subdomain)
- Middleware: `security-headers@file`, `gzip@file`, `rate-limit-api@file`

Services join the `proxy` network and declare Traefik labels to register routes.

## GitHub Secrets

Set in infra repo → Settings → Secrets and variables → Actions:

| Secret | Purpose |
|--------|---------|
| `VPS_HOST` | VPS IP address |
| `VPS_SSH_KEY` | SSH private key (ed25519) for root@VPS |
| `ACME_EMAIL` | Let's Encrypt certificate notifications |
| `DOZZLE_PASSWORD_HASH` | bcrypt hash for Dozzle login |
| `LANDING_NAME` | Landing page — name |
| `LANDING_TITLE` | Landing page — title |
| `LANDING_BIO` | Landing page — bio text |
| `LANDING_EMAIL` | Landing page — email |
| `LANDING_TELEGRAM` | Landing page — Telegram handle |
| `LANDING_LINKEDIN` | Landing page — LinkedIn URL |

`GITHUB_TOKEN` is automatic — no setup needed for image builds.

### Generating the SSH key

```bash
ssh-keygen -t ed25519 -f ~/.ssh/vps_deploy -N ""
ssh-copy-id -i ~/.ssh/vps_deploy.pub root@YOUR_VPS_IP
# The PRIVATE key (~/.ssh/vps_deploy) goes into GitHub secret VPS_SSH_KEY
```

## How to Add a New Service

1. Add a Dockerfile in the app repo
2. Add a CI job to build and push the image to GHCR
3. Create `compose/<stack>/docker-compose.yml` with Traefik labels
4. Add a deploy workflow in `.github/workflows/deploy-<stack>.yml`
5. Create DNS A record pointing to VPS IP
6. Push both repos — CI handles the rest

## Common Operations

A `Makefile` provides shortcuts for common tasks. Run `make help` to see all targets.

```bash
make status              # Show all containers
make health              # Check container health status
make stats               # Show resource usage
make logs                # Tail interview service logs
make logs-traefik        # Tail traefik logs
make logs-service SVC=backend  # Tail a specific service
make restart-interview   # Restart interview stack
make restart-landing     # Restart landing page
make restart-cryo-pay    # Restart cryo-pay stack
make restart-tools-mcp   # Restart tools-mcp server
make restart-monitoring  # Restart monitoring stack
make restart-traefik     # Restart traefik
make restart-all         # Restart all stacks
make setup-tools-secrets # Generate auth tokens for tools services
```

### Rollback

Revert the git commit and push — CI will build and deploy the old code.

Or manually on VPS:

```bash
ssh root@$VPS_HOST
docker images ghcr.io/ku113p/interview-backend --digests
# Pin to specific digest in docker-compose.yml, then:
cd /opt/services/interview && docker compose up -d backend
```

## DNS Reference

| Subdomain | Purpose |
|-----------|---------|
| `syncapp.tech` | Landing page |
| `www.syncapp.tech` | Landing page (alias) |
| `links.tools.syncapp.tech` | Short links |
| `pages.tools.syncapp.tech` | Landing pages |
| `msg.tools.syncapp.tech` | Message API |
| `mcp.tools.syncapp.tech` | Tools MCP server |
| `pay.syncapp.tech` | Cryo Pay |
| `promo.interview.syncapp.tech` | Interview promo |
| `api.interview.syncapp.tech` | Interview backend API |
| `mcp.interview.syncapp.tech` | Interview MCP server |
| `monitor.syncapp.tech` | Uptime Kuma |
| `logs.syncapp.tech` | Dozzle (log viewer) |

All subdomains are A records pointing to the VPS IP.

## One-Time VPS Setup

```bash
# 1. Run setup script
ssh root@$VPS_HOST 'bash -s' < scripts/setup-vps.sh

# 2. Generate auth tokens for tools services
ssh root@$VPS_HOST 'bash -s' < scripts/setup-tools-secrets.sh

# 3. Auth VPS to GHCR (need GitHub PAT with read:packages)
ssh root@$VPS_HOST
echo "ghp_..." | docker login ghcr.io -u ku113p --password-stdin

# 4. Push this repo — CI deploys everything automatically
git push origin master
```
