# 🛠️ Funny Threads AI Makefile

.PHONY: help run run-all run-be run-fe install lint clean iphone iphone-fast

API_BASE_URL ?= http://localhost:3000
BE_PORT ?= 3000
FE_PORT ?= 3001
NETWORK_IFACE ?=
MAC_IP ?=

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Running ---

run: ## Run backend + frontend together with prefixed logs
	@$(MAKE) run-all

run-all: ## Run backend + frontend together with [BE]/[FE] logs
	@bash -lc '\
	( cd apps/backend && npm run dev 2>&1 | sed "s/^/[BE] /" ) & \
	BE_PID=$$!; \
	( cd apps/frontend && flutter run -d chrome --dart-define=API_BASE_URL=$(API_BASE_URL) 2>&1 | sed "s/^/[FE] /" ) & \
	FE_PID=$$!; \
	cleanup(){ \
	  kill $$BE_PID $$FE_PID 2>/dev/null || true; \
	  wait $$BE_PID $$FE_PID 2>/dev/null || true; \
	}; \
	trap cleanup INT TERM EXIT; \
	wait $$BE_PID $$FE_PID; \
	'

run-be: ## Run backend development server
	cd apps/backend && npm run dev

run-fe: ## Run frontend development server
	cd apps/frontend && flutter run -d chrome --dart-define=API_BASE_URL=$(API_BASE_URL)

iphone: ## Run BE+FE for iPhone on local network with CLI QR
	BE_PORT=$(BE_PORT) FE_PORT=$(FE_PORT) NETWORK_IFACE=$(NETWORK_IFACE) MAC_IP=$(MAC_IP) SKIP_INSTALL=0 ./scripts/test_iphone_lan.sh

iphone-fast: ## Same as iphone, but skip npm/flutter install
	BE_PORT=$(BE_PORT) FE_PORT=$(FE_PORT) NETWORK_IFACE=$(NETWORK_IFACE) MAC_IP=$(MAC_IP) SKIP_INSTALL=1 ./scripts/test_iphone_lan.sh

# --- Development ---

install: ## Install dependencies for both apps
	cd apps/backend && npm install
	cd apps/frontend && flutter pub get

lint: ## Run linting for both apps
	cd apps/backend && npm run lint
	@echo "Running flutter analyze..."
	cd apps/frontend && flutter analyze

clean: ## Clean storage and build artifacts
	rm -rf apps/backend/dist
	rm -rf apps/backend/storage/videos/*
	rm -rf apps/backend/storage/clips/*
	rm -rf apps/backend/storage/jobs/*
	cd apps/frontend && flutter clean

# Handle unknown arguments
%:
	@:
