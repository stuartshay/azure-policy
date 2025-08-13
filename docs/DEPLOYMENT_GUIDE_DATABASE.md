# Database Module Deployment Guide

This guide walks you through deploying the PostgreSQL database module for the Azure Policy project.

## Prerequisites

Before deploying the database module, ensure:

1. **Core Infrastructure is Deployed**: The core module must be deployed first
2. **Azure CLI is Authenticated**: Run `az login` if needed
3. **Required Information**: You need the resource group name from the core module

## Step 1: Verify Core Infrastructure

First, check that the core infrastructure is deployed:

```bash
# Navigate to core module
cd ../core

# Check core module status
make status

# Get the resource group name (you'll need this)
terraform output resource_group_name
```

## Step 2: Configure Database Module

Navigate to the database module and set up configuration:

```bash
# Navigate to database module
cd ../database

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit the configuration file
nano terraform.tfvars  # or use your preferred editor
```

### Required Configuration

Update `terraform.tfvars` with at least these values:

```hcl
# Required - Get from Azure portal or `az account show`
subscription_id = "your-subscription-id-here"

# Required - Get from core module output
resource_group_name = "rg-azpolicy-dev-eastus"  # Example

# Optional - Customize as needed
environment = "dev"
```

## Step 3: Deploy the Database

Deploy using the Makefile commands:

```bash
# Option 1: Quick deployment (recommended for first time)
make quick-deploy

# Option 2: Step-by-step deployment
make init
make plan    # Review the plan carefully
make apply   # Confirm deployment
make output  # Show outputs
```

## Step 4: Verify Deployment

Check the deployment status:

```bash
# Check overall status
make status

# Check security configuration
make security-check

# Check cost information
make cost-info

# Show connection information (safe - no passwords)
make show-connection
```

## Step 5: Get Connection Information

Retrieve connection details for Function App integration:

```bash
# Show connection components (excludes password)
make show-components

# Get full outputs (includes sensitive data)
terraform output

# Get specific outputs
terraform output postgresql_server_fqdn
terraform output database_name
terraform output connection_string_template
```

## Expected Outputs

After successful deployment, you should see:

```
Database Infrastructure Status
=================================
✅ Database deployed

Resources:
  PostgreSQL Server: psql-azpolicy-dev-eastus-001
  Version: PostgreSQL 15
  Database: azurepolicy

Configuration:
  sku_name = "B_Standard_B1ms"
  storage_mb = 32768

Cost Optimization:
  tier = "Burstable"
  estimated_monthly_cost_usd = "12-15"
```

## Integration with Function Apps

After deployment, you can integrate with Function Apps using these outputs:

### Environment Variables for Function App

```bash
# Get these values from terraform outputs
DB_HOST=$(terraform output -raw postgresql_server_fqdn)
DB_PORT="5432"
DB_NAME=$(terraform output -raw database_name)
DB_USER=$(terraform output -raw postgresql_admin_username)
DB_PASSWORD=$(terraform output -raw postgresql_admin_password)
DATABASE_URL=$(terraform output -raw connection_string_full)
```

### Function App Configuration

Add these to your Function App's application settings:

```json
{
  "DB_HOST": "psql-azpolicy-dev-eastus-001.postgres.database.azure.com",
  "DB_PORT": "5432",
  "DB_NAME": "azurepolicy",
  "DB_USER": "psqladmin",
  "DB_PASSWORD": "auto-generated-password",
  "DATABASE_URL": "postgresql://psqladmin:password@server:5432/azurepolicy?sslmode=require"
}
```

## Testing Connection

If you have PostgreSQL client tools installed:

```bash
# Test connection (requires psql)
make test-connection

# Manual connection test
psql "$(terraform output -raw connection_string_full)" -c "SELECT version();"
```

## Troubleshooting

### Common Issues

1. **Core Infrastructure Not Found**
   ```bash
   # Verify core module is deployed
   cd ../core && make status

   # Check resource group exists
   az group show --name "your-resource-group-name"
   ```

2. **Subnet Not Found**
   ```bash
   # Check VNet and subnets exist
   az network vnet list --resource-group "your-resource-group-name"
   az network vnet subnet list --vnet-name "vnet-name" --resource-group "your-resource-group-name"
   ```

3. **Permission Issues**
   ```bash
   # Check Azure CLI authentication
   az account show

   # Check permissions
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

4. **Terraform State Issues**
   ```bash
   # Clean and reinitialize if needed
   make clean
   make init
   ```

### Debug Commands

```bash
# Validate configuration
make validate

# Check Terraform plan
terraform plan -detailed-exitcode

# Show current state
terraform show

# List all resources
terraform state list
```

## Cleanup

To remove the database (⚠️ **DESTRUCTIVE** ⚠️):

```bash
# This will destroy all database resources and data
make destroy

# Clean up Terraform files
make clean
```

## Security Notes

- Database has no public access (private endpoint only)
- SSL/TLS is enforced for all connections
- Admin password is auto-generated and stored in Terraform state
- Connection strings are marked as sensitive in outputs

## Cost Management

- Current configuration: ~$12-15 USD/month
- Burstable tier automatically scales down when idle
- No high availability to minimize costs
- Local backup only (no geo-redundant backup)

## Next Steps

1. **Update Function Apps**: Add database connection settings
2. **Test Connectivity**: Verify Function Apps can connect
3. **Set Up Monitoring**: Configure alerts and monitoring
4. **Backup Strategy**: Review backup and recovery procedures
5. **Security Review**: Audit access and security settings

## Support

For issues:
1. Check this troubleshooting guide
2. Review Terraform logs: `terraform plan` and `terraform apply`
3. Use `make help` for available commands
4. Check Azure portal for resource status
