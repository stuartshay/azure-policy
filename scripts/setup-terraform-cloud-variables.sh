#!/bin/bash

# Setup Terraform Cloud Global Environment Variables
# This script creates a global variable set for Azure authentication

set -e

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Check required variables
if [ -z "$TF_API_TOKEN" ] || [ -z "$TF_CLOUD_ORGANIZATION" ]; then
    echo "Error: TF_API_TOKEN and TF_CLOUD_ORGANIZATION must be set in .env"
    exit 1
fi

if [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_SUBSCRIPTION_ID" ] || [ -z "$ARM_TENANT_ID" ]; then
    echo "Error: Azure ARM_ variables must be set in .env"
    exit 1
fi

ORGANIZATION="$TF_CLOUD_ORGANIZATION"
API_TOKEN="$TF_API_TOKEN"

echo "Setting up global variable set for organization: $ORGANIZATION"

# Create global variable set
VARIABLE_SET_ID=$(curl -s \
  --header "Authorization: Bearer $API_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{
    "data": {
      "type": "varsets",
      "attributes": {
        "name": "Azure Authentication",
        "description": "Global Azure service principal authentication variables",
        "global": true
      }
    }
  }' \
  "https://app.terraform.io/api/v2/organizations/$ORGANIZATION/varsets" | jq -r '.data.id')

if [ "$VARIABLE_SET_ID" = "null" ] || [ -z "$VARIABLE_SET_ID" ]; then
    echo "Error: Failed to create variable set"
    exit 1
fi

echo "Created variable set with ID: $VARIABLE_SET_ID"

# Function to create environment variable
create_env_var() {
    local KEY=$1
    local VALUE=$2
    local DESCRIPTION=$3

    echo "Creating environment variable: $KEY"

    curl -s \
      --header "Authorization: Bearer $API_TOKEN" \
      --header "Content-Type: application/vnd.api+json" \
      --request POST \
      --data "{
        \"data\": {
          \"type\": \"vars\",
          \"attributes\": {
            \"key\": \"$KEY\",
            \"value\": \"$VALUE\",
            \"category\": \"env\",
            \"sensitive\": true,
            \"description\": \"$DESCRIPTION\"
          },
          \"relationships\": {
            \"configurable\": {
              \"data\": {
                \"id\": \"$VARIABLE_SET_ID\",
                \"type\": \"varsets\"
              }
            }
          }
        }
      }" \
      "https://app.terraform.io/api/v2/varsets/$VARIABLE_SET_ID/relationships/vars" > /dev/null
}

# Create all Azure environment variables
create_env_var "ARM_CLIENT_ID" "$ARM_CLIENT_ID" "Azure Service Principal Client ID"
create_env_var "ARM_CLIENT_SECRET" "$ARM_CLIENT_SECRET" "Azure Service Principal Client Secret"
create_env_var "ARM_SUBSCRIPTION_ID" "$ARM_SUBSCRIPTION_ID" "Azure Subscription ID"
create_env_var "ARM_TENANT_ID" "$ARM_TENANT_ID" "Azure Tenant ID"

echo ""
echo "✅ Global variable set 'Azure Authentication' created successfully!"
echo ""
echo "The following environment variables are now available globally:"
echo "  - ARM_CLIENT_ID"
echo "  - ARM_CLIENT_SECRET (sensitive)"
echo "  - ARM_SUBSCRIPTION_ID"
echo "  - ARM_TENANT_ID"
echo ""
echo "All workspaces in organization '$ORGANIZATION' can now authenticate with Azure."
echo ""
echo "You can verify this in Terraform Cloud:"
echo "  https://app.terraform.io/app/$ORGANIZATION/settings/varsets"
