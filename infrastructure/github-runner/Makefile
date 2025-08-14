# Makefile for GitHub Self-Hosted Runner Deployment
# Requires: Core infrastructure to be deployed first

.PHONY: help init plan apply destroy clean validate fmt check status test-runner prep-deploy full-deploy

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
RESET := \033[0m

# Default target
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "$(CYAN)GitHub Self-Hosted Runner Deployment$(RESET)"
	@echo "$(CYAN)=====================================$(RESET)"
	@echo
	@echo "$(YELLOW)Prerequisites:$(RESET)"
	@echo "  - Core infrastructure must be deployed first"
	@echo "  - GitHub Personal Access Token required"
	@echo "  - terraform.tfvars file configured"
	@echo
	@echo "$(YELLOW)Quick Start:$(RESET)"
	@echo "  1. make prep-deploy    # Copy and edit terraform.tfvars"
	@echo "  2. make full-deploy    # Complete deployment"
	@echo "  3. make test-runner    # Test runner registration"
	@echo
	@echo "$(YELLOW)Available targets:$(RESET)"
	@echo
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(BLUE)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Check if core infrastructure exists
check-prerequisites:
	@echo "$(YELLOW)🔍 Checking prerequisites...$(RESET)"
	@# Check if running with Terraform Cloud or local backend
	@if grep -q "cloud {" terraform.tf 2>/dev/null; then \
		echo "$(CYAN)📡 Using Terraform Cloud backend$(RESET)"; \
	elif grep -q "cloud {" ../core/terraform.tf 2>/dev/null; then \
		echo "$(CYAN)📡 Core infrastructure using Terraform Cloud - skipping local state check$(RESET)"; \
	elif [ ! -f "../core/terraform.tfstate" ] && [ ! -f "../core/.terraform/terraform.tfstate" ] && [ ! -d "../core/.terraform" ]; then \
		echo "$(RED)❌ Error: Core infrastructure not found (local backend)!$(RESET)"; \
		echo "   Please deploy core infrastructure first:"; \
		echo "   $(CYAN)cd ../core && make apply$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Backend configuration validated$(RESET)"

	@# Check terraform.tfvars only for local backend (TF Cloud uses environment variables)
	@if ! grep -q "cloud {" terraform.tf 2>/dev/null; then \
		if [ ! -f "terraform.tfvars" ]; then \
			echo "$(RED)❌ Error: terraform.tfvars not found (local backend)!$(RESET)"; \
			echo "   Run: $(CYAN)make prep-deploy$(RESET) to create it"; \
			exit 1; \
		fi; \
		echo "$(GREEN)✅ terraform.tfvars found$(RESET)"; \
		if ! grep -q "github_token" terraform.tfvars || grep -q "YOUR_GITHUB_TOKEN" terraform.tfvars; then \
			echo "$(RED)❌ Error: GitHub token not configured!$(RESET)"; \
			echo "   Edit terraform.tfvars and add your GitHub Personal Access Token"; \
			exit 1; \
		fi; \
		echo "$(GREEN)✅ GitHub token configured$(RESET)"; \
	else \
		echo "$(CYAN)📡 Using Terraform Cloud - secrets managed via environment variables$(RESET)"; \
		echo "$(YELLOW)💡 Ensure TF_VAR_github_token is set as sensitive variable in workspace$(RESET)"; \
	fi

prep-deploy: ## Prepare deployment by creating terraform.tfvars
	@echo "$(YELLOW)📝 Preparing terraform.tfvars...$(RESET)"
	@if [ ! -f "terraform.tfvars" ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "$(GREEN)✅ Created terraform.tfvars from template$(RESET)"; \
		echo "$(YELLOW)⚠️  Please edit terraform.tfvars and configure:$(RESET)"; \
		echo "   - github_token (your GitHub Personal Access Token)"; \
		echo "   - admin_ssh_public_key (optional, for SSH access)"; \
		echo "   - allowed_management_ips (optional, your IP for SSH)"; \
		echo "$(CYAN)Then run: make full-deploy$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  terraform.tfvars already exists$(RESET)"; \
		echo "   Edit it manually or delete it and run this command again"; \
	fi

init: check-prerequisites ## Initialize Terraform
	@echo "$(YELLOW)🚀 Initializing Terraform for GitHub Runner...$(RESET)"
	@terraform init

plan: check-prerequisites ## Show deployment plan
	@echo "$(YELLOW)📋 Planning GitHub Runner deployment...$(RESET)"
	@terraform plan

apply: check-prerequisites ## Deploy GitHub Runner
	@echo "$(YELLOW)🚀 Deploying GitHub Runner...$(RESET)"
	@terraform apply
	@echo "$(GREEN)✅ GitHub Runner deployment complete!$(RESET)"
	@echo "$(CYAN)Next steps:$(RESET)"
	@echo "  1. Check runner status: $(BLUE)make test-runner$(RESET)"
	@echo "  2. View outputs: $(BLUE)make output$(RESET)"

destroy: ## Destroy GitHub Runner
	@echo "$(RED)🗑️  Destroying GitHub Runner...$(RESET)"
	@echo "$(YELLOW)⚠️  This will remove the runner from GitHub and delete the VM$(RESET)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ]
	@terraform destroy

clean: ## Clean Terraform files
	@echo "$(YELLOW)🧹 Cleaning Terraform files...$(RESET)"
	rm -rf .terraform .terraform.lock.hcl terraform.tfstate.backup
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

validate: ## Validate Terraform configuration
	@echo "$(YELLOW)✅ Validating Terraform configuration...$(RESET)"
	@terraform validate
	@echo "$(GREEN)✅ Configuration is valid$(RESET)"

fmt: ## Format Terraform files
	@echo "$(YELLOW)📝 Formatting Terraform files...$(RESET)"
	@terraform fmt -recursive
	@echo "$(GREEN)✅ Files formatted$(RESET)"

check: validate fmt ## Run validation and formatting
	@echo "$(GREEN)✅ Configuration check complete$(RESET)"

output: ## Show Terraform outputs
	@echo "$(YELLOW)📊 GitHub Runner outputs:$(RESET)"
	@terraform output 2>/dev/null || echo "$(RED)No outputs available (not deployed?)$(RESET)"

status: ## Show current deployment status
	@echo "$(CYAN)📊 GitHub Runner Deployment Status$(RESET)"
	@echo "$(CYAN)==================================$(RESET)"
	@if [ -f "terraform.tfstate" ]; then \
		echo "$(GREEN)✅ Runner state file exists$(RESET)"; \
		echo ""; \
		echo "$(YELLOW)VM Information:$(RESET)"; \
		terraform output 2>/dev/null || echo "$(RED)No outputs available$(RESET)"; \
	else \
		echo "$(RED)❌ Runner not deployed$(RESET)"; \
	fi
	@echo ""
	@echo "$(CYAN)📊 Core Infrastructure Status$(RESET)"
	@echo "$(CYAN)=============================$(RESET)"
	@# Check if core also uses Terraform Cloud backend
	@if grep -q "cloud {" ../core/terraform.tf 2>/dev/null; then \
		echo "$(CYAN)📡 Core infrastructure using Terraform Cloud backend$(RESET)"; \
		echo "$(YELLOW)💡 Core infrastructure status checked via Terraform Cloud workspace$(RESET)"; \
	elif [ -f "../core/terraform.tfstate" ] || [ -f "../core/.terraform/terraform.tfstate" ]; then \
		echo "$(GREEN)✅ Core infrastructure deployed (local backend)$(RESET)"; \
	else \
		echo "$(RED)❌ Core infrastructure not found (local backend)$(RESET)"; \
	fi

test-runner: ## Test GitHub runner connectivity and registration
	@echo "$(YELLOW)🧪 Testing GitHub Runner...$(RESET)"
	@if [ -f "terraform.tfstate" ]; then \
		VM_IP=$$(terraform output -raw vm_public_ip 2>/dev/null); \
		if [ -n "$$VM_IP" ]; then \
			echo "$(CYAN)🌐 Runner VM IP: $$VM_IP$(RESET)"; \
			echo "$(YELLOW)Testing VM connectivity...$(RESET)"; \
			if ping -c 3 $$VM_IP >/dev/null 2>&1; then \
				echo "$(GREEN)✅ VM is reachable$(RESET)"; \
			else \
				echo "$(RED)❌ VM not reachable$(RESET)"; \
			fi; \
			echo "$(YELLOW)💡 To check runner status:$(RESET)"; \
			echo "  1. Go to your GitHub repository"; \
			echo "  2. Settings → Actions → Runners"; \
			echo "  3. Look for 'azure-vnet-runner-dev' (should be 'Idle')"; \
		else \
			echo "$(RED)❌ Could not get VM IP$(RESET)"; \
		fi; \
	else \
		echo "$(RED)❌ Runner not deployed$(RESET)"; \
		echo "   Run: $(CYAN)make apply$(RESET)"; \
	fi

ssh: ## SSH to the GitHub runner VM (requires SSH key configured)
	@echo "$(YELLOW)🔐 Connecting to GitHub Runner VM...$(RESET)"
	@if [ -f "terraform.tfstate" ]; then \
		VM_IP=$$(terraform output -raw vm_public_ip 2>/dev/null); \
		if [ -n "$$VM_IP" ]; then \
			echo "$(CYAN)Connecting to: $$VM_IP$(RESET)"; \
			ssh azureuser@$$VM_IP; \
		else \
			echo "$(RED)❌ Could not get VM IP$(RESET)"; \
		fi; \
	else \
		echo "$(RED)❌ Runner not deployed$(RESET)"; \
	fi

logs: ## View GitHub runner service logs (requires SSH access)
	@echo "$(YELLOW)📋 Viewing GitHub Runner logs...$(RESET)"
	@if [ -f "terraform.tfstate" ]; then \
		VM_IP=$$(terraform output -raw vm_public_ip 2>/dev/null); \
		if [ -n "$$VM_IP" ]; then \
			echo "$(CYAN)Connecting to: $$VM_IP$(RESET)"; \
			ssh azureuser@$$VM_IP "sudo journalctl -u actions.runner.* -f --no-pager"; \
		else \
			echo "$(RED)❌ Could not get VM IP$(RESET)"; \
		fi; \
	else \
		echo "$(RED)❌ Runner not deployed$(RESET)"; \
	fi

# Workflow targets
full-deploy: init plan apply status ## Complete deployment workflow
	@echo "$(GREEN)🎉 GitHub Runner deployment completed!$(RESET)"

quick-deploy: check-prerequisites apply status test-runner ## Quick deployment (skip init/plan)
	@echo "$(GREEN)🎉 Quick deployment completed!$(RESET)"

full-clean: destroy clean ## Complete cleanup: destroy -> clean
	@echo "$(GREEN)🧹 Full cleanup completed!$(RESET)"

# Development targets
dev-plan: ## Development: quick plan without full checks
	@terraform plan

dev-apply: ## Development: quick apply without checks
	@terraform apply -auto-approve

# Show GitHub runner service status on VM
runner-status: ## Check GitHub Actions runner service status on VM
	@echo "$(YELLOW)📊 Checking runner service status...$(RESET)"
	@if [ -f "terraform.tfstate" ]; then \
		VM_IP=$$(terraform output -raw vm_public_ip 2>/dev/null); \
		if [ -n "$$VM_IP" ]; then \
			ssh azureuser@$$VM_IP "sudo systemctl status actions.runner.* --no-pager"; \
		else \
			echo "$(RED)❌ Could not get VM IP$(RESET)"; \
		fi; \
	else \
		echo "$(RED)❌ Runner not deployed$(RESET)"; \
	fi
