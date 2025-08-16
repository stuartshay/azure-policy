# Azure Policy & Functions Development Environment Makefile
#
# This Makefile provides a unified interface for all development operations
# including testing, building, formatting, and deployment.

# Project Configuration
PROJECT_NAME := azure-policy
PYTHON_VERSION := 3.13
VENV_PATH := .venv
FUNCTIONS_PATH := functions/basic
INFRASTRUCTURE_PATH := infrastructure
SCRIPTS_PATH := scripts

# Colors for output (if terminal supports it)
ifneq (,$(findstring xterm,${TERM}))
	RED := $(shell tput -Txterm setaf 1)
	GREEN := $(shell tput -Txterm setaf 2)
	YELLOW := $(shell tput -Txterm setaf 3)
	BLUE := $(shell tput -Txterm setaf 4)
	RESET := $(shell tput -Txterm sgr0)
else
	RED := ""
	GREEN := ""
	YELLOW := ""
	BLUE := ""
	RESET := ""
endif

# Default target
.DEFAULT_GOAL := help

# Phony targets (targets that don't create files)
.PHONY: help setup clean install install-dev install-functions \
	test test-all test-smoke test-policy test-integration test-infrastructure test-coverage test-live \
	format format-check lint lint-python lint-shell lint-terraform \
	pre-commit pre-commit-install pre-commit-update pre-commit-run \
	functions functions-start functions-stop functions-logs \
	devcontainer devcontainer-build devcontainer-test devcontainer-rebuild devcontainer-debug \
	azure azure-login azure-logout azure-policies azure-assignments \
	terraform terraform-login terraform-init terraform-plan terraform-apply terraform-destroy \
	terraform-validate terraform-fmt terraform-output \
	docs docs-generate docs-serve \
	security security-scan security-secrets \
	ci ci-setup ci-test \
	dev dev-setup dev-start dev-stop dev-status \
	jupyter jupyter-start jupyter-stop jupyter-clean \
	requirements requirements-update requirements-check requirements-compile \
	validate validate-all validate-policies validate-syntax validate-requirements \
	build build-all build-functions build-docs \
	deploy deploy-functions deploy-infrastructure \
	monitoring monitoring-start monitoring-stop monitoring-logs \
	backup backup-policies backup-terraform backup-all \
	release release-prepare release-tag release-publish

##@ General

help: ## Display this help message
	@echo "$(GREEN)Azure Policy & Functions Development Environment$(RESET)"
	@echo ""
	@echo "$(YELLOW)Usage: make <target>$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(BLUE)%-20s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Quick Start:$(RESET)"
	@echo "  make setup      # Initial environment setup"
	@echo "  make test       # Run all tests"
	@echo "  make dev-start  # Start development environment"
	@echo ""

status: ## Show current project status
	@echo "$(GREEN)=== Project Status ===$(RESET)"
	@echo "Project: $(PROJECT_NAME)"
	@echo "Python: $(shell python3 --version 2>/dev/null || echo 'Not installed')"
	@echo "Virtual environment: $(shell test -d $(VENV_PATH) && echo 'EXISTS' || echo 'MISSING')"
	@echo "Azure CLI: $(shell az --version 2>/dev/null | head -1 || echo 'Not installed')"
	@echo "Docker: $(shell docker --version 2>/dev/null || echo 'Not installed')"
	@echo "Functions Core Tools: $(shell func --version 2>/dev/null || echo 'Not installed')"
	@echo "Terraform: $(shell terraform --version 2>/dev/null | head -1 || echo 'Not installed')"
	@echo "Pre-commit: $(shell pre-commit --version 2>/dev/null || echo 'Not installed')"

clean: ## Clean up generated files and caches
	@echo "$(YELLOW)Cleaning up generated files...$(RESET)"
	rm -rf $(VENV_PATH)
	rm -rf __pycache__ .pytest_cache .mypy_cache .coverage htmlcov
	rm -rf test-report.html
	rm -rf .terraform .terraform.lock.hcl terraform.tfstate*
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	@echo "$(GREEN)Cleanup completed$(RESET)"

##@ Environment Setup

setup: ## Complete environment setup
	@echo "$(GREEN)Setting up development environment...$(RESET)"
	@$(MAKE) install-dev
	@$(MAKE) pre-commit-install
	@$(MAKE) validate-requirements
	@echo "$(GREEN)Environment setup completed$(RESET)"

install: ## Install basic dependencies
	@echo "$(YELLOW)Installing basic dependencies...$(RESET)"
	pip install --upgrade pip
	pip install -r requirements.txt

