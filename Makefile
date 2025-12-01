# Docker Services:
#   up - Start services (use: make up [service...] or make up MODE=prod, ARGS="--build" for options)
#   down - Stop services (use: make down [service...] or make down MODE=prod, ARGS="--volumes" for options)
#   build - Build containers (use: make build [service...] or make build MODE=prod)
#   logs - View logs (use: make logs [service] or make logs SERVICE=backend, MODE=prod for production)
#   restart - Restart services (use: make restart [service...] or make restart MODE=prod)
#   shell - Open shell in container (use: make shell [service] or make shell SERVICE=gateway, MODE=prod, default: backend)
#   ps - Show running containers (use MODE=prod for production)
#
# Convenience Aliases (Development):
#   dev-up - Alias: Start development environment
#   dev-down - Alias: Stop development environment
#   dev-build - Alias: Build development containers
#   dev-logs - Alias: View development logs
#   dev-restart - Alias: Restart development services
#   dev-shell - Alias: Open shell in backend container
#   dev-ps - Alias: Show running development containers
#   backend-shell - Alias: Open shell in backend container
#   gateway-shell - Alias: Open shell in gateway container
#   mongo-shell - Open MongoDB shell
#
# Convenience Aliases (Production):
#   prod-up - Alias: Start production environment
#   prod-down - Alias: Stop production environment
#   prod-build - Alias: Build production containers
#   prod-logs - Alias: View production logs
#   prod-restart - Alias: Restart production services
#
# Backend:
#   backend-build - Build backend TypeScript
#   backend-install - Install backend dependencies
#   backend-type-check - Type check backend code
#   backend-dev - Run backend in development mode (local, not Docker)
#
# Database:
#   db-reset - Reset MongoDB database (WARNING: deletes all data)
#   db-backup - Backup MongoDB database
#
# Cleanup:
#   clean - Remove containers and networks (both dev and prod)
#   clean-all - Remove containers, networks, volumes, and images
#   clean-volumes - Remove all volumes
#
# Utilities:
#   status - Alias for ps
#   health - Check service health
#
# Help:
#   help - Display this help message


# Default mode and service
MODE ?= dev
SERVICE ?= 

# Docker Compose files
DEV_COMPOSE = docker/compose.development.yaml
PROD_COMPOSE = docker/compose.production.yaml

# Determine compose file based on mode
ifeq ($(MODE),prod)
	COMPOSE_FILE = $(PROD_COMPOSE)
else
	COMPOSE_FILE = $(DEV_COMPOSE)
endif

# Docker Compose base command
DOCKER_COMPOSE = docker compose -f $(COMPOSE_FILE)
DOCKER_COMPOSE_DEV = docker compose -f $(DEV_COMPOSE)
DOCKER_COMPOSE_PROD = docker compose -f $(PROD_COMPOSE)

# Parse .env file for commands that need credentials
ENV_FILE = .env
ifneq ($(wildcard $(ENV_FILE)),)
  MONGO_USER := $(shell grep MONGO_INITDB_ROOT_USERNAME $(ENV_FILE) | cut -d'=' -f2 | tr -d ' ')
  MONGO_PASS := $(shell grep MONGO_INITDB_ROOT_PASSWORD $(ENV_FILE) | cut -d'=' -f2 | tr -d ' ')
  MONGO_DB := $(shell grep MONGO_DATABASE $(ENV_FILE) | cut -d'=' -f2 | tr -d ' ')
  GATEWAY_PORT := $(shell grep GATEWAY_PORT $(ENV_FILE) | cut -d'=' -f2 | tr -d ' ')
endif

# Core Docker commands
.PHONY: up
up:
	$(DOCKER_COMPOSE) up -d $(ARGS) $(SERVICE)

.PHONY: down
down:
	$(DOCKER_COMPOSE) down $(ARGS) $(SERVICE)

.PHONY: build
build:
	$(DOCKER_COMPOSE) build $(ARGS) $(SERVICE)

.PHONY: logs
logs:
	$(DOCKER_COMPOSE) logs -f $(SERVICE)

.PHONY: restart
restart:
	$(DOCKER_COMPOSE) restart $(SERVICE)

.PHONY: shell
shell:
	@if [ -z "$(SERVICE)" ]; then \
		echo "Usage: make shell SERVICE=<service> [MODE=prod]"; \
		echo "Example: make shell SERVICE=backend"; \
		exit 1; \
	fi
	$(DOCKER_COMPOSE) exec $(SERVICE) /bin/sh

.PHONY: ps
ps:
	$(DOCKER_COMPOSE) ps

# Development aliases
.PHONY: dev-up dev-down dev-build dev-logs dev-restart dev-shell backend-shell gateway-shell mongo-shell

dev-up: MODE=dev
dev-up:
	$(DOCKER_COMPOSE_DEV) up -d $(ARGS) $(SERVICE)

dev-down: MODE=dev
dev-down:
	$(DOCKER_COMPOSE_DEV) down $(ARGS) $(SERVICE)

dev-build: MODE=dev
dev-build:
	$(DOCKER_COMPOSE_DEV) build $(ARGS) $(SERVICE)

dev-logs: MODE=dev
dev-logs:
	$(DOCKER_COMPOSE_DEV) logs -f $(SERVICE)

dev-restart: MODE=dev
dev-restart:
	$(DOCKER_COMPOSE_DEV) restart $(SERVICE)

dev-shell: MODE=dev SERVICE=backend
dev-shell:
	$(DOCKER_COMPOSE_DEV) exec backend /bin/sh

backend-shell: dev-shell

