#!/bin/bash
# Terraform Cloud Setup Script for Azure Policy Project
# This script helps set up Terraform Cloud organization and workspaces

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

print_info() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if .env file exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from template..."
    if [ -f .env.template ]; then
        cp .env.template .env
        print_status "Copied .env.template to .env"
        print_info "Please edit .env file with your actual values before continuing"
        exit 1
    else
        print_error ".env.template not found. Please create .env file manually."
        exit 1
    fi
fi

# Load environment variables
source .env

# Validate required environment variables
required_vars=(
    "TF_API_TOKEN"
    "TF_CLOUD_ORGANIZATION"
    "ARM_CLIENT_ID"
    "ARM_CLIENT_SECRET"
    "ARM_SUBSCRIPTION_ID"
    "ARM_TENANT_ID"
)

print_info "Validating environment variables..."
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ] || [[ "${!var}" == "your_"*"_here" ]]; then
        print_error "Environment variable $var is not set or still has template value"
        print_error "Please update your .env file with actual values"
        exit 1
    fi
done

print_status "All required environment variables are set"

# Check if terraform CLI is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform CLI is not installed. Please install it first."
    exit 1
fi

# Check if terraform is logged in to Terraform Cloud
print_info "Checking Terraform Cloud authentication..."
if ! terraform login -json 2>/dev/null | grep -q "true"; then
    print_warning "Not logged in to Terraform Cloud. Starting login process..."
    terraform login
fi

print_status "Terraform Cloud authentication verified"

# Navigate to terraform directory
cd "$(dirname "$0")/../infrastructure/terraform"

# Initialize Terraform with the new backend
print_info "Initializing Terraform with Terraform Cloud backend..."
terraform init

# Create workspaces if they don't exist
workspaces=("azure-policy-dev" "azure-policy-staging" "azure-policy-prod")

for workspace in "${workspaces[@]}"; do
    print_info "Checking workspace: $workspace"

    # Try to select the workspace
    if terraform workspace select "$workspace" 2>/dev/null; then
        print_status "Workspace $workspace already exists"
    else
        print_info "Creating workspace: $workspace"
        terraform workspace new "$workspace"
        print_status "Created workspace: $workspace"
    fi
done

# Switch back to default workspace
terraform workspace select default || terraform workspace select azure-policy-dev

print_status "Terraform Cloud setup complete!"
echo ""
print_info "Next steps:"
echo "1. Go to https://app.terraform.io/app/$TF_CLOUD_ORGANIZATION"
echo "2. Configure environment variables in each workspace:"
echo "   - ARM_CLIENT_ID"
echo "   - ARM_CLIENT_SECRET (mark as sensitive)"
echo "   - ARM_SUBSCRIPTION_ID"
echo "   - ARM_TENANT_ID"
echo "3. Set up any additional Terraform variables as needed"
echo "4. Configure GitHub Actions with TF_API_TOKEN secret"
echo ""
print_status "Your Terraform Cloud organization 'azure-policy-cloud' is ready!"