install-dev: ## Install development dependencies
	@echo "$(YELLOW)Installing development dependencies...$(RESET)"
	python3 -m venv $(VENV_PATH) || echo "Virtual environment already exists"
	. $(VENV_PATH)/bin/activate && pip install --upgrade pip
	. $(VENV_PATH)/bin/activate && pip install -r requirements.txt
	@echo "$(GREEN)Development dependencies installed$(RESET)"

install-functions: ## Install Azure Functions dependencies
	@echo "$(YELLOW)Installing Azure Functions dependencies...$(RESET)"
	cd $(FUNCTIONS_PATH) && python3 -m venv .venv || echo "Functions venv already exists"
	cd $(FUNCTIONS_PATH) && . .venv/bin/activate && pip install --upgrade pip
	cd $(FUNCTIONS_PATH) && . .venv/bin/activate && pip install -r requirements.txt
	@echo "$(GREEN)Functions dependencies installed$(RESET)"

##@ Testing

test: ## Run all tests
	@echo "$(YELLOW)Running all tests...$(RESET)"
	./run-tests.sh all

test-all: test ## Alias for test

test-smoke: ## Run quick smoke tests
	@echo "$(YELLOW)Running smoke tests...$(RESET)"
	./run-tests.sh smoke

test-policy: ## Run policy validation tests
	@echo "$(YELLOW)Running policy tests...$(RESET)"
	./run-tests.sh policy

test-integration: ## Run integration tests
	@echo "$(YELLOW)Running integration tests...$(RESET)"
	./run-tests.sh integration

test-infrastructure: ## Run infrastructure tests
	@echo "$(YELLOW)Running infrastructure tests...$(RESET)"
	./run-tests.sh infrastructure

test-coverage: ## Run tests with coverage report
	@echo "$(YELLOW)Running tests with coverage...$(RESET)"
	./run-tests.sh coverage
	@echo "$(GREEN)Coverage report available at: htmlcov/index.html$(RESET)"

test-live: ## Run live Azure tests (requires authentication)
	@echo "$(YELLOW)Running live Azure tests...$(RESET)"
	./run-tests.sh live

##@ Code Quality

format: ## Format all code
	@echo "$(YELLOW)Formatting code...$(RESET)"
	. $(VENV_PATH)/bin/activate && black .
	. $(VENV_PATH)/bin/activate && isort .
	cd $(FUNCTIONS_PATH) && . .venv/bin/activate && black .
	cd $(FUNCTIONS_PATH) && . .venv/bin/activate && isort .
	@echo "$(GREEN)Code formatting completed$(RESET)"

format-check: ## Check code formatting without making changes
	@echo "$(YELLOW)Checking code formatting...$(RESET)"
	. $(VENV_PATH)/bin/activate && black --check .
	. $(VENV_PATH)/bin/activate && isort --check-only .

lint: lint-python lint-shell lint-terraform ## Run all linting

lint-python: ## Lint Python code
	@echo "$(YELLOW)Linting Python code...$(RESET)"
	. $(VENV_PATH)/bin/activate && flake8 .
	cd $(FUNCTIONS_PATH) && . .venv/bin/activate && pylint function_app.py || echo "Pylint warnings found"

lint-shell: ## Lint shell scripts
	@echo "$(YELLOW)Linting shell scripts...$(RESET)"
	find . -name "*.sh" -not -path "./.git/*" -exec shellcheck {} \; || echo "Shellcheck warnings found"

lint-terraform: ## Lint Terraform code
	@echo "$(YELLOW)Linting Terraform code...$(RESET)"
	cd $(INFRASTRUCTURE_PATH) && terraform fmt -check -recursive || echo "Terraform formatting issues found"

pre-commit: ## Run pre-commit hooks on all files
	@echo "$(YELLOW)Running pre-commit hooks...$(RESET)"
	pre-commit run --all-files

pre-commit-install: ## Install pre-commit hooks
	@echo "$(YELLOW)Installing pre-commit hooks...$(RESET)"
	pip install pre-commit
	pre-commit install
	pre-commit install-hooks
	@echo "$(GREEN)Pre-commit hooks installed$(RESET)"

pre-commit-update: ## Update pre-commit hooks to latest versions
	@echo "$(YELLOW)Updating pre-commit hooks...$(RESET)"
	pre-commit autoupdate
	pre-commit install
	@echo "$(GREEN)Pre-commit hooks updated$(RESET)"

pre-commit-run: pre-commit ## Alias for pre-commit

##@ Azure Functions

functions: functions-start ## Start Azure Functions (alias)

