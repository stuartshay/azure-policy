# Terraform Makefile for Core Infrastructure
# This Makefile handles Terraform operations for the core workspace

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
RESET := \033[0m

# Path to .env file (in project root)
ENV_FILE := ../../.env

# Default target
.DEFAULT_GOAL := help

.PHONY: help init plan apply destroy validate fmt output login clean

help: ## Display this help message
	@echo "$(GREEN)Terraform Core Infrastructure$(RESET)"
	@echo ""
	@echo "$(YELLOW)Usage: make <target>$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(BLUE)%-15s$(RESET) %s\n", $$1, $$2}'
	@echo ""

login: ## Show Terraform Cloud authentication status
	@echo "$(YELLOW)Checking Terraform Cloud authentication...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		. $(ENV_FILE) && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		echo "$(GREEN)Token loaded from .env$(RESET)" && \
		echo "Organization: $$(grep TF_CLOUD_ORGANIZATION $(ENV_FILE) | cut -d'=' -f2)" && \
		echo "Workspace: azure-policy-core" && \
		echo "Token: $${TF_TOKEN_app_terraform_io:0:20}..."; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

init: ## Initialize Terraform
	@echo "$(YELLOW)Initializing Terraform for Core workspace...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform init; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

plan: ## Plan Terraform changes
	@echo "$(YELLOW)Planning Terraform changes for Core workspace...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform plan; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

apply: ## Apply Terraform changes
	@echo "$(YELLOW)Applying Terraform changes for Core workspace...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform apply; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

destroy: ## Destroy Terraform resources
	@echo "$(RED)Destroying Terraform resources for Core workspace...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform destroy; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

validate: ## Validate Terraform configuration
	@echo "$(YELLOW)Validating Terraform configuration...$(RESET)"
	@terraform validate

fmt: ## Format Terraform files
	@echo "$(YELLOW)Formatting Terraform files...$(RESET)"
	@terraform fmt -recursive

output: ## Show Terraform outputs
	@echo "$(YELLOW)Terraform outputs for Core workspace:$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform output; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

clean: ## Clean Terraform files
	@echo "$(YELLOW)Cleaning Terraform files...$(RESET)"
	rm -rf .terraform .terraform.lock.hcl
	@echo "$(GREEN)Cleanup completed$(RESET)"
