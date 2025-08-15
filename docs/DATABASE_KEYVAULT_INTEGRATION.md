# Database Key Vault Integration Setup Guide

## 📋 Overview

This guide shows how to configure your PostgreSQL database deployment to automatically generate a secure password and store all database credentials in your existing Azure Key Vault (`AzureConnectedServices`).

## 🔑 What Gets Stored in Key Vault

When you deploy the database with Key Vault integration enabled, the following secrets are automatically created:

| Secret Name | Content | Purpose |
|-------------|---------|---------|
| `postgres-admin-username` | Database administrator username | For application authentication |
| `postgres-admin-password` | Auto-generated secure password | For application authentication |
| `postgres-connection-string` | Complete PostgreSQL connection string | For easy application integration |

## 🚀 Deployment Steps

### 1. **Configure the Database Module**

Create a `terraform.tfvars` file in the `infrastructure/database/` directory:

```hcl
# Basic Configuration
subscription_id = "09e01a7d-07d4-43ee-80c7-8b2c0d7ec41f"
resource_group_name = "rg-azurepolicy-dev-eastus-001"
environment = "dev"

# Key Vault Integration (IMPORTANT!)
enable_keyvault_integration = true
keyvault_name = "AzureConnectedServices"
keyvault_resource_group_name = "AzureConnectedServices-RG"

# Database Configuration
admin_username = "psqladmin"
# admin_password = null  # Will auto-generate if not provided
database_name = "azurepolicy"

# Cost Optimization
sku_name = "B_Standard_B1ms"  # Lowest cost tier
storage_mb = 32768  # 32 GB minimum
backup_retention_days = 7
geo_redundant_backup_enabled = false
```

### 2. **Deploy the Database**

```bash
# Navigate to database workspace
cd infrastructure/database

# Initialize Terraform
make init

# Plan the deployment
make plan

# Apply the changes
make apply
```

### 3. **Verify Key Vault Integration**

Run the test script to verify credentials were stored correctly:

```bash
./test-keyvault-integration.sh
```

Expected output:
```
🔐 Testing Key Vault Integration for Database Credentials
==================================================
✅ Key Vault accessible: AzureConnectedServices

🔍 Testing database credential secrets...
  - postgres-admin-username: ✅ Found
  - postgres-admin-password: ✅ Found
  - postgres-connection-string: ✅ Found

✅ Connection string format is valid
🎉 Key Vault integration test completed!
```

## 🔗 Using Credentials in Function Apps

### Option 1: Key Vault References (Recommended)

Configure your Function App to reference Key Vault secrets directly:

```hcl
# In your Function App configuration
app_settings = {
  "DATABASE_USERNAME" = "@Microsoft.KeyVault(SecretUri=https://azureconnectedservices.vault.azure.net/secrets/postgres-admin-username/)"
  "DATABASE_PASSWORD" = "@Microsoft.KeyVault(SecretUri=https://azureconnectedservices.vault.azure.net/secrets/postgres-admin-password/)"
  "DATABASE_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=https://azureconnectedservices.vault.azure.net/secrets/postgres-connection-string/)"
}
```

### Option 2: Azure SDK in Python

```python
from azure.keyvault.secrets import SecretClient
from azure.identity import DefaultAzureCredential

# Function App will use managed identity automatically
credential = DefaultAzureCredential()
client = SecretClient(
    vault_url="https://azureconnectedservices.vault.azure.net/",
    credential=credential
)

# Retrieve database credentials
username = client.get_secret("postgres-admin-username").value
password = client.get_secret("postgres-admin-password").value
connection_string = client.get_secret("postgres-connection-string").value
```

## 🔒 Security Benefits

1. **No Hardcoded Passwords**: Database passwords are never stored in code or configuration files
2. **Automatic Rotation Support**: Passwords can be easily rotated through Key Vault
3. **Audit Trail**: All access to secrets is logged in Key Vault
4. **Managed Identity**: Function Apps use managed identity to access Key Vault (no service principal needed)
5. **Cross-Resource Group**: Database and Key Vault can be in different resource groups

## 🧪 Testing Database Connection

You can test the database connection using the stored credentials:

```bash
# Get connection string from Key Vault
CONNECTION_STRING=$(az keyvault secret show --vault-name AzureConnectedServices --name postgres-connection-string --query value -o tsv)

# Test connection (requires psql client)
psql "$CONNECTION_STRING" -c "SELECT version();"
```

## 📊 Cost Impact

- **Key Vault Operations**: ~$0.03/10K operations (minimal cost)
- **Additional Secrets**: No extra cost (first 25K operations/month are free)
- **Database**: Same cost as without Key Vault integration

## 🚨 Important Notes

1. **Permissions**: Your Terraform service principal needs `Key Vault Administrator` role on the Key Vault
2. **Function App Access**: Function Apps need `Key Vault Secrets User` role to read secrets
3. **Network Access**: Ensure Key Vault allows access from your Function App subnet
4. **Backup**: Key Vault secrets are automatically backed up by Azure

## 🔧 Customization

You can customize secret names by modifying the `keyvault_secret_names` variable:

```hcl
keyvault_secret_names = {
  admin_username    = "my-db-username"
  admin_password    = "my-db-password"      # pragma: allowlist secret
  connection_string = "my-db-connection"
}
```

## 🐛 Troubleshooting

**Problem**: `403 Forbidden` when storing secrets
**Solution**: Ensure your user/service principal has `Key Vault Administrator` role

**Problem**: Function App can't read secrets
**Solution**: Grant the Function App's managed identity `Key Vault Secrets User` role

**Problem**: Connection string format issues
**Solution**: Run the test script to verify format and regenerate if needed
