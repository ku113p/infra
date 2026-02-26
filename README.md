# Infra — Operations Guide

Infrastructure for [ku113p/interview](https://github.com/ku113p/interview): compose files, deploy scripts, and ops tooling.

## Architecture

```
interview repo                      infra repo
  git push master                     git push master
       |                                   |
       v                                   v
  GitHub Actions                      GitHub Actions
  (build 3 Docker images)            (sync compose files to VPS)
       |                                   |
       v                                   |
  GHCR (image registry)                   |
       |                                   |
       v                                   v
  Watchtower (polls GHCR)            rsync + docker compose up
       |                                   |
       v                                   v
      Live                               Live
```

Both repos auto-deploy on push to master. No manual SSH needed.

## GitHub Secrets

Set these in **both repos** → Settings → Secrets and variables → Actions:

| Secret | Where | Purpose |
|--------|-------|---------|
| `VPS_HOST` | infra | VPS IP address |
| `VPS_SSH_KEY` | infra | SSH private key (ed25519) for root@VPS |
| `ACME_EMAIL` | infra | Let's Encrypt certificate notifications |

`GITHUB_TOKEN` is automatic — no setup needed for the interview repo's image builds.

### Generating the SSH key

```bash
# On your local machine
ssh-keygen -t ed25519 -f ~/.ssh/vps_deploy -N ""

# Copy public key to VPS
ssh-copy-id -i ~/.ssh/vps_deploy.pub root@YOUR_VPS_IP

# The PRIVATE key (~/.ssh/vps_deploy) goes into GitHub secret VPS_SSH_KEY
```

## Services

| Service | Image | Port | URL |
|---------|-------|------|-----|
| promo | `ghcr.io/ku113p/interview-promo` | 80 | https://promo.interview.syncapp.tech |
| backend | `ghcr.io/ku113p/interview-backend` | 8080 | https://api.interview.syncapp.tech |
| mcp | `ghcr.io/ku113p/interview-mcp` | 8080 | https://mcp.interview.syncapp.tech |
| watchtower | `containrrr/watchtower` | — | — |

## VPS Layout

```
/opt/services/
├── interview/          # docker-compose.yml + .env
├── watchtower/         # docker-compose.yml
├── traefik/            # reverse proxy (manages TLS)
├── landing/            # static site + nginx
└── monitoring/         # uptime-kuma + dozzle
```

## Traefik Routing

Traefik runs as a separate compose stack and handles:
- TLS termination via Let's Encrypt (`certresolver=letsencrypt`)
- Host-based routing (each service gets its own subdomain)
- Middleware: `security-headers@file`, `gzip@file`, `rate-limit-api@file`

Services join the `proxy` network and declare Traefik labels to register routes.

## How to Add a New Service

1. Add a Dockerfile in the app directory (e.g., `backend/Dockerfile` in the interview repo)
2. Add a CI job in the interview repo's `.github/workflows/deploy.yml`
3. Add the service to `compose/interview/docker-compose.yml` with Traefik labels
4. Create DNS A record pointing to VPS IP
5. Push both repos — CI handles the rest

## Common Operations

### View logs

```bash
ssh root@$VPS_HOST

# All interview services
cd /opt/services/interview && docker compose logs -f

# Single service
docker logs -f interview-backend

# Watchtower (see pull activity)
docker logs -f watchtower
```

### Restart a service

```bash
ssh root@$VPS_HOST
cd /opt/services/interview && docker compose restart backend
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

### Check resource usage

```bash
ssh root@$VPS_HOST
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

## DNS Reference

| Subdomain | Target | Purpose |
|-----------|--------|---------|
| `promo.interview.syncapp.tech` | VPS IP (A record) | Landing page |
| `api.interview.syncapp.tech` | VPS IP (A record) | Backend API |
| `mcp.interview.syncapp.tech` | VPS IP (A record) | MCP server |

## One-Time VPS Setup

```bash
# 1. Run setup script
ssh root@$VPS_HOST 'bash -s' < scripts/setup-vps.sh

# 2. Auth VPS to GHCR (need GitHub PAT with read:packages)
ssh root@$VPS_HOST
echo "ghp_..." | docker login ghcr.io -u ku113p --password-stdin

# 3. Push this repo — CI deploys everything automatically
git push origin master
```
