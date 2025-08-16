# Azure Database for PostgreSQL Infrastructure

This module creates a low-cost Azure Database for PostgreSQL Flexible Server optimized for the Azure Policy project's Function Stack integration.

## Overview

This Terraform module deploys:
- Azure Database for PostgreSQL Flexible Server (Burstable tier for cost optimization)
- Private endpoint for secure connectivity
- Private DNS zone for name resolution
- Default database and optional additional databases
- Network security configuration for Function App access

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                     │
│                                                             │
│  ┌─────────────────┐    ┌──────────────────────────────────┐ │
│  │   PostgreSQL    │    │         Private DNS Zone        │ │
│  │ Flexible Server │    │ privatelink.postgres.database... │ │
│  │                 │    │                                  │ │
│  │ • B_Standard_B1ms│    └──────────────────────────────────┘ │
│  │ • 32 GB Storage │                                        │
│  │ • SSL Enforced  │    ┌──────────────────────────────────┐ │
│  │ • Private Only  │    │        Private Endpoint          │ │
│  └─────────────────┘    │                                  │ │
│           │              │ • VNet Integration               │ │
│           └──────────────│ • Private IP                    │ │
│                          │ • DNS Resolution                │ │
│                          └──────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                Virtual Network                          │ │
│  │                                                         │ │
│  │  ┌─────────────────┐  ┌─────────────────────────────────┐ │ │
│  │  │ Functions Subnet│  │   Private Endpoints Subnet     │ │ │
│  │  │                 │  │                                 │ │ │
│  │  │ • Function Apps │  │ • Database Private Endpoint    │ │ │
│  │  │ • Firewall Rule │  │ • Other Private Endpoints      │ │ │
│  │  └─────────────────┘  └─────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Cost Optimization

This module is configured for **lowest cost** while maintaining production-ready security:

- **SKU**: `B_Standard_B1ms` (Burstable, 1 vCore, 2 GB RAM)
- **Storage**: 32 GB (minimum)
- **High Availability**: Disabled
- **Geo-redundant Backup**: Disabled
- **Estimated Cost**: $12-15 USD/month

## Features

### Security
- ✅ Private endpoint connectivity (no public access)
- ✅ SSL/TLS enforcement (minimum TLS 1.2)
- ✅ VNet integration
- ✅ Network security group rules
- ✅ Secure credential management

### Performance
- ✅ Query Store enabled for performance monitoring
- ✅ Performance Insights enabled
- ✅ Optimized PostgreSQL configuration
- ✅ Connection pooling ready

### Monitoring
- ✅ Slow query logging (>1 second)
- ✅ pg_stat_statements extension
- ✅ Azure Monitor integration ready

## Prerequisites

1. **Core Infrastructure**: The core module must be deployed first to provide:
   - Resource Group
   - Virtual Network
   - Subnets (functions, privateendpoints)

2. **Azure CLI**: Authenticated with appropriate permissions

3. **Terraform**: Version >= 1.5

## Quick Start

1. **Navigate to the database module**:
   ```bash
   cd infrastructure/database
   ```

2. **Set required variables** (create `terraform.tfvars`):
   ```hcl
   subscription_id       = "your-subscription-id"
   resource_group_name   = "rg-azpolicy-dev-eastus"  # From core module
   environment          = "dev"
   ```

3. **Deploy the database**:
   ```bash
   make quick-deploy
   ```

4. **Check deployment status**:
   ```bash
   make status
   ```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `subscription_id` | Azure subscription ID | `"12345678-1234-1234-1234-123456789012"` |
| `resource_group_name` | Existing resource group name | `"rg-azpolicy-dev-eastus"` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `environment` | Environment name | `"dev"` |
| `workload` | Workload name | `"azpolicy"` |
| `location` | Azure region | `"East US"` |
| `admin_username` | Database admin username | `"psqladmin"` |
| `admin_password` | Database admin password | `null` (auto-generated) |
| `sku_name` | PostgreSQL SKU | `"B_Standard_B1ms"` |
| `postgres_version` | PostgreSQL version | `"15"` |
| `storage_mb` | Storage size in MB | `32768` (32 GB) |
| `database_name` | Default database name | `"azurepolicy"` |

## Outputs

### Function App Integration

The module provides several outputs for easy Function App integration:

```hcl
# Full connection string (sensitive)
output "connection_string_full"

# Connection components
output "connection_components" {
  host     = "psql-azpolicy-dev-eastus-001.postgres.database.azure.com"
  port     = "5432"
  database = "azurepolicy"
  username = "psqladmin"
  password = "..." # sensitive
  sslmode  = "require"
}

# Complete configuration for Function Apps
output "database_config_for_functions"
```

### Server Information

```hcl
output "postgresql_server_name"
output "postgresql_server_fqdn"
output "postgresql_server_version"
output "private_endpoint_ip"
```

## Usage Examples

### Basic Deployment

```bash
# Initialize and deploy
make init
make plan
make apply

# Check status
make status
make security-check
make cost-info
```

