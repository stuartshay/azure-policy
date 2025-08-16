#!/bin/bash

# Fix Azure Key Vault Permissions for Database Destroy
# This script grants the necessary permissions to the service principal for Key Vault access

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# Configuration
KEYVAULT_NAME="AzureConnectedServices"
KEYVAULT_RG="azureconnectedservices-rg"
# SERVICE_PRINCIPAL_ID is kept for reference but currently unused
# shellcheck disable=SC2034
SERVICE_PRINCIPAL_ID="50ac2ed1-1ea1-46e6-9992-6c5de5f5da24"
OBJECT_ID="c1957a68-2b8f-4c8e-8cd0-5b8bd6c359f9"

echo -e "${BLUE}=== Azure Key Vault Permissions Fix ===${RESET}"
echo ""

# Function to check if logged in to Azure
check_azure_login() {
    echo -e "${YELLOW}Checking Azure CLI login status...${RESET}"
    if ! az account show &>/dev/null; then
        echo -e "${RED}Error: Not logged in to Azure CLI${RESET}"
        echo -e "${YELLOW}Please run: az login${RESET}"
        exit 1
    fi

    local current_subscription
    current_subscription=$(az account show --query name -o tsv)
    echo -e "${GREEN}✅ Logged in to Azure${RESET}"
    echo -e "Current subscription: ${current_subscription}"
    echo ""
}

# Function to check if Key Vault exists
check_keyvault_exists() {
    echo -e "${YELLOW}Checking if Key Vault exists...${RESET}"
    if ! az keyvault show --name "$KEYVAULT_NAME" --resource-group "$KEYVAULT_RG" &>/dev/null; then
        echo -e "${RED}Error: Key Vault '$KEYVAULT_NAME' not found in resource group '$KEYVAULT_RG'${RESET}"
        echo -e "${YELLOW}Available Key Vaults:${RESET}"
        az keyvault list --query "[].{Name:name, ResourceGroup:resourceGroup}" -o table
        exit 1
    fi

    echo -e "${GREEN}✅ Key Vault '$KEYVAULT_NAME' found${RESET}"
    echo ""
}

# Function to check current permissions
check_current_permissions() {
    echo -e "${YELLOW}Checking current Key Vault access policies...${RESET}"

    local policies
    policies=$(az keyvault show --name "$KEYVAULT_NAME" --resource-group "$KEYVAULT_RG" --query "properties.accessPolicies[?objectId=='$OBJECT_ID']" -o json)

    if [ "$policies" = "[]" ]; then
        echo -e "${RED}❌ No access policy found for service principal${RESET}"
        return 1
    else
        echo -e "${GREEN}✅ Access policy exists for service principal${RESET}"
        echo -e "${BLUE}Current permissions:${RESET}"
        echo "$policies" | jq -r '.[0].permissions | to_entries[] | "\(.key): \(.value | join(", "))"'
        return 0
    fi
    echo ""
}

# Function to check if Key Vault uses RBAC
check_keyvault_rbac() {
    echo -e "${YELLOW}Checking Key Vault authorization model...${RESET}"

    local rbac_enabled
    rbac_enabled=$(az keyvault show --name "$KEYVAULT_NAME" --resource-group "$KEYVAULT_RG" --query "properties.enableRbacAuthorization" -o tsv)

    if [ "$rbac_enabled" = "true" ]; then
        echo -e "${BLUE}Key Vault uses RBAC authorization${RESET}"
        return 0
    else
        echo -e "${BLUE}Key Vault uses access policies${RESET}"
        return 1
    fi
}

# Function to grant Key Vault permissions via RBAC
grant_keyvault_rbac_permissions() {
    echo -e "${YELLOW}Granting Key Vault RBAC permissions to service principal...${RESET}"

    # Get Key Vault resource ID
    local keyvault_id
    keyvault_id=$(az keyvault show --name "$KEYVAULT_NAME" --resource-group "$KEYVAULT_RG" --query "id" -o tsv)

    # Check if we need read-only or full permissions
    local role_name="Key Vault Secrets Officer"
    echo -e "${BLUE}Assigning '${role_name}' role for full secret management permissions...${RESET}"

    # Assign Key Vault Secrets Officer role (includes read, write, delete)
    az role assignment create \
        --assignee "$OBJECT_ID" \
        --role "$role_name" \
        --scope "$keyvault_id" \
        --output none

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully granted Key Vault RBAC permissions${RESET}"
        echo -e "Role assigned:"
        echo -e "  - Key Vault Secrets Officer (full access to secrets: read, write, delete)"
        echo ""
    else
        echo -e "${YELLOW}⚠️  Key Vault Secrets Officer role assignment failed, trying Key Vault Secrets User...${RESET}"

        # Fallback to Key Vault Secrets User role
        az role assignment create \
            --assignee "$OBJECT_ID" \
            --role "Key Vault Secrets User" \
            --scope "$keyvault_id" \
            --output none

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Successfully granted Key Vault RBAC permissions${RESET}"
            echo -e "Role assigned:"
            echo -e "  - Key Vault Secrets User (read access to secrets)"
            echo -e "${YELLOW}Note: Delete operations may still fail. Use --bypass option if needed.${RESET}"
            echo ""
        else
            echo -e "${RED}❌ Failed to grant Key Vault RBAC permissions${RESET}"
            exit 1
        fi
    fi
}

