#!/bin/bash

# Azure Policy Infrastructure Cleanup Script
# This script will help clean up all Azure resources and reset Terraform state

set -e

echo "🗑️  Azure Policy Infrastructure Cleanup Script"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Please install it first."
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    print_error "Terraform not found. Please install it first."
    exit 1
fi

print_status "Prerequisites check passed"
echo ""

# Check Azure login
echo "Checking Azure authentication..."
if ! az account show &> /dev/null; then
    print_error "Not logged into Azure. Please run 'az login' first."
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_status "Logged into Azure subscription: $SUBSCRIPTION_ID"
echo ""

# Confirmation prompt
print_warning "This script will DELETE ALL Azure resources related to the azure-policy project!"
print_warning "This action cannot be undone!"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup process..."
echo ""

# Step 1: List and delete resource groups
echo "🔍 Finding resource groups..."
RG_LIST=$(az group list --query "[?contains(name, 'azpolicy') || contains(name, 'rg-azurepolicy')].name" -o tsv)

if [ -z "$RG_LIST" ]; then
    print_status "No resource groups found matching 'azpolicy' pattern"
else
    echo "Found resource groups:"
    echo "$RG_LIST"
    echo ""

    for rg in $RG_LIST; do
        echo "🗑️  Deleting resource group: $rg"
        az group delete --name "$rg" --yes --no-wait
        print_status "Deletion initiated for $rg (running in background)"
    done
fi

echo ""

# Step 2: Clean up local Terraform files
echo "🧹 Cleaning up local Terraform files..."

# Remove .terraform directories
find infrastructure/ -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
find infrastructure/ -name ".terraform.lock.hcl" -delete 2>/dev/null || true

# Remove any local state files (should not exist with remote backend, but just in case)
find infrastructure/ -name "terraform.tfstate*" -delete 2>/dev/null || true

print_status "Local Terraform files cleaned"
echo ""

# Step 3: Check for remaining resources
echo "🔍 Checking for any remaining resources with project tag..."
REMAINING_RESOURCES=$(az resource list --tag Project=azurepolicy --query "[].{Name:name, Type:type, ResourceGroup:resourceGroup}" -o tsv 2>/dev/null || echo "")

if [ -z "$REMAINING_RESOURCES" ]; then
    print_status "No tagged resources found"
else
    print_warning "Found remaining resources with Project=azurepolicy tag:"
    echo "$REMAINING_RESOURCES"
    echo ""
    print_warning "You may need to delete these manually"
fi

echo ""

# Step 4: Reinitialize Terraform modules
echo "🔄 Reinitializing Terraform modules..."

for module in infrastructure policies functions; do
    if [ -d "infrastructure/$module" ]; then
        echo "Initializing $module module..."
        cd "infrastructure/$module"

        # Initialize without backend for validation
        if terraform init -backend=false > /dev/null 2>&1; then
            print_status "$module module initialized successfully"

            # Validate configuration
            if terraform validate > /dev/null 2>&1; then
                print_status "$module module configuration is valid"
            else
                print_warning "$module module configuration has validation errors"
            fi
        else
            print_error "Failed to initialize $module module"
        fi

        cd ../..
    else
        print_warning "Module directory infrastructure/$module not found"
    fi
done

echo ""

# Step 5: Wait for resource group deletions to complete
echo "⏳ Checking resource group deletion status..."
sleep 10  # Give Azure a moment to start processing

for rg in $RG_LIST; do
    if az group show --name "$rg" &> /dev/null; then
        print_warning "Resource group $rg still exists (deletion may take several minutes)"
    else
        print_status "Resource group $rg successfully deleted"
    fi
done

echo ""
echo "🎉 Cleanup process completed!"
echo ""
echo "Next steps:"
echo "1. Verify all resource groups are deleted in Azure Portal"
echo "2. Reset or recreate Terraform Cloud workspaces"
echo "3. Test GitHub Actions workflows"
echo ""
print_warning "Resource group deletions may take several minutes to complete."
print_warning "Check Azure Portal to confirm all resources are deleted."
echo ""
