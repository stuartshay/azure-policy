#!/bin/bash
# Clean up old TF_VAR variables from Terraform Cloud workspace

set -e

# Load environment variables
source .env

# Terraform Cloud API settings
ORG_NAME="azure-policy-cloud"
WORKSPACE_NAME="azure-policy-infrastructure"
API_URL="https://app.terraform.io/api/v2"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

# Function to get workspace ID
get_workspace_id() {
    local workspace_id
    workspace_id=$(curl -s \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "$API_URL/organizations/$ORG_NAME/workspaces/$WORKSPACE_NAME" | \
        jq -r '.data.id')
    echo "$workspace_id"
}

# Function to delete a variable
delete_variable() {
    local workspace_id="$1"
    local var_key="$2"

    # Get variable ID
    local var_id
    var_id=$(curl -s \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "$API_URL/workspaces/$workspace_id/vars" | \
        jq -r --arg key "$var_key" '.data[] | select(.attributes.key == $key) | .id')

    if [[ -n "$var_id" && "$var_id" != "null" ]]; then
        print_status "Deleting old variable: $var_key"
        curl -s \
            --header "Authorization: Bearer $TF_API_TOKEN" \
            --request DELETE \
            "$API_URL/workspaces/$workspace_id/vars/$var_id"
        print_success "Deleted: $var_key"
    else
        print_status "Variable not found: $var_key"
    fi
}

# Main function
main() {
    print_status "Cleaning up old TF_VAR variables from workspace $WORKSPACE_NAME"

    # Get workspace ID
    workspace_id=$(get_workspace_id)

    # Delete old TF_VAR variables (we're using terraform.tfvars now)
    delete_variable "$workspace_id" "TF_VAR_subscription_id"
    delete_variable "$workspace_id" "TF_VAR_location"
    delete_variable "$workspace_id" "TF_VAR_owner"
    delete_variable "$workspace_id" "TF_VAR_cost_center"
    delete_variable "$workspace_id" "TF_VAR_environment"

    print_success "Cleanup completed!"
}

main
