# Azure Function App Deployment

This module deploys the actual Azure Function App that depends on the app-service infrastructure. It's designed as a separate deployment to allow for independent Function App lifecycle management.

## Prerequisites

1. **App Service Infrastructure**: The `app-service` module must be deployed first
   ```bash
   # From project root
   make terraform-app-service-apply
   ```

2. **Azure CLI**: Must be logged in and have appropriate permissions
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

## Architecture

This module creates:
- **Azure Function App**: Linux-based Python Function App
- **Dependencies**: References existing App Service Plan, Storage Account, and Application Insights

## Dependencies

This module depends on outputs from the `app-service` module:
- App Service Plan ID
- Storage Account name and connection string
- Application Insights connection string and instrumentation key
- VNet integration configuration (if enabled)

## Configuration

### Key Variables (terraform.tfvars)

```hcl
# Must match app-service module configuration
subscription_id         = "your-subscription-id"
resource_group_name    = "rg-azpolicy-dev-eastus"
environment           = "dev"
workload              = "azpolicy"
functions_sku_name    = "EP1"
python_version        = "3.11"

# Function App specific settings
function_app_settings = {
  "ENVIRONMENT" = "dev"
  "LOG_LEVEL"   = "INFO"
}
```

## Deployment

### Using Makefile (Recommended)

```bash
# Quick deployment
make quick-deploy

# Step by step
make init      # Initialize Terraform
make plan      # Review deployment plan
make apply     # Deploy Function App
make status    # Check deployment status
```

### Using Terraform directly

```bash
terraform init
terraform plan
terraform apply
```

## Management

### View Function App Status
```bash
make status
```

### Update Function App
```bash
# After making changes
make plan
make apply
```

### Destroy Function App
```bash
make destroy  # Keeps app-service infrastructure
```

## Outputs

After deployment, the module provides:

- `function_app_name`: Name of the deployed Function App
- `function_app_url`: URL of the Function App
- `function_app_id`: Azure resource ID
- `app_settings_summary`: Key configuration settings

## Function App Configuration

The Function App is configured with:

### Runtime Settings
- **Runtime**: Python
- **Version**: Configurable (default: 3.11)
- **Extension Version**: ~4
- **Always On**: Enabled for non-consumption plans

### EP1 Premium Plan Features
- **Pre-warmed Instances**: Configurable always-ready instances
- **Elastic Scaling**: Up to configured maximum workers
- **VNet Integration**: If enabled in app-service module

### Storage Configuration
- **AzureWebJobsStorage**: Uses storage account from app-service module
- **Content Share**: Dedicated file share for Function App content

### Monitoring
- **Application Insights**: Uses instance from app-service module
- **Connection String**: Automatically configured
- **Instrumentation Key**: Automatically configured

## File Structure

```
functions-app/
├── main.tf           # Main Terraform configuration
├── variables.tf      # Variable definitions
├── outputs.tf        # Output definitions
├── terraform.tfvars  # Variable values
├── Makefile         # Automation commands
└── README.md        # This file
```

## Troubleshooting

### Common Issues

1. **App Service Not Found**
   ```
   Error: App Service infrastructure not found
   Solution: Deploy app-service module first
   ```

2. **Storage Account Access**
   ```
   Error: Cannot access storage account
   Solution: Ensure app-service module is properly deployed
   ```

3. **VNet Integration Issues**
   ```
   Error: Subnet not available for VNet integration
   Solution: Check app-service VNet configuration
   ```

### Debugging Commands

```bash
# Check prerequisites
make check-prerequisites

# Validate configuration
make validate

# View current state
terraform show

# View remote state
terraform state pull
```

## Integration with CI/CD

This module is designed to work with CI/CD pipelines:

1. **Infrastructure Pipeline**: Deploys app-service module
2. **Application Pipeline**: Deploys Function App using this module
3. **Code Pipeline**: Deploys function code to the Function App

## Security Considerations

- Function App uses managed identity when possible
- Storage account access keys are managed by Terraform
- Application Insights keys are marked as sensitive
- VNet integration provides network isolation

## Cost Optimization

- EP1 plan allows for elastic scaling
- Pre-warmed instances minimize cold starts
- Always-on ensures consistent performance
- Elastic scaling optimizes costs during low usage

## Next Steps

After deploying the Function App:

