#!/bin/bash
# Terraform Cloud Workspace Variables Management Script

set -e

# Load environment variables
source .env

# Terraform Cloud API settings
ORG_NAME="azure-policy-cloud"
WORKSPACE_NAME="azure-policy-core"
API_URL="https://app.terraform.io/api/v2"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Function to get workspace ID
get_workspace_id() {
    local workspace_id
    workspace_id=$(curl -s \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "$API_URL/organizations/$ORG_NAME/workspaces/$WORKSPACE_NAME" | \
        jq -r '.data.id')

    if [[ "$workspace_id" == "null" || -z "$workspace_id" ]]; then
        print_error "Failed to get workspace ID"
        exit 1
    fi

    echo "$workspace_id"
}

# Function to list workspace variables
list_workspace_variables() {
    local workspace_id="$1"

    print_status "Listing current workspace variables..."

    curl -s \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "$API_URL/workspaces/$workspace_id/vars" | \
        jq -r '.data[] | "\(.attributes.key) = \(.attributes.value // "[SENSITIVE]") (Category: \(.attributes.category))"'
}

# Function to check if a variable exists
variable_exists() {
    local workspace_id="$1"
    local var_key="$2"

    local count
    count=$(curl -s \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "$API_URL/workspaces/$workspace_id/vars" | \
        jq -r --arg key "$var_key" '.data[] | select(.attributes.key == $key) | .id' | wc -l)

    [[ "$count" -gt 0 ]]
}

# Function to create or update a workspace variable
create_or_update_variable() {
    local workspace_id="$1"
    local var_key="$2"
    local var_value="$3"
    local var_category="$4"  # "env" or "terraform"
    local var_sensitive="$5" # "true" or "false"

    # Check if variable exists
    local var_id
    var_id=$(curl -s \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        --header "Content-Type: application/vnd.api+json" \
        "$API_URL/workspaces/$workspace_id/vars" | \
        jq -r --arg key "$var_key" '.data[] | select(.attributes.key == $key) | .id')

    local payload
    payload=$(jq -n \
        --arg key "$var_key" \
        --arg value "$var_value" \
        --arg category "$var_category" \
        --argjson sensitive "$var_sensitive" \
        '{
            data: {
                type: "vars",
                attributes: {
                    key: $key,
                    value: $value,
                    category: $category,
                    sensitive: $sensitive
                }
            }
        }')

    if [[ -n "$var_id" && "$var_id" != "null" ]]; then
        # Update existing variable
        print_status "Updating existing variable: $var_key"
        curl -s \
            --header "Authorization: Bearer $TF_API_TOKEN" \
            --header "Content-Type: application/vnd.api+json" \
            --request PATCH \
            --data "$payload" \
            "$API_URL/workspaces/$workspace_id/vars/$var_id" > /dev/null
    else
        # Create new variable
        print_status "Creating new variable: $var_key"
        curl -s \
            --header "Authorization: Bearer $TF_API_TOKEN" \
            --header "Content-Type: application/vnd.api+json" \
            --request POST \
            --data "$payload" \
            "$API_URL/workspaces/$workspace_id/vars" > /dev/null
    fi
}

# Main function
main() {
    print_status "Managing Terraform Cloud workspace variables for $WORKSPACE_NAME"

    # Get workspace ID
    workspace_id=$(get_workspace_id)
    print_success "Workspace ID: $workspace_id"

    # List current variables
    echo
    print_status "Current workspace variables:"
    list_workspace_variables "$workspace_id"
    echo

    # Azure Service Principal variables to create/update
    print_status "Setting up Azure Service Principal environment variables..."

    create_or_update_variable "$workspace_id" "ARM_CLIENT_ID" "$ARM_CLIENT_ID" "env" "false"
    create_or_update_variable "$workspace_id" "ARM_CLIENT_SECRET" "$ARM_CLIENT_SECRET" "env" "true"
    create_or_update_variable "$workspace_id" "ARM_SUBSCRIPTION_ID" "$ARM_SUBSCRIPTION_ID" "env" "false"
    create_or_update_variable "$workspace_id" "ARM_TENANT_ID" "$ARM_TENANT_ID" "env" "false"

    print_success "Azure Service Principal variables configured!"

    echo
    print_status "Updated workspace variables:"
    list_workspace_variables "$workspace_id"

    echo
    print_success "All variables have been set up successfully!"
    print_status "You can now run 'terraform plan' and 'terraform apply'"
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed. Please install jq first."
    print_status "Install with: sudo apt-get install jq"
    exit 1
fi

# Check if API token is available
if [[ -z "$TF_API_TOKEN" ]]; then
    print_error "TF_API_TOKEN environment variable is not set"
    print_status "Please ensure .env file is loaded with: source .env"
    exit 1
fi

# Run main function
main