functions-start: ## Start Azure Functions development server
	@echo "$(YELLOW)Starting Azure Functions...$(RESET)"
	./start-functions.sh

functions-stop: ## Stop Azure Functions development server
	@echo "$(YELLOW)Stopping Azure Functions...$(RESET)"
	pkill -f "func start" || echo "No Functions process found"

functions-logs: ## Show Azure Functions logs
	@echo "$(YELLOW)Azure Functions logs:$(RESET)"
	@echo "Check terminal output or logs in functions/basic/"

##@ DevContainer

devcontainer: devcontainer-test ## Test DevContainer (alias)

devcontainer-build: ## Build DevContainer
	@echo "$(YELLOW)Building DevContainer...$(RESET)"
	$(SCRIPTS_PATH)/test-devcontainer.sh --build-only

devcontainer-test: ## Test DevContainer environment
	@echo "$(YELLOW)Testing DevContainer...$(RESET)"
	$(SCRIPTS_PATH)/test-devcontainer.sh

devcontainer-rebuild: ## Quick rebuild DevContainer
	@echo "$(YELLOW)Quick rebuilding DevContainer...$(RESET)"
	$(SCRIPTS_PATH)/quick-rebuild-devcontainer.sh

devcontainer-debug: ## Debug DevContainer issues
	@echo "$(YELLOW)Debugging DevContainer...$(RESET)"
	$(SCRIPTS_PATH)/debug-devcontainer.sh --all

##@ Azure CLI

azure-login: ## Login to Azure
	@echo "$(YELLOW)Logging into Azure...$(RESET)"
	az login

azure-logout: ## Logout from Azure
	@echo "$(YELLOW)Logging out from Azure...$(RESET)"
	az logout

azure-policies: ## List Azure policies
	@echo "$(YELLOW)Listing Azure policies...$(RESET)"
	$(SCRIPTS_PATH)/01-list-policies.sh

azure-assignments: ## List policy assignments
	@echo "$(YELLOW)Listing policy assignments...$(RESET)"
	$(SCRIPTS_PATH)/03-list-assignments.sh

##@ Terraform

# Helper function to load .env and export Terraform token
define load-terraform-env
	@if [ -f .env ]; then \
		echo "$(BLUE)Loading Terraform Cloud token from .env...$(RESET)"; \
		export $$(grep -E '^TF_API_TOKEN=' .env | xargs) && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		export $$(grep -E '^ARM_' .env | xargs); \
	else \
		echo "$(RED)Warning: .env file not found. Please copy .env.template to .env and add your tokens.$(RESET)"; \
		exit 1; \
	fi
endef

terraform-version: ## Show current Terraform version and tfenv status
	@echo "$(YELLOW)Checking Terraform version...$(RESET)"
	@./scripts/terraform-version-check.sh

terraform-check-versions: terraform-version ## Check Terraform and provider versions (alias)

terraform-update-providers: ## Update provider versions across all modules
	@echo "$(YELLOW)Updating Terraform providers...$(RESET)"
	@echo "Usage: make terraform-update-providers OLD_VERSION=4.37 NEW_VERSION=4.39"
	@if [ -z "$(OLD_VERSION)" ] || [ -z "$(NEW_VERSION)" ]; then \
		echo "$(RED)Error: OLD_VERSION and NEW_VERSION are required$(RESET)"; \
		echo "Example: make terraform-update-providers OLD_VERSION=4.37 NEW_VERSION=4.39"; \
		exit 1; \
	fi
	@./scripts/terraform-update-providers.sh --old-version $(OLD_VERSION) --new-version $(NEW_VERSION)

terraform-update-providers-dry-run: ## Preview provider version updates without making changes
	@echo "$(YELLOW)Previewing Terraform provider updates...$(RESET)"
	@if [ -z "$(OLD_VERSION)" ] || [ -z "$(NEW_VERSION)" ]; then \
		echo "$(RED)Error: OLD_VERSION and NEW_VERSION are required$(RESET)"; \
		echo "Example: make terraform-update-providers-dry-run OLD_VERSION=4.37 NEW_VERSION=4.39"; \
		exit 1; \
	fi
	@./scripts/terraform-update-providers.sh --old-version $(OLD_VERSION) --new-version $(NEW_VERSION) --dry-run

