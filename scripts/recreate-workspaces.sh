#!/bin/bash

# Terraform Cloud Workspace Recreation Script
# This script helps recreate Terraform Cloud workspaces with proper configuration

set -e

echo "🏗️  Terraform Cloud Workspace Recreation Script"
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
WORKSPACES=("infrastructure" "policies" "functions")

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

# Get subscription ID for workspace variables
print_info "Please provide the following information for workspace configuration:"
echo ""

read -p "Azure Subscription ID: " SUBSCRIPTION_ID
read -p "Azure Location (default: East US): " LOCATION
LOCATION=${LOCATION:-"East US"}

read -p "Environment (default: dev): " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-"dev"}

read -p "Owner (default: platform-team): " OWNER
OWNER=${OWNER:-"platform-team"}

read -p "Cost Center (default: development): " COST_CENTER
COST_CENTER=${COST_CENTER:-"development"}

echo ""

# Function to create workspace
create_workspace() {
    local workspace_name="azure-policy-$1"
    local working_directory="infrastructure/$1"

    echo "Creating workspace: $workspace_name"

    # Create workspace
    RESPONSE=$(curl -s -X POST \
        -H "Authorization: Bearer $TF_API_TOKEN" \
        -H "Content-Type: application/vnd.api+json" \
        -d "{
            \"data\": {
                \"type\": \"workspaces\",
                \"attributes\": {
                    \"name\": \"$workspace_name\",
                    \"terraform-version\": \"1.6.0\",
                    \"working-directory\": \"$working_directory\",
                    \"auto-apply\": false,
                    \"queue-all-runs\": false
                }
            }
        }" \
        "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces")

    if echo "$RESPONSE" | grep -q "\"name\":\"$workspace_name\""; then
        print_status "Workspace $workspace_name created successfully"

        # Get workspace ID for variable creation
        WORKSPACE_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

        # Create workspace variables
        create_workspace_variables "$workspace_name" "$WORKSPACE_ID"

    else
        print_error "Failed to create workspace $workspace_name"
        echo "Response: $RESPONSE"
    fi
}

# Function to create workspace variables
create_workspace_variables() {
    local workspace_name=$1
    local workspace_id=$2

    echo "  Adding variables to $workspace_name..."

    # Define variables
    declare -A variables=(
        ["TF_VAR_subscription_id"]="$SUBSCRIPTION_ID:true"
        ["TF_VAR_location"]="$LOCATION:false"
        ["TF_VAR_environment"]="$ENVIRONMENT:false"
        ["TF_VAR_owner"]="$OWNER:false"
        ["TF_VAR_cost_center"]="$COST_CENTER:false"
    )

    # Create each variable
    for var_name in "${!variables[@]}"; do
        IFS=':' read -r var_value var_sensitive <<< "${variables[$var_name]}"

        VAR_RESPONSE=$(curl -s -X POST \
            -H "Authorization: Bearer $TF_API_TOKEN" \
            -H "Content-Type: application/vnd.api+json" \
            -d "{
                \"data\": {
                    \"type\": \"vars\",
                    \"attributes\": {
                        \"key\": \"$var_name\",
                        \"value\": \"$var_value\",
                        \"category\": \"terraform\",
                        \"sensitive\": $var_sensitive
                    }
                }
            }" \
            "https://app.terraform.io/api/v2/workspaces/$workspace_id/vars")

        if echo "$VAR_RESPONSE" | grep -q "\"key\":\"$var_name\""; then
            if [ "$var_sensitive" = "true" ]; then
                echo "    ✅ Added sensitive variable: $var_name"
            else
                echo "    ✅ Added variable: $var_name = $var_value"
            fi
        else
            print_warning "    Failed to create variable: $var_name"
        fi
    done
}

# Function to delete workspace (if it exists)
delete_workspace() {
    local workspace_name="azure-policy-$1"

    echo "Checking if workspace $workspace_name exists..."

    curl -s -X DELETE \
        -H "Authorization: Bearer $TF_API_TOKEN" \
        -H "Content-Type: application/vnd.api+json" \
        "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces/$workspace_name" > /dev/null

    if [ $? -eq 0 ]; then
        print_status "Workspace $workspace_name deleted (if it existed)"
    fi
}

# Main execution
echo "🔄 Recreating Terraform Cloud workspaces..."
echo ""

for workspace in "${WORKSPACES[@]}"; do
    echo "Processing $workspace workspace..."

    # Delete existing workspace (ignore if it doesn't exist)
    delete_workspace "$workspace"

    # Wait a moment
    sleep 2

    # Create new workspace
    create_workspace "$workspace"

    echo ""
done

echo "🎉 Workspace recreation completed!"
echo ""
echo "Created workspaces:"
for workspace in "${WORKSPACES[@]}"; do
    echo "  - azure-policy-$workspace"
done

echo ""
echo "Next steps:"
echo "1. Verify workspaces in Terraform Cloud UI: https://app.terraform.io/app/$ORG_NAME/workspaces"
echo "2. Connect workspaces to your GitHub repository"
echo "3. Test GitHub Actions workflows"
echo ""

print_info "You can now run the GitHub Actions workflows to deploy infrastructure!"
echo ""

# Main execution
echo "🔄 Recreating Terraform Cloud workspaces..."
echo ""

for workspace in "${WORKSPACES[@]}"; do
    echo "Processing $workspace workspace..."

    # Delete existing workspace (ignore if it doesn't exist)
    delete_workspace "$workspace"

    # Wait a moment
    sleep 2

    # Create new workspace
    create_workspace "$workspace"

    echo ""
done

echo "🎉 Workspace recreation completed!"
echo ""
echo "Created workspaces:"
for workspace in "${WORKSPACES[@]}"; do
    echo "  - azure-policy-$workspace"
done

echo ""
echo "Next steps:"
echo "1. Verify workspaces in Terraform Cloud UI: https://app.terraform.io/app/$ORG_NAME/workspaces"
echo "2. Connect workspaces to your GitHub repository"
echo "3. Test GitHub Actions workflows"
echo ""

print_info "You can now run the GitHub Actions workflows to deploy infrastructure!"
echo ""
