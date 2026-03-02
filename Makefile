# Infra Makefile — common operations for VPS management
# Requires: VPS_HOST env var (or set in .env)

-include .env
export

SERVER := root@$(VPS_HOST)
SERVICES_DIR := /opt/services

.PHONY: help status health stats logs logs-traefik logs-service \
	restart-interview restart-traefik restart-monitoring restart-landing restart-cryo-pay restart-tools-mcp \
	restart-crypto-assets setup-tools-secrets restart-all

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

# --- Status ---

status: ## Show all containers on VPS
	@ssh $(SERVER) "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"

health: ## Check container health status
	@ssh $(SERVER) "docker ps --format '{{.Names}}\t{{.Status}}' | sort"

stats: ## Show resource usage
	@ssh $(SERVER) "docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'"

# --- Logs ---

logs: ## Tail interview service logs
	@ssh $(SERVER) "cd $(SERVICES_DIR)/interview && docker compose logs -f --tail=50"

logs-traefik: ## Tail traefik logs
	@ssh $(SERVER) "cd $(SERVICES_DIR)/traefik && docker compose logs -f --tail=50"

logs-service: ## Tail a specific service (usage: make logs-service SVC=backend)
	@ssh $(SERVER) "docker logs -f --tail=50 $(SVC)"

# --- Restart ---

restart-interview: ## Restart interview stack
	@ssh $(SERVER) "cd $(SERVICES_DIR)/interview && docker compose up -d"

restart-traefik: ## Restart traefik
	@ssh $(SERVER) "cd $(SERVICES_DIR)/traefik && docker compose up -d"

restart-monitoring: ## Restart monitoring stack
	@ssh $(SERVER) "cd $(SERVICES_DIR)/monitoring && docker compose up -d"

restart-landing: ## Restart landing page
	@ssh $(SERVER) "cd $(SERVICES_DIR)/landing && docker compose up -d"

restart-cryo-pay: ## Restart cryo-pay stack
	@ssh $(SERVER) "cd $(SERVICES_DIR)/cryo-pay && docker compose up -d"

restart-tools-mcp: ## Restart tools-mcp server
	@ssh $(SERVER) "cd $(SERVICES_DIR)/tools-mcp && docker compose up -d"

restart-crypto-assets: ## Restart crypto-assets
	@ssh $(SERVER) "cd $(SERVICES_DIR)/crypto-assets && docker compose up -d"

setup-tools-secrets: ## Generate auth tokens for tools services on VPS
	@ssh $(SERVER) 'bash -s' < scripts/setup-tools-secrets.sh

restart-all: ## Restart all stacks
	@ssh $(SERVER) "\
		cd $(SERVICES_DIR)/traefik && docker compose up -d && \
		cd $(SERVICES_DIR)/landing && docker compose up -d && \
		cd $(SERVICES_DIR)/interview && docker compose up -d && \
		cd $(SERVICES_DIR)/monitoring && docker compose up -d && \
		cd $(SERVICES_DIR)/watchtower && docker compose up -d && \
		cd $(SERVICES_DIR)/cryo-pay && docker compose up -d && \
		cd $(SERVICES_DIR)/crypto-assets && docker compose up -d && \
		cd $(SERVICES_DIR)/tools-mcp && docker compose up -d"