terraform-set-version: ## Set Terraform version for the project using tfenv
	@echo "$(YELLOW)Setting Terraform version...$(RESET)"
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)Error: VERSION is required$(RESET)"; \
		echo "Example: make terraform-set-version VERSION=1.10.3"; \
		exit 1; \
	fi
	@if command -v tfenv >/dev/null 2>&1; then \
		echo "$(BLUE)Installing Terraform $(VERSION) via tfenv...$(RESET)"; \
		tfenv install $(VERSION); \
		tfenv use $(VERSION); \
		echo "$(VERSION)" > .terraform-version; \
		echo "$(GREEN)Terraform version set to $(VERSION)$(RESET)"; \
	else \
		echo "$(RED)Error: tfenv is not installed. Install it first with: make setup$(RESET)"; \
		exit 1; \
	fi

terraform-login: ## Configure Terraform Cloud authentication from .env
	@echo "$(YELLOW)Configuring Terraform Cloud authentication...$(RESET)"
	@if [ -f .env ]; then \
		. ./.env && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		echo "$(GREEN)Terraform Cloud token loaded from .env$(RESET)" && \
		echo "Organization: $$(grep TF_CLOUD_ORGANIZATION .env | cut -d'=' -f2)" && \
		echo "Token: $${TF_TOKEN_app_terraform_io:0:20}..." && \
		echo "" && \
		echo "$(GREEN)Authentication configured. You can now run terraform commands.$(RESET)"; \
	else \
		echo "$(RED)Error: .env file not found. Please copy .env.template to .env and add your tokens.$(RESET)"; \
		exit 1; \
	fi

terraform-init: ## Initialize Terraform (main workspace)
	@echo "$(YELLOW)Initializing Terraform...$(RESET)"
	@if [ -f .env ]; then \
		set -a && . ./.env && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		cd $(INFRASTRUCTURE_PATH)/terraform && terraform init; \
	else \
		echo "$(RED)Error: .env file not found. Please copy .env.template to .env and add your tokens.$(RESET)"; \
		exit 1; \
	fi

terraform-plan: ## Plan Terraform changes (main workspace)
	@echo "$(YELLOW)Planning Terraform changes...$(RESET)"
	@if [ -f .env ]; then \
		set -a && . ./.env && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		cd $(INFRASTRUCTURE_PATH)/terraform && terraform plan; \
	else \
		echo "$(RED)Error: .env file not found. Please copy .env.template to .env and add your tokens.$(RESET)"; \
		exit 1; \
	fi

terraform-apply: ## Apply Terraform changes (main workspace)
	@echo "$(YELLOW)Applying Terraform changes...$(RESET)"
	@if [ -f .env ]; then \
		set -a && . ./.env && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		cd $(INFRASTRUCTURE_PATH)/terraform && terraform apply; \
	else \
		echo "$(RED)Error: .env file not found. Please copy .env.template to .env and add your tokens.$(RESET)"; \
		exit 1; \
	fi

terraform-destroy: ## Destroy Terraform resources (main workspace)
	@echo "$(RED)Destroying Terraform resources...$(RESET)"
	@if [ -f .env ]; then \
		set -a && . ./.env && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		cd $(INFRASTRUCTURE_PATH)/terraform && terraform destroy; \
	else \
		echo "$(RED)Error: .env file not found. Please copy .env.template to .env and add your tokens.$(RESET)"; \
		exit 1; \
	fi

terraform-validate: ## Validate Terraform configuration
	@echo "$(YELLOW)Validating Terraform configuration...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/terraform && terraform validate

terraform-fmt: ## Format Terraform files
	@echo "$(YELLOW)Formatting Terraform files...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/terraform && terraform fmt -recursive

terraform-output: ## Show Terraform outputs (main workspace)
	@echo "$(YELLOW)Terraform outputs:$(RESET)"
	@if [ -f .env ]; then \
		set -a && . ./.env && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		cd $(INFRASTRUCTURE_PATH)/terraform && terraform output; \
	else \
		echo "$(RED)Error: .env file not found. Please copy .env.template to .env and add your tokens.$(RESET)"; \
		exit 1; \
	fi

##@ Terraform Workspaces

terraform-core-init: ## Initialize Core workspace
	@echo "$(YELLOW)Initializing Core workspace...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/core && $(MAKE) init

terraform-core-plan: ## Plan Core workspace changes
	@echo "$(YELLOW)Planning Core workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/core && $(MAKE) plan

terraform-core-apply: ## Apply Core workspace changes
	@echo "$(YELLOW)Applying Core workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/core && $(MAKE) apply

terraform-core-destroy: ## Destroy Core workspace resources
	@echo "$(RED)Destroying Core workspace resources...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/core && $(MAKE) destroy

terraform-app-service-init: ## Initialize App Service workspace
	@echo "$(YELLOW)Initializing App Service workspace...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/app-service && $(MAKE) init

