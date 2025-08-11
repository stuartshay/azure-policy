#!/bin/bash

# Configure Terraform Cloud Workspace Variables via API
# This script automatically sets Azure credentials in Terraform Cloud workspaces

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables from .env
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Function to create or update a variable in Terraform Cloud
create_or_update_variable() {
    local workspace_id=$1
    local key=$2
    local value=$3
    local category=$4  # "terraform" or "env"
    local sensitive=$5  # "true" or "false"
    local description=$6

    # Check if variable exists
    existing_var=$(curl -s \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "https://app.terraform.io/api/v2/workspaces/${workspace_id}/vars" | \
        jq -r ".data[] | select(.attributes.key==\"${key}\") | .id" || echo "")

    if [ -n "$existing_var" ]; then
        # Update existing variable
        echo "  Updating variable: $key"
        curl -s \
            --header "Authorization: Bearer $TF_API_TOKEN" \
            --header "Content-Type: application/vnd.api+json" \
            --request PATCH \
            --data "{
                \"data\": {
                    \"type\": \"vars\",
                    \"id\": \"${existing_var}\",
                    \"attributes\": {
                        \"value\": \"${value}\",
                        \"sensitive\": ${sensitive}
                    }
                }
            }" \
            "https://app.terraform.io/api/v2/vars/${existing_var}" > /dev/null
    else
        # Create new variable
        echo "  Creating variable: $key"
        curl -s \
            --header "Authorization: Bearer $TF_API_TOKEN" \
            --header "Content-Type: application/vnd.api+json" \
            --request POST \
            --data "{
                \"data\": {
                    \"type\": \"vars\",
                    \"attributes\": {
                        \"key\": \"${key}\",
                        \"value\": \"${value}\",
                        \"category\": \"${category}\",
                        \"sensitive\": ${sensitive},
                        \"description\": \"${description}\"
                    },
                    \"relationships\": {
                        \"workspace\": {
                            \"data\": {
                                \"type\": \"workspaces\",
                                \"id\": \"${workspace_id}\"
                            }
                        }
                    }
                }
            }" \
            "https://app.terraform.io/api/v2/vars" > /dev/null
    fi
}

# Function to get workspace ID
get_workspace_id() {
    local org=$1
    local workspace_name=$2

    workspace_id=$(curl -s \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "https://app.terraform.io/api/v2/organizations/${org}/workspaces/${workspace_name}" | \
        jq -r '.data.id')

    echo "$workspace_id"
}

# Function to configure a workspace
configure_workspace() {
    local workspace_name=$1
    echo -e "${YELLOW}Configuring workspace: ${workspace_name}${NC}"

    # Get workspace ID
    workspace_id=$(get_workspace_id "$TF_CLOUD_ORGANIZATION" "$workspace_name")

    if [ "$workspace_id" == "null" ] || [ -z "$workspace_id" ]; then
        echo -e "${RED}  Error: Workspace ${workspace_name} not found${NC}"
        return 1
    fi

    echo "  Workspace ID: $workspace_id"

    # Set environment variables
    create_or_update_variable "$workspace_id" "ARM_CLIENT_ID" "$ARM_CLIENT_ID" "env" "false" "Azure Service Principal Client ID"
    create_or_update_variable "$workspace_id" "ARM_CLIENT_SECRET" "$ARM_CLIENT_SECRET" "env" "true" "Azure Service Principal Client Secret"
    create_or_update_variable "$workspace_id" "ARM_SUBSCRIPTION_ID" "$ARM_SUBSCRIPTION_ID" "env" "false" "Azure Subscription ID"
    create_or_update_variable "$workspace_id" "ARM_TENANT_ID" "$ARM_TENANT_ID" "env" "false" "Azure Tenant ID"

    # Set Terraform variables
    create_or_update_variable "$workspace_id" "subscription_id" "$ARM_SUBSCRIPTION_ID" "terraform" "false" "Azure Subscription ID for Terraform"

    echo -e "${GREEN}  Workspace configured successfully!${NC}"
}

# Main execution
echo -e "${GREEN}Terraform Cloud Workspace Configuration${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check if we have the required environment variables
if [ -z "$TF_API_TOKEN" ] || [ -z "$TF_CLOUD_ORGANIZATION" ] || [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_SUBSCRIPTION_ID" ] || [ -z "$ARM_TENANT_ID" ]; then
    echo -e "${RED}Error: Missing required environment variables${NC}"
    echo "Please ensure your .env file contains:"
    echo "  - TF_API_TOKEN"
    echo "  - TF_CLOUD_ORGANIZATION"
    echo "  - ARM_CLIENT_ID"
    echo "  - ARM_CLIENT_SECRET"
    echo "  - ARM_SUBSCRIPTION_ID"
    echo "  - ARM_TENANT_ID"
    exit 1
fi

# Configure the workspace specified as argument, or all workspaces
if [ $# -eq 1 ]; then
    configure_workspace "$1"
else
    echo "Configuring all workspaces..."
    configure_workspace "azure-policy-core"
    configure_workspace "azure-policy-functions"
    configure_workspace "azure-policy-policies"
fi

echo ""
echo -e "${GREEN}Configuration complete!${NC}"
echo ""
echo "You can now run:"
echo "  make terraform-core-plan"
echo "  make terraform-functions-plan"
echo "  make terraform-policies-plan"