gateway-shell: MODE=dev SERVICE=gateway
gateway-shell:
	$(DOCKER_COMPOSE_DEV) exec gateway /bin/sh

mongo-shell: MODE=dev SERVICE=mongodb
mongo-shell:
	@if [ -z "$(MONGO_USER)" ] || [ -z "$(MONGO_PASS)" ] || [ -z "$(MONGO_DB)" ]; then \
		echo "Error: Could not parse MongoDB credentials from .env file"; \
		exit 1; \
	fi
	$(DOCKER_COMPOSE_DEV) exec mongodb mongosh -u "$(MONGO_USER)" -p "$(MONGO_PASS)" --authenticationDatabase admin "$(MONGO_DB)"

# Production aliases
.PHONY: prod-up prod-down prod-build prod-logs prod-restart


prod-up: MODE=prod
prod-up:
	$(DOCKER_COMPOSE_PROD) up -d $(ARGS) $(SERVICE)

prod-down: MODE=prod
prod-down:
	$(DOCKER_COMPOSE_PROD) down $(ARGS) $(SERVICE)

prod-build: MODE=prod
prod-build:
	$(DOCKER_COMPOSE_PROD) build $(ARGS) $(SERVICE)

prod-logs: MODE=prod
prod-logs:
	$(DOCKER_COMPOSE_PROD) logs -f $(SERVICE)

prod-restart: MODE=prod
prod-restart:
	$(DOCKER_COMPOSE_PROD) restart $(SERVICE)

# Cleanup commands
.PHONY: clean clean-all clean-volumes

clean:
	-docker compose -f $(DEV_COMPOSE) down --remove-orphans 2>/dev/null
	-docker compose -f $(PROD_COMPOSE) down --remove-orphans 2>/dev/null

clean-all:
	-docker compose -f $(DEV_COMPOSE) down --remove-orphans --volumes --rmi all 2>/dev/null
	-docker compose -f $(PROD_COMPOSE) down --remove-orphans --volumes --rmi all 2>/dev/null

clean-volumes:
	-docker compose -f $(DEV_COMPOSE) down --volumes 2>/dev/null
	-docker compose -f $(PROD_COMPOSE) down --volumes 2>/dev/null

# Utility commands
.PHONY: status health

status: ps

health:
	@if [ -z "$(GATEWAY_PORT)" ]; then \
		echo "Error: GATEWAY_PORT not found in .env file"; \
		exit 1; \
	fi
	@echo "Checking gateway health..."
	@curl -f http://localhost:$(GATEWAY_PORT)/health || (echo "Gateway health check failed" && exit 1)
	@echo "Checking backend health via gateway..."
	@curl -f http://localhost:$(GATEWAY_PORT)/api/health || (echo "Backend health check failed" && exit 1)
	@echo "All services are healthy!"

# Backend local development commands
.PHONY: backend-build backend-install backend-type-check backend-dev

backend-build:
	cd backend && npm run build

backend-install:
	cd backend && npm install

backend-type-check:
	cd backend && npm run type-check

backend-dev:
	cd backend && npm run dev

# Database management commands
.PHONY: db-reset db-backup

db-reset:
	@echo "WARNING: This will delete all data in the MongoDB database!"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ]
	@if [ -z "$(MONGO_USER)" ] || [ -z "$(MONGO_PASS)" ] || [ -z "$(MONGO_DB)" ]; then \
		echo "Error: Could not parse MongoDB credentials from .env file"; \
		exit 1; \
	fi
	$(DOCKER_COMPOSE) exec mongodb mongosh -u "$(MONGO_USER)" -p "$(MONGO_PASS)" --authenticationDatabase admin "$(MONGO_DB)" --eval "db.dropDatabase()"

db-backup:
	@if [ -z "$(MONGO_USER)" ] || [ -z "$(MONGO_PASS)" ] || [ -z "$(MONGO_DB)" ]; then \
		echo "Error: Could not parse MongoDB credentials from .env file"; \
		exit 1; \
	fi
	@echo "Backing up database..."
	$(DOCKER_COMPOSE) exec mongodb mongodump -u "$(MONGO_USER)" -p "$(MONGO_PASS)" --authenticationDatabase admin --db "$(MONGO_DB)" --archive=/backup/backup_$$(date +%Y%m%d_%H%M%S).archive
	@echo "Backup created in mongodb container at /backup/"

# Help command
.PHONY: help
help:
	@echo "E-commerce Hackathon Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make [COMMAND] [SERVICE=<service>] [MODE=dev|prod] [ARGS=\"<args>\"]"
	@echo ""
	@echo "Core Commands:"
	@echo "  up [service...]       - Start services"
	@echo "  down [service...]     - Stop services"
	@echo "  build [service...]    - Build containers"
	@echo "  logs [service]        - View logs"
	@echo "  restart [service...]  - Restart services"
	@echo "  shell [service]       - Open shell in container"
	@echo "  ps                    - Show running containers"
	@echo ""
	@echo "Development Aliases:"
	@echo "  dev-up, dev-down, dev-build, dev-logs, dev-restart"
	@echo "  dev-shell, backend-shell, gateway-shell, mongo-shell"
	@echo ""
	@echo "Production Aliases:"
	@echo "  prod-up, prod-down, prod-build, prod-logs, prod-restart"
	@echo ""
	@echo "Examples:"
	@echo "  make up                           # Start all services in dev mode"
	@echo "  make up SERVICE=gateway           # Start only gateway"
	@echo "  make up MODE=prod ARGS=\"--build\"  # Build and start prod services"
	@echo "  make shell SERVICE=backend        # Open shell in backend"
	@echo "  make health                       # Check service health"