terraform-app-service-plan: ## Plan App Service workspace changes
	@echo "$(YELLOW)Planning App Service workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/app-service && $(MAKE) plan

terraform-app-service-apply: ## Apply App Service workspace changes
	@echo "$(YELLOW)Applying App Service workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/app-service && $(MAKE) apply

terraform-app-service-destroy: ## Destroy App Service workspace resources
	@echo "$(RED)Destroying App Service workspace resources...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/app-service && $(MAKE) destroy

terraform-policies-init: ## Initialize Policies workspace
	@echo "$(YELLOW)Initializing Policies workspace...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/policies && $(MAKE) init

terraform-policies-plan: ## Plan Policies workspace changes
	@echo "$(YELLOW)Planning Policies workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/policies && $(MAKE) plan

terraform-policies-apply: ## Apply Policies workspace changes
	@echo "$(YELLOW)Applying Policies workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/policies && $(MAKE) apply

terraform-policies-destroy: ## Destroy Policies workspace resources
	@echo "$(RED)Destroying Policies workspace resources...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/policies && $(MAKE) destroy

terraform-database-init: ## Initialize Database workspace
	@echo "$(YELLOW)Initializing Database workspace...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/database && $(MAKE) init

terraform-database-plan: ## Plan Database workspace changes
	@echo "$(YELLOW)Planning Database workspace changes...$(RESET)"
	@if [ -z "$(TF_VAR_dev_access_ip)" ]; then \
		echo "$(YELLOW)Warning: TF_VAR_dev_access_ip not set. Database will not allow development access.$(RESET)"; \
		echo "$(YELLOW)Set with: export TF_VAR_dev_access_ip=\$$(curl -s ifconfig.me)$(RESET)"; \
	fi
	@cd $(INFRASTRUCTURE_PATH)/database && $(MAKE) plan

terraform-database-apply: ## Apply Database workspace changes
	@echo "$(YELLOW)Applying Database workspace changes...$(RESET)"
	@if [ -z "$(TF_VAR_dev_access_ip)" ]; then \
		echo "$(YELLOW)Warning: TF_VAR_dev_access_ip not set. Database will not allow development access.$(RESET)"; \
		echo "$(YELLOW)Set with: export TF_VAR_dev_access_ip=\$$(curl -s ifconfig.me)$(RESET)"; \
	fi
	@cd $(INFRASTRUCTURE_PATH)/database && $(MAKE) apply

terraform-database-destroy: ## Destroy Database workspace resources
	@echo "$(RED)Destroying Database workspace resources...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/database && $(MAKE) destroy

terraform-database-status: ## Show Database deployment status
	@echo "$(BLUE)Database deployment status:$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/database && $(MAKE) status

setup-dev-database-access: ## Set up development database access with current public IP
	@echo "$(YELLOW)Setting up development database access...$(RESET)"
	@CURRENT_IP=$$(curl -s ifconfig.me 2>/dev/null || echo "unable-to-detect"); \
	if [ "$$CURRENT_IP" = "unable-to-detect" ]; then \
		echo "$(RED)Unable to detect public IP. Please set manually:$(RESET)"; \
		echo "$(YELLOW)export TF_VAR_dev_access_ip=your.ip.address.here$(RESET)"; \
	else \
		echo "$(GREEN)Detected public IP: $$CURRENT_IP$(RESET)"; \
		echo "$(YELLOW)Run the following command to set development access:$(RESET)"; \
		echo "$(BLUE)export TF_VAR_dev_access_ip=$$CURRENT_IP$(RESET)"; \
	fi

terraform-functions-app-init: ## Initialize Functions App workspace
	@echo "$(YELLOW)Initializing Functions App workspace...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/functions-app && $(MAKE) init

terraform-functions-app-plan: ## Plan Functions App workspace changes
	@echo "$(YELLOW)Planning Functions App workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/functions-app && $(MAKE) plan

terraform-functions-app-apply: ## Apply Functions App workspace changes
	@echo "$(YELLOW)Applying Functions App workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/functions-app && $(MAKE) apply

terraform-functions-app-destroy: ## Destroy Functions App workspace resources
	@echo "$(RED)Destroying Functions App workspace resources...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/functions-app && $(MAKE) destroy

terraform-functions-app-status: ## Show Functions App deployment status
	@echo "$(BLUE)Functions App deployment status:$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/functions-app && $(MAKE) status

terraform-service-bus-init: ## Initialize Service Bus workspace
	@echo "$(YELLOW)Initializing Service Bus workspace...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/service-bus && $(MAKE) init

