# Terraform Makefile for Service Bus Infrastructure
# This Makefile handles Terraform operations for the service bus workspace

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
	@echo "$(GREEN)Terraform Service Bus Infrastructure$(RESET)"
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
	@echo "$(RED)WARNING: This will destroy all Service Bus resources!$(RESET)"
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
	@echo "$(BLUE)Service Bus Infrastructure Status$(RESET)"
	@echo "================================="
	@if [ -f "terraform.tfstate" ]; then \
		echo "$(GREEN)✅ Service Bus deployed$(RESET)"; \
		echo ""; \
		echo "$(YELLOW)Resources:$(RESET)"; \
		terraform output service_bus_namespace_name 2>/dev/null | sed 's/"//g' | xargs -I {} echo "  Namespace: {}"; \
		terraform output service_bus_sku 2>/dev/null | sed 's/"//g' | xargs -I {} echo "  SKU: {}"; \
		terraform output queue_names 2>/dev/null && echo ""; \
		terraform output topic_names 2>/dev/null; \
	else \
		echo "$(RED)❌ Service Bus not deployed$(RESET)"; \
	fi

# Workflow shortcuts
quick-deploy: init plan apply output ## Quick deployment: init -> plan -> apply -> output
full-clean: destroy clean ## Full cleanup: destroy -> clean

# Development helpers
check: validate fmt ## Check configuration: validate -> fmt
dev-deploy: check apply status ## Development deployment: check -> apply -> status
