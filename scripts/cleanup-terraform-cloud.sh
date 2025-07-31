#!/bin/bash

# Terraform Cloud Organization Cleanup Script
# This script will completely clean up the azure-policy-cloud organization

set -e

echo "🧹 Terraform Cloud Organization Cleanup Script"
echo "==============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Configuration
ORG_NAME="azure-policy-cloud"

# Check if TF_API_TOKEN is set
if [ -z "$TF_API_TOKEN" ]; then
    print_error "TF_API_TOKEN environment variable is not set"
    echo "Please set your Terraform Cloud API token:"
    echo "export TF_API_TOKEN=your_token_here"
    echo ""
    echo "You can create a token at: https://app.terraform.io/app/settings/tokens"
    exit 1
fi

print_status "Terraform Cloud API token found"
echo ""

# Test API connection
echo "Testing Terraform Cloud API connection..."
if curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
        -H "Content-Type: application/vnd.api+json" \
        "https://app.terraform.io/api/v2/organizations/$ORG_NAME" > /dev/null; then
    print_status "Successfully connected to Terraform Cloud"
else
    print_error "Failed to connect to Terraform Cloud API"
    print_error "Please check your API token and organization name"
    exit 1
fi

echo ""

# Get current workspaces
echo "🔍 Discovering existing workspaces..."
WORKSPACE_RESPONSE=$(curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
    -H "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces")

WORKSPACE_NAMES=$(echo "$WORKSPACE_RESPONSE" | jq -r '.data[]?.attributes.name')

if [ -z "$WORKSPACE_NAMES" ]; then
    print_info "No workspaces found in organization"
    exit 0
fi

echo "Found workspaces:"
echo "$WORKSPACE_NAMES" | while read -r workspace; do
    echo "  - $workspace"
done

echo ""

# Confirmation prompt
print_warning "This script will DELETE ALL workspaces in the $ORG_NAME organization!"
print_warning "This includes all Terraform state, run history, and configurations!"
print_warning "This action cannot be undone!"
echo ""
read -p "Are you sure you want to continue? (type 'DELETE-ALL' to confirm): " confirm

if [ "$confirm" != "DELETE-ALL" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "🗑️  Starting workspace cleanup..."
echo ""

# Function to force delete workspace with state destruction
delete_workspace_with_state() {
    local workspace_name=$1

    echo "🗑️  Processing workspace: $workspace_name"

    # First, try to get workspace details to check for resources
    WORKSPACE_DETAIL=$(curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
        -H "Content-Type: application/vnd.api+json" \
        "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces/$workspace_name")

    RESOURCE_COUNT=$(echo "$WORKSPACE_DETAIL" | jq -r '.data.attributes."resource-count" // 0')

    if [ "$RESOURCE_COUNT" -gt 0 ]; then
        print_warning "  Workspace has $RESOURCE_COUNT resources in state"
        echo "  Attempting to force delete (this will destroy state)..."
    fi

    # Cancel any running operations first
    echo "  Cancelling any active runs..."
    curl -s -X POST \
        -H "Authorization: Bearer $TF_API_TOKEN" \
        -H "Content-Type: application/vnd.api+json" \
        "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces/$workspace_name/actions/force-cancel" > /dev/null 2>&1

    # Wait a moment for cancellation
    sleep 2

    # Force delete the workspace
    DELETE_RESPONSE=$(curl -s -X DELETE \
        -H "Authorization: Bearer $TF_API_TOKEN" \
        -H "Content-Type: application/vnd.api+json" \
        "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces/$workspace_name")

    if [ $? -eq 0 ]; then
        print_status "  Workspace $workspace_name deleted successfully"
    else
        print_error "  Failed to delete workspace $workspace_name"
        echo "  Response: $DELETE_RESPONSE"
    fi

    echo ""
}

# Delete each workspace
echo "$WORKSPACE_NAMES" | while read -r workspace; do
    if [ -n "$workspace" ]; then
        delete_workspace_with_state "$workspace"
    fi
done

# Wait a moment and verify cleanup
sleep 5

echo "🔍 Verifying cleanup..."
FINAL_CHECK=$(curl -s -H "Authorization: Bearer $TF_API_TOKEN" \
    -H "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces")

REMAINING_WORKSPACES=$(echo "$FINAL_CHECK" | jq -r '.data[]?.attributes.name')

if [ -z "$REMAINING_WORKSPACES" ]; then
    print_status "✅ All workspaces successfully deleted!"
    echo ""
    echo "🎉 Terraform Cloud organization cleanup completed!"
    echo ""
    echo "Your organization '$ORG_NAME' is now completely clean."
    echo ""
    echo "Next steps:"
    echo "1. Run ./scripts/recreate-workspaces.sh to create new workspaces"
    echo "2. Test GitHub Actions workflows with fresh deployment"
    echo ""
else
    print_warning "Some workspaces may still exist:"
    echo "$REMAINING_WORKSPACES"
    echo ""
    print_info "You may need to manually delete these through the Terraform Cloud UI"
    echo "Visit: https://app.terraform.io/app/$ORG_NAME/workspaces"
fi

echo ""
print_info "Organization URL: https://app.terraform.io/app/$ORG_NAME"
echo ""