terraform-service-bus-plan: ## Plan Service Bus workspace changes
	@echo "$(YELLOW)Planning Service Bus workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/service-bus && $(MAKE) plan

terraform-service-bus-apply: ## Apply Service Bus workspace changes
	@echo "$(YELLOW)Applying Service Bus workspace changes...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/service-bus && $(MAKE) apply

terraform-service-bus-destroy: ## Destroy Service Bus workspace resources
	@echo "$(RED)Destroying Service Bus workspace resources...$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/service-bus && $(MAKE) destroy

terraform-service-bus-status: ## Show Service Bus deployment status
	@echo "$(BLUE)Service Bus deployment status:$(RESET)"
	@cd $(INFRASTRUCTURE_PATH)/service-bus && $(MAKE) status

##@ Module Management

module-verify: ## Verify module is ready for publishing
	@echo "$(YELLOW)Verifying networking module for publishing...$(RESET)"
	./scripts/verify-module-ready.sh

module-publish-help: ## Show module publishing instructions
	@echo "$(GREEN)=== Module Publishing Instructions ===$(RESET)"
	@echo ""
	@echo "1. $(YELLOW)Verify module readiness:$(RESET)"
	@echo "   make module-verify"
	@echo ""
	@echo "2. $(YELLOW)Publish manually in Terraform Cloud:$(RESET)"
	@echo "   • Go to: https://app.terraform.io/app/azure-policy-cloud/registry"
	@echo "   • Click 'Publish' > 'Module'"
	@echo "   • Repository: stuartshay/azure-policy"
	@echo "   • Module Name: networking"
	@echo "   • Provider: azurerm"
	@echo "   • Module Directory: infrastructure/terraform/modules/networking"
	@echo "   • Publishing Type: Tag"
	@echo ""
	@echo "3. $(YELLOW)Switch to registry source:$(RESET)"
	@echo "   make module-switch-to-registry"
	@echo ""

module-switch-to-registry: ## Switch core infrastructure to use registry module
	@echo "$(YELLOW)Switching to Terraform Cloud registry module...$(RESET)"
	./scripts/switch-to-registry-module.sh 0.1.0

module-tag: ## Create and push a new module version tag
	@read -p "Enter version (e.g., 0.1.1): " VERSION && \
	git tag -a "v$$VERSION" -m "Release v$$VERSION: networking module" && \
	git push origin "v$$VERSION" && \
	echo "$(GREEN)Tagged and pushed v$$VERSION$(RESET)"

terraform-all-init: ## Initialize all Terraform workspaces
	@echo "$(YELLOW)Initializing all Terraform workspaces...$(RESET)"
	@$(MAKE) terraform-core-init
	@$(MAKE) terraform-app-service-init
	@$(MAKE) terraform-database-init
	@$(MAKE) terraform-service-bus-init
	@$(MAKE) terraform-policies-init
	@echo "$(GREEN)All workspaces initialized$(RESET)"

terraform-all-plan: ## Plan changes for all workspaces
	@echo "$(YELLOW)Planning changes for all workspaces...$(RESET)"
	@$(MAKE) terraform-core-plan
	@$(MAKE) terraform-app-service-plan
	@$(MAKE) terraform-database-plan
	@$(MAKE) terraform-service-bus-plan
	@$(MAKE) terraform-policies-plan
	@echo "$(GREEN)All workspace plans completed$(RESET)"

terraform-workspaces: ## Show all Terraform workspaces
	@echo "$(GREEN)Available Terraform Workspaces:$(RESET)"
	@echo "  $(BLUE)core$(RESET)         - Core infrastructure (networking, resource groups)"
	@echo "  $(BLUE)app-service$(RESET)  - App Service infrastructure (plans, storage, insights)"
	@echo "  $(BLUE)database$(RESET)     - Database infrastructure (PostgreSQL server and databases)"
	@echo "  $(BLUE)functions-app$(RESET) - Function App deployment (depends on app-service)"
	@echo "  $(BLUE)service-bus$(RESET)  - Service Bus namespace, queues, and topics"
	@echo "  $(BLUE)policies$(RESET)     - Azure Policy definitions and assignments"
	@echo ""
	@echo "$(YELLOW)Use workspace-specific commands:$(RESET)"
	@echo "  make terraform-core-init             # Initialize core workspace"
	@echo "  make terraform-app-service-plan      # Plan app service workspace"
	@echo "  make terraform-database-apply        # Apply database workspace"
	@echo "  make terraform-functions-app-apply   # Apply functions app workspace"
	@echo "  make terraform-service-bus-apply     # Apply service bus workspace"
	@echo "  make terraform-policies-apply        # Apply policies workspace"
	@echo ""
	@echo "$(YELLOW)Or work directly in the workspace directory:$(RESET)"
	@echo "  cd infrastructure/core && make init"
	@echo "  cd infrastructure/app-service && make plan"
	@echo "  cd infrastructure/database && make apply"
	@echo "  cd infrastructure/functions-app && make apply"
	@echo "  cd infrastructure/service-bus && make apply"
	@echo "  cd infrastructure/policies && make apply"

