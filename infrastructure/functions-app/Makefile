# Makefile for Azure Function App Deployment
# Requires: app-service infrastructure to be deployed first

.PHONY: help init plan apply destroy clean validate fmt check status

# Default target
help: ## Show this help message
	@echo "Azure Function App Deployment Commands"
	@echo "======================================="
	@echo
	@echo "Prerequisites:"
	@echo "  - App Service infrastructure must be deployed first"
	@echo "  - Run: make terraform-app-service-apply (from project root)"
	@echo
	@echo "Available targets:"
	@echo
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Check if app-service infrastructure is deployed (remote state only)
check-prerequisites:
	@echo "ℹ️  Skipping local terraform.tfstate check (using remote state backend)"
	@echo "✅ Assuming App Service infrastructure is deployed via Terraform Cloud"

init: check-prerequisites ## Initialize Terraform
	@echo "🚀 Initializing Terraform for Function App deployment..."
	terraform init

plan: check-prerequisites ## Show deployment plan
	@echo "📋 Planning Function App deployment..."
	terraform plan

apply: check-prerequisites ## Deploy Function App
	@echo "🚀 Deploying Function App..."
	terraform apply -auto-approve

destroy: ## Destroy Function App (keeps app-service infrastructure)
	@echo "🗑️  Destroying Function App..."
	@echo "⚠️  This will destroy the Function App but keep the app-service infrastructure"
	terraform destroy -auto-approve

clean: ## Clean Terraform files
	@echo "🧹 Cleaning Terraform files..."
	rm -rf .terraform .terraform.lock.hcl terraform.tfstate.backup

validate: ## Validate Terraform configuration
	@echo "✅ Validating Terraform configuration..."
	terraform validate

fmt: ## Format Terraform files
	@echo "📝 Formatting Terraform files..."
	terraform fmt -recursive

check: validate fmt ## Run validation and formatting
	@echo "✅ Configuration check complete"

status: ## Show current deployment status
	@echo "📊 Function App Deployment Status"
	@echo "================================="
	@if [ -f "terraform.tfstate" ]; then \
		echo "✅ Function App state file exists"; \
		terraform output 2>/dev/null || echo "No outputs available"; \
	else \
		echo "❌ Function App not deployed"; \
	fi
	@echo
	@echo "📊 App Service Infrastructure Status"
	@echo "====================================="
	@if [ -f "../app-service/terraform.tfstate" ]; then \
		echo "✅ App Service infrastructure deployed"; \
	else \
		echo "❌ App Service infrastructure not found"; \
	fi

# Quick deployment workflow
quick-deploy: init plan apply status ## Quick deployment: init -> plan -> apply -> status

# Full cleanup (Function App only)
full-clean: destroy clean ## Full cleanup: destroy -> clean
