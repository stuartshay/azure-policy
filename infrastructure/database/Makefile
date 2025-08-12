# Terraform Makefile for Database Infrastructure
# This Makefile handles Terraform operations for the database workspace

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
RESET := \033[0m

# Environment file path (from project root)
ENV_FILE := ../../.env

# Load environment variables if .env file exists
ifneq (,$(wildcard $(ENV_FILE)))
	include $(ENV_FILE)
	export
endif

.PHONY: help init plan apply destroy validate fmt output login clean status

help: ## Display this help message
	@echo "$(GREEN)Terraform Database Infrastructure$(RESET)"
	@echo ""
	@echo "$(YELLOW)Usage: make <target>$(RESET)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Initialize Terraform
	@echo "$(YELLOW)Initializing Terraform...$(RESET)"
	terraform init

plan: ## Plan Terraform changes
	@echo "$(YELLOW)Planning Terraform changes...$(RESET)"
	terraform plan

apply: ## Apply Terraform changes
	@echo "$(YELLOW)Applying Terraform changes...$(RESET)"
	terraform apply

destroy: ## Destroy all resources
	@echo "$(RED)WARNING: This will destroy all Database resources!$(RESET)"
	@echo "$(YELLOW)Press Ctrl+C within 5 seconds to cancel...$(RESET)"
	@sleep 5
	terraform destroy

validate: ## Validate Terraform configuration
	@echo "$(YELLOW)Validating Terraform configuration...$(RESET)"
	terraform validate

fmt: ## Format Terraform files
	@echo "$(YELLOW)Formatting Terraform files...$(RESET)"
	terraform fmt -recursive

output: ## Show Terraform outputs
	@echo "$(YELLOW)Terraform outputs:$(RESET)"
	@terraform output

login: ## Login to Azure CLI
	@echo "$(YELLOW)Logging in to Azure CLI...$(RESET)"
	az login

clean: ## Clean Terraform files
	@echo "$(YELLOW)Cleaning Terraform files...$(RESET)"
	rm -rf .terraform .terraform.lock.hcl terraform.tfstate.backup

status: ## Show current deployment status
	@echo "$(BLUE)Database Infrastructure Status$(RESET)"
	@echo "================================="
	@if [ -f "terraform.tfstate" ]; then \
		echo "$(GREEN)✅ Database deployed$(RESET)"; \
		echo ""; \
		echo "$(YELLOW)Resources:$(RESET)"; \
		terraform output postgresql_server_name 2>/dev/null | sed 's/"//g' | xargs -I {} echo "  PostgreSQL Server: {}"; \
		terraform output postgresql_server_version 2>/dev/null | sed 's/"//g' | xargs -I {} echo "  Version: PostgreSQL {}"; \
		terraform output database_name 2>/dev/null | sed 's/"//g' | xargs -I {} echo "  Database: {}"; \
		echo ""; \
		echo "$(YELLOW)Configuration:$(RESET)"; \
		terraform output server_configuration 2>/dev/null | grep -E "(sku_name|storage_mb)" | sed 's/[",]//g' | sed 's/^/  /'; \
		echo ""; \
		echo "$(YELLOW)Cost Optimization:$(RESET)"; \
		terraform output cost_optimization_info 2>/dev/null | grep -E "(tier|estimated_monthly_cost)" | sed 's/[",]//g' | sed 's/^/  /'; \
	else \
		echo "$(RED)❌ Database not deployed$(RESET)"; \
	fi

# Connection testing
test-connection: ## Test database connection (requires psql)
	@echo "$(YELLOW)Testing database connection...$(RESET)"
	@if command -v psql >/dev/null 2>&1; then \
		echo "$(BLUE)Attempting to connect to PostgreSQL...$(RESET)"; \
		terraform output connection_string_full 2>/dev/null | sed 's/"//g' | xargs -I {} psql {} -c "SELECT version();" || echo "$(RED)Connection failed. Check network connectivity and credentials.$(RESET)"; \
	else \
		echo "$(RED)psql not found. Install PostgreSQL client to test connection.$(RESET)"; \
	fi

# Security checks
security-check: ## Check security configuration
	@echo "$(BLUE)Database Security Configuration$(RESET)"
	@echo "================================="
	@echo "$(YELLOW)SSL Configuration:$(RESET)"
	@terraform output server_configuration 2>/dev/null | grep -E "(ssl_enforcement|ssl_minimal_tls)" | sed 's/[",]//g' | sed 's/^/  /'
	@echo ""
	@echo "$(YELLOW)Network Security:$(RESET)"
	@terraform output server_configuration 2>/dev/null | grep "public_network_access" | sed 's/[",]//g' | sed 's/^/  /'
	@terraform output network_configuration 2>/dev/null | grep "vnet_integration" | sed 's/[",]//g' | sed 's/^/  /'

# Cost analysis
cost-info: ## Show cost optimization information
	@echo "$(BLUE)Database Cost Information$(RESET)"
	@echo "================================="
	@terraform output cost_optimization_info 2>/dev/null || echo "$(RED)No cost information available$(RESET)"

# Workflow shortcuts
quick-deploy: init plan apply output ## Quick deployment: init -> plan -> apply -> output
full-clean: destroy clean ## Full cleanup: destroy -> clean

# Development helpers
check: validate fmt ## Check configuration: validate -> fmt
dev-deploy: check apply status ## Development deployment: check -> apply -> status
full-status: status security-check cost-info ## Full status: deployment -> security -> cost

# Database management helpers
show-connection: ## Show connection string template (safe)
	@echo "$(YELLOW)Connection String Template:$(RESET)"
	@terraform output connection_string_template 2>/dev/null | sed 's/"//g' || echo "$(RED)Database not deployed$(RESET)"

show-components: ## Show connection components
	@echo "$(YELLOW)Connection Components:$(RESET)"
	@terraform output connection_components 2>/dev/null | grep -E "(host|port|database|username)" | sed 's/[",]//g' | sed 's/^/  /' || echo "$(RED)Database not deployed$(RESET)"