### Testing Connection

```bash
# Test database connectivity (requires psql)
make test-connection

# Show connection information
make show-connection
make show-components
```

### Integration with Function Apps

After deployment, use the outputs to configure your Function App:

```python
# In your Function App
import os
import psycopg2

# Connection using individual components
conn = psycopg2.connect(
    host=os.environ['DB_HOST'],
    port=os.environ['DB_PORT'],
    database=os.environ['DB_NAME'],
    user=os.environ['DB_USER'],
    password=os.environ['DB_PASSWORD'],
    sslmode='require'
)

# Or using connection string
conn = psycopg2.connect(os.environ['DATABASE_URL'])
```

## Maintenance

### Backup and Recovery

- **Automatic Backups**: 7 days retention (configurable)
- **Point-in-time Recovery**: Available within retention period
- **Manual Backups**: Use Azure CLI or portal

### Updates and Patches

- **Maintenance Window**: Sundays at 2:00 AM UTC (configurable)
- **Automatic Updates**: Minor version updates enabled
- **Major Upgrades**: Manual process required

### Monitoring

```bash
# Check performance metrics
make status

# Security configuration review
make security-check

# Cost analysis
make cost-info
```

## Troubleshooting

### Common Issues

1. **Connection Timeout**
   - Verify VNet integration is working
   - Check private endpoint configuration
   - Ensure Function App is in the correct subnet

2. **Authentication Failed**
   - Verify credentials using `terraform output`
   - Check if password was auto-generated
   - Ensure SSL is properly configured

3. **DNS Resolution Issues**
   - Verify private DNS zone is linked to VNet
   - Check DNS configuration in Function App

### Debug Commands

```bash
# Show all outputs
make output

# Test connectivity
make test-connection

# Check security settings
make security-check

# Validate configuration
make validate
```

## Security Considerations

- **No Public Access**: Database is only accessible via private endpoint
- **SSL Required**: All connections must use SSL/TLS
- **Network Isolation**: Traffic stays within Azure backbone
- **Credential Management**: Passwords are marked as sensitive
- **Firewall Rules**: Only Function subnet has access

## Cost Management

- **Burstable Tier**: Automatically scales down when idle
- **Minimal Storage**: 32 GB starting size (can grow as needed)
- **No High Availability**: Reduces cost by ~50%
- **Local Backup Only**: No geo-redundant backup charges

## Next Steps