##@ Documentation

docs-generate: ## Generate documentation
	@echo "$(YELLOW)Generating documentation...$(RESET)"
	terraform-docs markdown table --output-file README.md --output-mode inject $(INFRASTRUCTURE_PATH)

docs-serve: ## Serve documentation locally
	@echo "$(YELLOW)Starting documentation server...$(RESET)"
	@echo "Open README.md in VS Code or browser"

##@ Security

security: security-scan ## Run security scans (alias)

security-scan: ## Run security scans
	@echo "$(YELLOW)Running security scans...$(RESET)"
	. $(VENV_PATH)/bin/activate && bandit -r . -f json || echo "Security issues found"
	pre-commit run checkov --all-files || echo "Checkov issues found"

security-secrets: ## Scan for secrets
	@echo "$(YELLOW)Scanning for secrets...$(RESET)"
	detect-secrets scan --baseline .secrets.baseline

##@ CI/CD

ci-setup: ## Setup CI environment
	@echo "$(YELLOW)Setting up CI environment...$(RESET)"
	./debug-ci-environment.sh

ci-test: ## Run CI tests
	@echo "$(YELLOW)Running CI tests...$(RESET)"
	@$(MAKE) test-smoke
	@$(MAKE) pre-commit

##@ Development

dev-setup: setup ## Setup development environment (alias)

dev-start: ## Start complete development environment
	@echo "$(GREEN)Starting development environment...$(RESET)"
	@$(MAKE) install-dev
	@$(MAKE) install-functions
	@echo "$(GREEN)Development environment ready$(RESET)"
	@echo "Next steps:"
	@echo "  make functions-start    # Start Azure Functions"
	@echo "  make jupyter-start      # Start Jupyter Lab"
	@echo "  make test-smoke         # Run quick tests"

dev-stop: ## Stop development services
	@echo "$(YELLOW)Stopping development services...$(RESET)"
	@$(MAKE) functions-stop
	@$(MAKE) jupyter-stop

dev-status: status ## Show development status (alias)

##@ Jupyter

jupyter-start: ## Start Jupyter Lab
	@echo "$(YELLOW)Starting Jupyter Lab...$(RESET)"
	$(SCRIPTS_PATH)/start-jupyter.sh

jupyter-stop: ## Stop Jupyter Lab
	@echo "$(YELLOW)Stopping Jupyter Lab...$(RESET)"
	pkill -f "jupyter" || echo "No Jupyter process found"

jupyter-clean: ## Clean Jupyter notebooks
	@echo "$(YELLOW)Cleaning Jupyter notebooks...$(RESET)"
	find notebooks/ -name "*.ipynb" -exec jupyter nbconvert --clear-output --inplace {} \;

##@ Requirements

requirements-update: ## Update requirements files
	@echo "$(YELLOW)Updating requirements...$(RESET)"
	. $(VENV_PATH)/bin/activate && pip-compile requirements/base.txt
	. $(VENV_PATH)/bin/activate && pip-compile requirements/dev.txt
	. $(VENV_PATH)/bin/activate && pip-compile requirements/test.txt

requirements-check: ## Check requirements consistency
	@echo "$(YELLOW)Checking requirements...$(RESET)"
	$(SCRIPTS_PATH)/validate-requirements.sh

requirements-compile: requirements-update ## Compile requirements (alias)

##@ Validation

validate: validate-all ## Run all validations (alias)

validate-all: ## Run all validations
	@echo "$(YELLOW)Running all validations...$(RESET)"
	@$(MAKE) validate-policies
	@$(MAKE) validate-syntax
	@$(MAKE) validate-requirements

validate-policies: ## Validate policy files
	@echo "$(YELLOW)Validating policy files...$(RESET)"
	find policies/ -name "*.json" -exec jq empty {} \;
	@echo "$(GREEN)Policy validation completed$(RESET)"

validate-syntax: ## Validate syntax of all files
	@echo "$(YELLOW)Validating file syntax...$(RESET)"
	find . -name "*.json" -not -path "./.git/*" -exec jq empty {} \;
	find . -name "*.yaml" -o -name "*.yml" -not -path "./.git/*" | xargs -I {} sh -c 'python -c "import yaml; yaml.safe_load(open(\"{}\"))"'

