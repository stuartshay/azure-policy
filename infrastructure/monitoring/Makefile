# Terraform Makefile for Monitoring Infrastructure
# This Makefile handles Terraform operations for the monitoring workspace

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

.PHONY: help init plan apply destroy validate fmt output login clean status

help: ## Display this help message
	@echo "$(GREEN)Terraform Monitoring Infrastructure$(RESET)"
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
		echo "Workspace: azure-policy-monitoring" && \
		echo "Token: $${TF_TOKEN_app_terraform_io:0:20}..."; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

init: ## Initialize Terraform
	@echo "$(YELLOW)Initializing Terraform for Monitoring workspace...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform init; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

plan: ## Plan Terraform changes
	@echo "$(YELLOW)Planning Terraform changes for Monitoring workspace...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform plan; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

apply: ## Apply Terraform changes
	@echo "$(YELLOW)Applying Terraform changes for Monitoring workspace...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform apply; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

destroy: ## Destroy Terraform resources
	@echo "$(RED)Destroying Terraform resources for Monitoring workspace...$(RESET)"
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
	@echo "$(YELLOW)Terraform outputs for Monitoring workspace:$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform output; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

status: ## Show monitoring deployment status
	@echo "$(GREEN)=== Monitoring Infrastructure Status ===$(RESET)"
	@echo "Workspace: azure-policy-monitoring"
	@echo "Environment: $$(grep 'environment.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"
	@echo "Location: $$(grep 'location.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"
	@echo "Workload: $$(grep 'workload.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"
	@echo ""
	@echo "$(BLUE)Configuration:$(RESET)"
	@echo "Log Analytics SKU: $$(grep 'log_analytics_sku.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"
	@echo "Log Retention: $$(grep 'log_retention_days.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"') days"
	@echo "Sampling: $$(grep 'sampling_percentage.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')%"
	@echo ""
	@echo "$(BLUE)Features Enabled:$(RESET)"
	@echo "Log Alerts: $$(grep 'enable_log_alerts.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"
	@echo "Smart Detection: $$(grep 'enable_smart_detection.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"
	@echo "Workbook: $$(grep 'enable_workbook.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"
	@echo "Budget Alerts: $$(grep 'enable_budget_alerts.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"

clean: ## Clean Terraform files
	@echo "$(YELLOW)Cleaning Terraform files...$(RESET)"
	rm -rf .terraform .terraform.lock.hcl
	@echo "$(GREEN)Cleanup completed$(RESET)"

test-alerts: ## Test alert configuration (dry run)
	@echo "$(YELLOW)Testing alert configuration...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform plan -target=module.monitoring.azurerm_monitor_action_group.main && \
		terraform plan -target=module.monitoring.azurerm_monitor_metric_alert.function_app_cpu; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

show-config: ## Show current monitoring configuration
	@echo "$(GREEN)=== Monitoring Configuration ===$(RESET)"
	@echo ""
	@echo "$(BLUE)Alert Thresholds:$(RESET)"
	@echo "CPU: $$(grep 'cpu_threshold.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')%"
	@echo "Memory: $$(grep 'memory_threshold.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')%"
	@echo "Errors: $$(grep 'error_threshold.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"') errors"
	@echo "Response Time: $$(grep 'response_time_threshold.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"') seconds"
	@echo "Availability: $$(grep 'availability_threshold.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')%"
	@echo ""
	@echo "$(BLUE)Monitored Functions:$(RESET)"
	@echo "Basic Function: $$(grep 'monitor_basic_function.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"
	@echo "Advanced Function: $$(grep 'monitor_advanced_function.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"
	@echo "Infrastructure Function: $$(grep 'monitor_infrastructure_function.*=' terraform.tfvars | cut -d'=' -f2 | tr -d ' \"')"

show-outputs: output ## Alias for output command

integration-test: ## Run integration test (requires deployed infrastructure)
	@echo "$(YELLOW)Running monitoring integration test...$(RESET)"
	@echo "$(BLUE)Checking Log Analytics Workspace...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		WORKSPACE_NAME=$$(terraform output -raw log_analytics_workspace_name 2>/dev/null) && \
		if [ -n "$$WORKSPACE_NAME" ]; then \
			echo "$(GREEN)✓ Log Analytics Workspace: $$WORKSPACE_NAME$(RESET)"; \
		else \
			echo "$(RED)✗ Log Analytics Workspace not found$(RESET)"; \
		fi && \
		APP_INSIGHTS_NAME=$$(terraform output -raw application_insights_name 2>/dev/null) && \
		if [ -n "$$APP_INSIGHTS_NAME" ]; then \
			echo "$(GREEN)✓ Application Insights: $$APP_INSIGHTS_NAME$(RESET)"; \
		else \
			echo "$(RED)✗ Application Insights not found$(RESET)"; \
		fi; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

# Development helpers
dev-apply: ## Apply with auto-approve for development
	@echo "$(YELLOW)Applying Terraform changes (auto-approve)...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform apply -auto-approve; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi

dev-destroy: ## Destroy with auto-approve for development
	@echo "$(RED)Destroying Terraform resources (auto-approve)...$(RESET)"
	@if [ -f $(ENV_FILE) ]; then \
		set -a && . $(ENV_FILE) && set +a && \
		export TF_TOKEN_app_terraform_io="$$TF_API_TOKEN" && \
		terraform destroy -auto-approve; \
	else \
		echo "$(RED)Error: .env file not found at $(ENV_FILE)$(RESET)"; \
		exit 1; \
	fi