1. **Deploy the database module**
2. **Update Function App configuration** with database connection details
3. **Test connectivity** from Function Apps
4. **Set up monitoring** and alerting
5. **Configure backup policies** if needed

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Terraform logs
3. Use `make help` for available commands
4. Check Azure portal for resource status

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.39 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.9 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.39.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.7.2 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.13.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_key_vault_secret.postgres_admin_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.postgres_admin_username](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.postgres_connection_string](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_postgresql_flexible_server.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_configuration.log_min_duration_statement](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.log_statement](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_configuration.shared_preload_libraries](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.additional_databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_database.app_database](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.allowed_cidrs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.dev_access](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_postgresql_flexible_server_firewall_rule.functions_subnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_firewall_rule) | resource |
| [azurerm_private_dns_zone.postgres](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.postgres](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [random_password.postgres_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [time_rotating.keyvault_secret_rotation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/rotating) | resource |
| [azurerm_key_vault.external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.functions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_databases"></a> [additional\_databases](#input\_additional\_databases) | List of additional database names to create | `list(string)` | `[]` | no |
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | Administrator password for PostgreSQL server (if not provided, a random password will be generated) | `string` | `null` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | Administrator username for PostgreSQL server | `string` | `"psqladmin"` | no |
| <a name="input_allowed_cidrs"></a> [allowed\_cidrs](#input\_allowed\_cidrs) | List of CIDR blocks allowed to access the database (in addition to VNet subnets) | `list(string)` | `[]` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Availability zone for the PostgreSQL server (1, 2, 3, or null for no preference) | `string` | `null` | no |
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Backup retention period in days | `number` | `7` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center for resource billing | `string` | `"development"` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the default database to create | `string` | `"azurepolicy"` | no |
| <a name="input_dev_access_ip"></a> [dev\_access\_ip](#input\_dev\_access\_ip) | IP address for development access to the database | `string` | `null` | no |
| <a name="input_enable_keyvault_integration"></a> [enable\_keyvault\_integration](#input\_enable\_keyvault\_integration) | Enable storing database credentials in Key Vault | `bool` | `false` | no |
| <a name="input_enable_performance_insights"></a> [enable\_performance\_insights](#input\_enable\_performance\_insights) | Enable Performance Insights for monitoring | `bool` | `true` | no |
| <a name="input_enable_query_store"></a> [enable\_query\_store](#input\_enable\_query\_store) | Enable Query Store for performance monitoring | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_geo_redundant_backup_enabled"></a> [geo\_redundant\_backup\_enabled](#input\_geo\_redundant\_backup\_enabled) | Enable geo-redundant backup (increases cost) | `bool` | `true` | no |
| <a name="input_keyvault_name"></a> [keyvault\_name](#input\_keyvault\_name) | Name of the existing Key Vault | `string` | `""` | no |
| <a name="input_keyvault_resource_group_name"></a> [keyvault\_resource\_group\_name](#input\_keyvault\_resource\_group\_name) | Resource group name where the Key Vault exists | `string` | `""` | no |
| <a name="input_keyvault_secret_expiration_days"></a> [keyvault\_secret\_expiration\_days](#input\_keyvault\_secret\_expiration\_days) | Number of days until Key Vault secrets expire (90-365 days recommended) | `number` | `90` | no |
| <a name="input_keyvault_secret_names"></a> [keyvault\_secret\_names](#input\_keyvault\_secret\_names) | Names for the secrets to be stored in Key Vault | <pre>object({<br/>    admin_username    = optional(string, "postgres-admin-username")<br/>    admin_password    = optional(string, "postgres-admin-password") # pragma: allowlist secret<br/>    connection_string = optional(string, "postgres-connection-string")<br/>  })</pre> | <pre>{<br/>  "admin_password": "postgres-admin-password",<br/>  "admin_username": "postgres-admin-username",<br/>  "connection_string": "postgres-connection-string"<br/>}</pre> | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for resources | `string` | `"East US"` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | Maintenance window configuration | <pre>object({<br/>    day_of_week  = optional(number, 0) # 0 = Sunday, 1 = Monday, etc.<br/>    start_hour   = optional(number, 2) # Hour in UTC (0-23)<br/>    start_minute = optional(number, 0) # Minute (0-59)<br/>  })</pre> | <pre>{<br/>  "day_of_week": 0,<br/>  "start_hour": 2,<br/>  "start_minute": 0<br/>}</pre> | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources (team name or email) | `string` | `"platform-team"` | no |
| <a name="input_postgres_version"></a> [postgres\_version](#input\_postgres\_version) | PostgreSQL version | `string` | `"15"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the existing resource group | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | SKU name for PostgreSQL Flexible Server | `string` | `"B_Standard_B1ms"` | no |
| <a name="input_storage_mb"></a> [storage\_mb](#input\_storage\_mb) | Storage size in MB for PostgreSQL server | `number` | `32768` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID | `string` | n/a | yes |
| <a name="input_workload"></a> [workload](#input\_workload) | Name of the workload or application | `string` | `"azpolicy"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_additional_database_names"></a> [additional\_database\_names](#output\_additional\_database\_names) | Names of additional databases created |
| <a name="output_connection_components"></a> [connection\_components](#output\_connection\_components) | Individual connection components for Function App configuration |
| <a name="output_connection_string_full"></a> [connection\_string\_full](#output\_connection\_string\_full) | Full PostgreSQL connection string for applications |
| <a name="output_connection_string_template"></a> [connection\_string\_template](#output\_connection\_string\_template) | PostgreSQL connection string template (password placeholder) |
| <a name="output_cost_optimization_info"></a> [cost\_optimization\_info](#output\_cost\_optimization\_info) | Information about cost optimization settings |
| <a name="output_database_config_for_functions"></a> [database\_config\_for\_functions](#output\_database\_config\_for\_functions) | Database configuration summary for Function App integration |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | Name of the default database |
| <a name="output_keyvault_integration"></a> [keyvault\_integration](#output\_keyvault\_integration) | Key Vault integration information |
| <a name="output_monitoring_configuration"></a> [monitoring\_configuration](#output\_monitoring\_configuration) | Monitoring and performance configuration |
| <a name="output_network_configuration"></a> [network\_configuration](#output\_network\_configuration) | Network configuration details |
| <a name="output_postgresql_admin_password"></a> [postgresql\_admin\_password](#output\_postgresql\_admin\_password) | Administrator password for PostgreSQL server |
| <a name="output_postgresql_admin_username"></a> [postgresql\_admin\_username](#output\_postgresql\_admin\_username) | Administrator username for PostgreSQL server |
| <a name="output_postgresql_server_fqdn"></a> [postgresql\_server\_fqdn](#output\_postgresql\_server\_fqdn) | Fully qualified domain name of the PostgreSQL server |
| <a name="output_postgresql_server_id"></a> [postgresql\_server\_id](#output\_postgresql\_server\_id) | ID of the PostgreSQL Flexible Server |
| <a name="output_postgresql_server_name"></a> [postgresql\_server\_name](#output\_postgresql\_server\_name) | Name of the PostgreSQL Flexible Server |
| <a name="output_postgresql_server_version"></a> [postgresql\_server\_version](#output\_postgresql\_server\_version) | PostgreSQL server version |
| <a name="output_private_dns_zone_name"></a> [private\_dns\_zone\_name](#output\_private\_dns\_zone\_name) | Name of the private DNS zone |
| <a name="output_server_configuration"></a> [server\_configuration](#output\_server\_configuration) | PostgreSQL server configuration details |
<!-- END_TF_DOCS -->
