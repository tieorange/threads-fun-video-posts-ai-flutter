# 🛠️ Funny Threads AI Makefile

.PHONY: help run-be run-fe install lint clean

API_BASE_URL ?= http://localhost:3000

help: ## Display available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Running ---

run: ## Run components (usage: make run be | make run fe)
	@$(MAKE) run-$(filter-out run,$(MAKECMDGOALS))

run-be: ## Run backend development server
	cd apps/backend && npm run dev

run-fe: ## Run frontend development server
	cd apps/frontend && flutter run -d chrome --dart-define=API_BASE_URL=$(API_BASE_URL)

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

# Handle arguments for 'run be' and 'run fe'
%:
	@:
