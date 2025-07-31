#!/usr/bin/env bash
# Terraform Cloud Setup Script for Azure Policy Project
# This script helps you set up Terraform Cloud for the Azure Policy project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_header "Checking prerequisites..."

    if ! command -v terraform >/dev/null 2>&1; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        print_error "jq is not installed. Please install it first."
        exit 1
    fi

    print_status "Prerequisites check passed."
}

# Get organization name from user
get_organization_name() {
    echo ""
    print_header "Organization Configuration"
    echo "Current organization in main.tf: azure-policy-cloud"
    echo ""
    echo "Options:"
    echo "1. Use existing organization (enter your org name)"
    echo "2. Create new organization 'azure-policy-cloud'"
    echo "3. Keep current setting"
    echo ""

    read -p "Enter your choice (1-3) or organization name: " choice

    case $choice in
        1)
            read -p "Enter your existing organization name: " ORG_NAME
            ;;
        2)
            ORG_NAME="azure-policy-cloud"
            print_warning "You'll need to create this organization at app.terraform.io"
            ;;
        3)
            ORG_NAME="azure-policy-cloud"
            ;;
        *)
            # Assume they entered an org name directly
            ORG_NAME="$choice"
            ;;
    esac

    print_status "Using organization: $ORG_NAME"

    # Update main.tf if different from current
    if [ "$ORG_NAME" != "azure-policy-cloud" ]; then
        print_status "Updating organization name in main.tf..."
        sed -i "s/organization = \"azure-policy-cloud\"/organization = \"$ORG_NAME\"/" infrastructure/terraform/main.tf
        print_status "Updated main.tf with organization: $ORG_NAME"
    fi
}

# Display workspace setup instructions
show_workspace_setup() {
    print_header "Terraform Cloud Workspace Setup"
    echo ""
    echo "You need to create these workspaces in Terraform Cloud:"
    echo ""
    echo "1. 🏗️  azure-policy-cloud-dev"
    echo "   - Auto Apply: ✅ Enabled (for rapid development)"
    echo "   - Working Directory: infrastructure/terraform"
    echo "   - Tags (comma-separated): azure-policy, dev, development"
    echo ""
    echo "2. 🧪 azure-policy-cloud-staging"
    echo "   - Auto Apply: ❌ Disabled (manual approval)"
    echo "   - Working Directory: infrastructure/terraform"
    echo "   - Tags (comma-separated): azure-policy, staging"
    echo ""
    echo "3. 🚀 azure-policy-cloud-prod"
    echo "   - Auto Apply: ❌ Disabled (manual approval)"
    echo "   - Working Directory: infrastructure/terraform"
    echo "   - Tags (comma-separated): azure-policy, prod, production"
    echo ""
}

# Display environment variables setup
show_environment_variables() {
    print_header "Environment Variables Setup"
    echo ""
    echo "For each workspace, add these environment variables:"
    echo ""
    echo "🔐 Environment Variables (Mark as Sensitive):"
    echo "   ARM_CLIENT_ID=<your-service-principal-client-id>"
    echo "   ARM_CLIENT_SECRET=<your-service-principal-secret> (Sensitive)"
    echo "   ARM_SUBSCRIPTION_ID=<your-azure-subscription-id>"
    echo "   ARM_TENANT_ID=<your-azure-tenant-id>"
    echo ""
    echo "⚙️  Terraform Variables:"
    echo "   environment = dev|staging|prod (set per workspace)"
    echo "   location = \"East US\" (or your preferred region)"
    echo "   cost_center = \"development\" (or your cost center)"
    echo "   owner = \"platform-team\" (or your team name)"
    echo ""
}