# Function to grant Key Vault permissions via access policies
grant_keyvault_policy_permissions() {
    echo -e "${YELLOW}Granting Key Vault access policy permissions to service principal...${RESET}"

    # Grant secret permissions (get, list)
    az keyvault set-policy \
        --name "$KEYVAULT_NAME" \
        --resource-group "$KEYVAULT_RG" \
        --object-id "$OBJECT_ID" \
        --secret-permissions get list \
        --output none

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Successfully granted Key Vault access policy permissions${RESET}"
        echo -e "Permissions granted:"
        echo -e "  - Secret permissions: get, list"
        echo ""
    else
        echo -e "${RED}❌ Failed to grant Key Vault access policy permissions${RESET}"
        exit 1
    fi
}

# Function to grant Key Vault permissions (auto-detect method)
grant_keyvault_permissions() {
    if check_keyvault_rbac; then
        grant_keyvault_rbac_permissions
    else
        grant_keyvault_policy_permissions
    fi
}

# Function to verify permissions
verify_permissions() {
    echo -e "${YELLOW}Verifying permissions...${RESET}"

    # Wait a moment for permissions to propagate
    echo -e "${BLUE}Waiting for permissions to propagate (30 seconds)...${RESET}"
    sleep 30

    # Try to list secrets to verify access
    if az keyvault secret list --vault-name "$KEYVAULT_NAME" --query "[0].name" -o tsv &>/dev/null; then
        echo -e "${GREEN}✅ Permissions verified successfully${RESET}"
        echo -e "${GREEN}Service principal can now access Key Vault secrets${RESET}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Permissions may still be propagating${RESET}"
        echo -e "${YELLOW}Wait a few more minutes before retrying the destroy operation${RESET}"
        return 1
    fi
    echo ""
}

# Function to show next steps
show_next_steps() {
    echo -e "${BLUE}=== Next Steps ===${RESET}"
    echo ""
    echo -e "${GREEN}1. Wait 1-2 minutes for permissions to fully propagate${RESET}"
    echo -e "${GREEN}2. Retry the database destroy operation:${RESET}"
    echo -e "   ${BLUE}make terraform-database-destroy${RESET}"
    echo ""
    echo -e "${YELLOW}If the issue persists, try:${RESET}"
    echo -e "   ${BLUE}cd infrastructure/database && make destroy${RESET}"
    echo ""
    echo -e "${YELLOW}Alternative approach (if still failing):${RESET}"
    echo -e "   ${BLUE}./scripts/fix-keyvault-permissions.sh --bypass${RESET}"
    echo ""
}

# Function to bypass Key Vault integration (Option 2)
bypass_keyvault_integration() {
    echo -e "${YELLOW}Bypassing Key Vault integration for destroy operation...${RESET}"

    cd infrastructure/database

    # Check if terraform state exists
    if [ ! -f "terraform.tfstate" ]; then
        echo -e "${RED}Error: No terraform.tfstate file found${RESET}"
        echo -e "${YELLOW}Run this script from the project root directory${RESET}"
        exit 1
    fi

    # Remove Key Vault secret resources from state
    echo -e "${BLUE}Removing Key Vault secrets from Terraform state...${RESET}"

    terraform state rm 'azurerm_key_vault_secret.postgres_admin_username[0]' 2>/dev/null || echo "Resource not in state"
    terraform state rm 'azurerm_key_vault_secret.postgres_admin_password[0]' 2>/dev/null || echo "Resource not in state"
    terraform state rm 'azurerm_key_vault_secret.postgres_connection_string[0]' 2>/dev/null || echo "Resource not in state"

    echo -e "${GREEN}✅ Key Vault secrets removed from state${RESET}"
    echo -e "${YELLOW}Now you can run: make destroy${RESET}"

    cd - > /dev/null
}

# Function to show help
show_help() {
    echo -e "${BLUE}Azure Key Vault Permissions Fix Script${RESET}"
    echo ""
    echo -e "${YELLOW}Usage:${RESET}"
    echo -e "  $0                    # Grant Key Vault permissions (default)"
    echo -e "  $0 --bypass          # Bypass Key Vault integration for destroy"
    echo -e "  $0 --check           # Check current permissions only"
    echo -e "  $0 --help            # Show this help"
    echo ""
    echo -e "${YELLOW}Description:${RESET}"
    echo -e "This script fixes the Key Vault permissions issue when destroying"
    echo -e "the database infrastructure. It grants the necessary permissions"
    echo -e "to the service principal to read Key Vault secrets."
    echo ""
}

# Main execution
main() {
    case "${1:-}" in
        --bypass)
            check_azure_login
            bypass_keyvault_integration
            ;;
        --check)
            check_azure_login
            check_keyvault_exists
            check_current_permissions
            ;;
        --help)
            show_help
            ;;
        "")
            check_azure_login
            check_keyvault_exists

            if check_current_permissions; then
                echo -e "${GREEN}Permissions already exist. Verifying access...${RESET}"
                if verify_permissions; then
                    echo -e "${GREEN}✅ All permissions are working correctly${RESET}"
                    show_next_steps
                else
                    echo -e "${YELLOW}Permissions exist but may need time to propagate${RESET}"
                    show_next_steps
                fi
            else
                grant_keyvault_permissions
                verify_permissions
                show_next_steps
            fi
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${RESET}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