validate-requirements: ## Validate requirements setup
	@echo "$(YELLOW)Validating requirements...$(RESET)"
	$(SCRIPTS_PATH)/validate-requirements.sh

##@ Build

build: build-all ## Build all components (alias)

build-all: ## Build all components
	@echo "$(YELLOW)Building all components...$(RESET)"
	@$(MAKE) install-dev
	@$(MAKE) install-functions
	@$(MAKE) validate-all

build-functions: ## Build Azure Functions
	@echo "$(YELLOW)Building Azure Functions...$(RESET)"
	@$(MAKE) install-functions
	cd $(FUNCTIONS_PATH) && . .venv/bin/activate && python -m pytest tests/ -v

build-docs: ## Build documentation
	@echo "$(YELLOW)Building documentation...$(RESET)"
	@$(MAKE) docs-generate

##@ Deployment

deploy: ## Deploy all components
	@echo "$(YELLOW)Deploying components...$(RESET)"
	@echo "$(RED)Manual deployment required. See deployment guides in docs/$(RESET)"

deploy-functions: ## Deploy Azure Functions
	@echo "$(YELLOW)Deploying Azure Functions...$(RESET)"
	@echo "$(RED)Manual deployment required. Use Azure CLI or VS Code extension$(RESET)"

deploy-infrastructure: ## Deploy infrastructure
	@echo "$(YELLOW)Deploying infrastructure...$(RESET)"
	@$(MAKE) terraform-apply

##@ Monitoring

monitoring-start: ## Start monitoring tools
	@echo "$(YELLOW)Starting monitoring...$(RESET)"
	@echo "Monitoring available through Azure Portal"

monitoring-stop: ## Stop monitoring tools
	@echo "$(YELLOW)Stopping monitoring...$(RESET)"
	@echo "Monitoring managed through Azure"

monitoring-logs: ## Show monitoring logs
	@echo "$(YELLOW)Monitoring logs:$(RESET)"
	@echo "Check Azure Application Insights or Function logs"

##@ Backup

backup-policies: ## Backup policy files
	@echo "$(YELLOW)Backing up policies...$(RESET)"
	tar -czf backup-policies-$(shell date +%Y%m%d-%H%M%S).tar.gz policies/

backup-terraform: ## Backup Terraform state
	@echo "$(YELLOW)Backing up Terraform state...$(RESET)"
	cd $(INFRASTRUCTURE_PATH) && cp terraform.tfstate terraform.tfstate.backup-$(shell date +%Y%m%d-%H%M%S)

backup-all: backup-policies backup-terraform ## Backup all important files

##@ Release

release-prepare: ## Prepare for release
	@echo "$(YELLOW)Preparing release...$(RESET)"
	@$(MAKE) test-all
	@$(MAKE) validate-all
	@$(MAKE) security-scan

release-tag: ## Create release tag
	@echo "$(YELLOW)Creating release tag...$(RESET)"
	@echo "$(RED)Manual tagging required: git tag -a v1.0.0 -m 'Release version 1.0.0'$(RESET)"

release-publish: ## Publish release
	@echo "$(YELLOW)Publishing release...$(RESET)"
	@echo "$(RED)Manual publishing required through GitHub$(RESET)"

##@ Utilities

logs: ## Show application logs
	@echo "$(YELLOW)Application logs:$(RESET)"
	@echo "DevContainer logs: ./scripts/debug-devcontainer.sh --logs"
	@echo "Function logs: Check terminal or Azure portal"
	@echo "Test logs: See test-report.html or htmlcov/"

ps: ## Show running processes
	@echo "$(YELLOW)Project-related processes:$(RESET)"
	@ps aux | grep -E "(func|jupyter|python|azurite)" | grep -v grep || echo "No project processes found"

ports: ## Show used ports
	@echo "$(YELLOW)Project ports:$(RESET)"
	@echo "Azure Functions: 7071 (if running)"
	@echo "Jupyter Lab: 8888 (if running)"
	@echo "Azurite: 10000, 10001, 10002 (if running)"

env: ## Show environment information
	@echo "$(YELLOW)Environment Information:$(RESET)"
	@echo "PROJECT_NAME: $(PROJECT_NAME)"
	@echo "PYTHON_VERSION: $(PYTHON_VERSION)"
	@echo "VENV_PATH: $(VENV_PATH)"
	@echo "FUNCTIONS_PATH: $(FUNCTIONS_PATH)"
	@echo "PWD: $(shell pwd)"
