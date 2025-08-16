#!/bin/bash
# Test Key Vault Integration for Database Credentials
# This script verifies that database credentials are properly stored in Key Vault

set -e

# Configuration
KEYVAULT_NAME="AzureConnectedServices"
SECRET_NAMES=("postgres-admin-username" "postgres-admin-password" "postgres-connection-string")

echo "🔐 Testing Key Vault Integration for Database Credentials"
echo "=================================================="

# Check if Azure CLI is logged in
if ! az account show >/dev/null 2>&1; then
    echo "❌ Please login to Azure CLI first: az login"
    exit 1
fi

# Check if Key Vault is accessible
echo "📍 Checking Key Vault access..."
if ! az keyvault show --name "$KEYVAULT_NAME" >/dev/null 2>&1; then
    echo "❌ Cannot access Key Vault: $KEYVAULT_NAME"
    exit 1
fi
echo "✅ Key Vault accessible: $KEYVAULT_NAME"

# Test each secret
echo ""
echo "🔍 Testing database credential secrets..."
for secret_name in "${SECRET_NAMES[@]}"; do
    echo -n "  - $secret_name: "
    if az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$secret_name" >/dev/null 2>&1; then
        echo "✅ Found"

        # Show secret URI (but not value)
        secret_uri=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$secret_name" --query "id" -o tsv)
        echo "    URI: $secret_uri"
    else
        echo "❌ Missing"
    fi
done

# Test connection string format (without revealing actual values)
echo ""
echo "🔗 Testing connection string format..."
if connection_string=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "postgres-connection-string" --query "value" -o tsv 2>/dev/null); then
    if [[ "$connection_string" == postgresql://* ]] && [[ "$connection_string" == *"sslmode=require"* ]]; then
        echo "✅ Connection string format is valid (URL format)"
        echo "    Format: postgresql://username:password@host:5432/database?sslmode=require" # pragma: allowlist secret
    else
        echo "❌ Connection string format is invalid"
        echo "    Expected: postgresql://... format with sslmode=require"
    fi
else
    echo "❌ Could not retrieve connection string"
fi

# Show how to use in Function App settings
echo ""
echo "💡 Usage in Function App Settings:"
echo "=================================================="
echo 'DATABASE_USERNAME="@Microsoft.KeyVault(SecretUri=https://azureconnectedservices.vault.azure.net/secrets/postgres-admin-username/)"'
echo 'DATABASE_PASSWORD="@Microsoft.KeyVault(SecretUri=https://azureconnectedservices.vault.azure.net/secrets/postgres-admin-password/)"'
echo 'DATABASE_CONNECTION_STRING="@Microsoft.KeyVault(SecretUri=https://azureconnectedservices.vault.azure.net/secrets/postgres-connection-string/)"'

echo ""
echo "🎉 Key Vault integration test completed!"