1. Deploy your function code using Azure Functions Core Tools or CI/CD
2. Configure custom domains and SSL certificates if needed
3. Set up monitoring and alerting
4. Configure authentication and authorization

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.42.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.42.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_function_app.advanced](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app.basic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_linux_function_app.infrastructure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_role_assignment.infrastructure_keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.infrastructure_servicebus](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_key_vault.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_storage_account.functions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/storage_account) | data source |
| [terraform_remote_state.app_service](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_advanced_function_app_settings"></a> [advanced\_function\_app\_settings](#input\_advanced\_function\_app\_settings) | Additional app settings for the Advanced Function App | `map(string)` | `{}` | no |
| <a name="input_always_ready_instances"></a> [always\_ready\_instances](#input\_always\_ready\_instances) | Number of always ready instances for EP1 (must match app-service module) | `number` | `1` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center for resource billing | `string` | `"development"` | no |
| <a name="input_enable_infrastructure_function"></a> [enable\_infrastructure\_function](#input\_enable\_infrastructure\_function) | Enable the infrastructure function for secret rotation | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_function_app_settings"></a> [function\_app\_settings](#input\_function\_app\_settings) | Additional app settings for the Basic Function App | `map(string)` | `{}` | no |
| <a name="input_functions_sku_name"></a> [functions\_sku\_name](#input\_functions\_sku\_name) | SKU name for the Functions App Service Plan (must match app-service module) | `string` | `"EP1"` | no |
| <a name="input_infrastructure_function_app_settings"></a> [infrastructure\_function\_app\_settings](#input\_infrastructure\_function\_app\_settings) | Additional app settings for the Infrastructure Function App | `map(string)` | `{}` | no |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | Name of the Key Vault for secret storage | `string` | `""` | no |
| <a name="input_key_vault_resource_group_name"></a> [key\_vault\_resource\_group\_name](#input\_key\_vault\_resource\_group\_name) | Resource group name containing the Key Vault | `string` | `""` | no |
| <a name="input_maximum_elastic_worker_count"></a> [maximum\_elastic\_worker\_count](#input\_maximum\_elastic\_worker\_count) | Maximum number of elastic workers for EP1 (must match app-service module) | `number` | `3` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources (team name or email) | `string` | `"platform-team"` | no |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | Python version for Functions | `string` | `"3.13"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the existing resource group (created by app-service module) | `string` | n/a | yes |
| <a name="input_rotate_admin_access"></a> [rotate\_admin\_access](#input\_rotate\_admin\_access) | Include admin access rule in rotation | `string` | `"false"` | no |
| <a name="input_rotation_enabled"></a> [rotation\_enabled](#input\_rotation\_enabled) | Enable automatic secret rotation | `string` | `"true"` | no |
| <a name="input_service_bus_namespace_name"></a> [service\_bus\_namespace\_name](#input\_service\_bus\_namespace\_name) | Name of the Service Bus namespace | `string` | `""` | no |
| <a name="input_service_bus_resource_group_name"></a> [service\_bus\_resource\_group\_name](#input\_service\_bus\_resource\_group\_name) | Resource group name containing the Service Bus namespace | `string` | `""` | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID | `string` | n/a | yes |
| <a name="input_workload"></a> [workload](#input\_workload) | Name of the workload or application | `string` | `"azpolicy"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_advanced_function_app_default_hostname"></a> [advanced\_function\_app\_default\_hostname](#output\_advanced\_function\_app\_default\_hostname) | Default hostname of the Advanced Function App |
| <a name="output_advanced_function_app_id"></a> [advanced\_function\_app\_id](#output\_advanced\_function\_app\_id) | ID of the Advanced Function App |
| <a name="output_advanced_function_app_name"></a> [advanced\_function\_app\_name](#output\_advanced\_function\_app\_name) | Name of the Advanced Function App |
| <a name="output_advanced_function_app_url"></a> [advanced\_function\_app\_url](#output\_advanced\_function\_app\_url) | URL of the Advanced Function App |
| <a name="output_app_settings_summary"></a> [app\_settings\_summary](#output\_app\_settings\_summary) | Summary of key app settings |
| <a name="output_basic_function_app_default_hostname"></a> [basic\_function\_app\_default\_hostname](#output\_basic\_function\_app\_default\_hostname) | Default hostname of the Basic Function App |
| <a name="output_basic_function_app_id"></a> [basic\_function\_app\_id](#output\_basic\_function\_app\_id) | ID of the Basic Function App |
| <a name="output_basic_function_app_name"></a> [basic\_function\_app\_name](#output\_basic\_function\_app\_name) | Name of the Basic Function App |
| <a name="output_basic_function_app_url"></a> [basic\_function\_app\_url](#output\_basic\_function\_app\_url) | URL of the Basic Function App |
| <a name="output_function_app_default_hostname"></a> [function\_app\_default\_hostname](#output\_function\_app\_default\_hostname) | Default hostname of the Function App (legacy - points to basic) |
| <a name="output_function_app_id"></a> [function\_app\_id](#output\_function\_app\_id) | ID of the deployed Function App (legacy - points to basic) |
| <a name="output_function_app_kind"></a> [function\_app\_kind](#output\_function\_app\_kind) | Kind of the Function App (legacy - points to basic) |
| <a name="output_function_app_name"></a> [function\_app\_name](#output\_function\_app\_name) | Name of the deployed Function App (legacy - points to basic) |
| <a name="output_function_app_url"></a> [function\_app\_url](#output\_function\_app\_url) | URL of the Function App (legacy - points to basic) |
| <a name="output_function_apps_summary"></a> [function\_apps\_summary](#output\_function\_apps\_summary) | Summary of both function apps |
| <a name="output_infrastructure_function_app_hostname"></a> [infrastructure\_function\_app\_hostname](#output\_infrastructure\_function\_app\_hostname) | Hostname of the Infrastructure Function App |
| <a name="output_infrastructure_function_app_id"></a> [infrastructure\_function\_app\_id](#output\_infrastructure\_function\_app\_id) | ID of the Infrastructure Function App |
| <a name="output_infrastructure_function_app_identity_principal_id"></a> [infrastructure\_function\_app\_identity\_principal\_id](#output\_infrastructure\_function\_app\_identity\_principal\_id) | Principal ID of the Infrastructure Function App managed identity |
| <a name="output_infrastructure_function_app_name"></a> [infrastructure\_function\_app\_name](#output\_infrastructure\_function\_app\_name) | Name of the Infrastructure Function App |
| <a name="output_infrastructure_function_enabled"></a> [infrastructure\_function\_enabled](#output\_infrastructure\_function\_enabled) | Whether the infrastructure function is enabled |
| <a name="output_python_version"></a> [python\_version](#output\_python\_version) | Python version used by the Function Apps |
| <a name="output_service_plan_id"></a> [service\_plan\_id](#output\_service\_plan\_id) | ID of the App Service Plan used by the Function Apps |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the storage account used by the Function Apps |
<!-- END_TF_DOCS -->