# Display GitHub secrets setup
show_github_secrets() {
    print_header "GitHub Secrets Setup"
    echo ""
    echo "Add these secrets to your GitHub repository:"
    echo "Repository Settings → Secrets and variables → Actions"
    echo ""
    echo "Required secrets:"
    echo "   ARM_CLIENT_ID=<your-service-principal-client-id>"
    echo "   ARM_CLIENT_SECRET=<your-service-principal-secret>"
    echo "   ARM_SUBSCRIPTION_ID=<your-azure-subscription-id>"
    echo "   ARM_TENANT_ID=<your-azure-tenant-id>"
    echo "   TF_API_TOKEN=<your-terraform-cloud-api-token>"
    echo ""
    echo "To get your Terraform Cloud API token:"
    echo "1. Go to Terraform Cloud → User Settings → Tokens"
    echo "2. Create a new API token"
    echo "3. Copy and add as TF_API_TOKEN in GitHub secrets"
    echo ""
}

# Generate terraform.tfvars
generate_tfvars() {
    print_header "Generating terraform.tfvars"

    if [ -f "infrastructure/terraform/terraform.tfvars" ]; then
        print_warning "terraform.tfvars already exists. Creating backup..."
        cp infrastructure/terraform/terraform.tfvars infrastructure/terraform/terraform.tfvars.backup
    fi

    cat > infrastructure/terraform/terraform.tfvars << 'EOF'
# Azure Policy Infrastructure - Development Environment
# Generated by setup-terraform-cloud.sh

# Environment Configuration
environment = "dev"
location    = "East US"

# Tagging
cost_center = "development"
owner       = "platform-team"

# Network Configuration
vnet_address_space = ["10.0.0.0/16"]

# Feature Toggles (optimized for development)
enable_network_watcher       = true
enable_flow_logs            = false  # Disabled to reduce costs in dev
enable_policy_assignments   = true
EOF

    print_status "Created terraform.tfvars for development environment"
    print_warning "Remember to customize values for staging and production!"
}

# Test Terraform initialization
test_terraform_init() {
    print_header "Testing Terraform Configuration"

    cd infrastructure/terraform

    print_status "Running terraform init..."
    if terraform init; then
        print_status "✅ Terraform initialization successful"
    else
        print_error "❌ Terraform initialization failed"
        print_error "Please check your Terraform Cloud setup and try again"
        exit 1
    fi

    print_status "Running terraform validate..."
    if terraform validate; then
        print_status "✅ Terraform configuration is valid"
    else
        print_error "❌ Terraform validation failed"
        exit 1
    fi

    cd ../..
}

# Main execution
main() {
    echo "🚀 Terraform Cloud Setup for Azure Policy Project"
    echo "=================================================="
    echo ""

    check_prerequisites
    get_organization_name
    show_workspace_setup

    echo ""
    read -p "Press Enter to continue to environment variables setup..."
    show_environment_variables

    echo ""
    read -p "Press Enter to continue to GitHub secrets setup..."
    show_github_secrets

    echo ""
    read -p "Generate terraform.tfvars file? (y/n): " generate_vars
    if [[ $generate_vars =~ ^[Yy]$ ]]; then
        generate_tfvars
    fi

    echo ""
    read -p "Test Terraform configuration? (y/n): " test_config
    if [[ $test_config =~ ^[Yy]$ ]]; then
        test_terraform_init
    fi

    echo ""
    print_header "Setup Complete!"
    echo ""
    echo "Next steps:"
    echo "1. 🌐 Go to https://app.terraform.io and create/verify your organization"
    echo "2. 🏗️  Create the three workspaces (dev, staging, prod)"
    echo "3. ⚙️  Configure environment variables in each workspace"
    echo "4. 🔐 Add GitHub secrets to your repository"
    echo "5. 🧪 Test with: GitHub Actions → Terraform Validate workflow"
    echo "6. 🚀 Deploy with: GitHub Actions → Terraform Apply workflow"
    echo ""
    echo "📚 For detailed instructions, see: docs/TERRAFORM_CLOUD_SETUP.md"
    echo ""
}

# Run the main function
main "$@"
