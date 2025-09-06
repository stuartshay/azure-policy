# Azure App Service Infrastructure

This Terraform configuration deploys Azure App Service infrastructure with EP1 (Elastic Premium) App Service Plan and VNet integration support. This infrastructure can host Functions, Web Apps, or other Azure App Service applications.

## Features

- **Elastic Premium (EP1) App Service Plan** - Provides dedicated compute with elastic scaling
- **VNet Integration** - Secure network connectivity with dedicated subnet
- **Application Insights** - Monitoring and telemetry
- **Security Hardening** - HTTPS-only, private network access when VNet integrated
- **EP1 Optimizations** - Always-on instances, pre-warmed instances, elastic scaling

## Architecture

The infrastructure creates:
- App Service Plan (EP1 SKU) with elastic scaling capabilities
- Linux Function App with Python 3.11 runtime
- Storage Account for Functions runtime
- Application Insights for monitoring
- VNet Integration for secure network connectivity

## Prerequisites

- Core infrastructure must be deployed first (provides VNet and subnets)
- Functions subnet must exist in the core VNet with proper delegation

## Usage

```bash
# Initialize the workspace
make terraform-app-service-init

# Plan the deployment
make terraform-app-service-plan

# Apply the changes
make terraform-app-service-apply
```

## Configuration

Key variables for EP1 configuration:

- `functions_sku_name`: Set to "EP1" (default)
- `always_ready_instances`: Number of always-ready instances (default: 1)
- `maximum_elastic_worker_count`: Maximum elastic workers (default: 3)
- `enable_vnet_integration`: Enable VNet integration (default: true)

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

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app_service_plan"></a> [app\_service\_plan](#module\_app\_service\_plan) | app.terraform.io/azure-policy-cloud/app-service-plan-function/azurerm | 1.1.65 |

## Resources

| Name | Type |
|------|------|
| [azurerm_app_service_virtual_network_swift_connection.functions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_virtual_network_swift_connection) | resource |
| [azurerm_application_insights.functions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) | resource |
| [azurerm_linux_function_app.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_function_app) | resource |
| [azurerm_storage_account.functions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.functions](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_always_ready_instances"></a> [always\_ready\_instances](#input\_always\_ready\_instances) | Number of always ready instances for EP1 | `number` | `1` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | Cost center for resource billing | `string` | `"development"` | no |
| <a name="input_deploy_function_app"></a> [deploy\_function\_app](#input\_deploy\_function\_app) | Whether to deploy the Function App resource (set to false for infrastructure-only deployment) | `bool` | `false` | no |
| <a name="input_enable_application_insights"></a> [enable\_application\_insights](#input\_enable\_application\_insights) | Enable Application Insights for Functions | `bool` | `false` | no |
| <a name="input_enable_vnet_integration"></a> [enable\_vnet\_integration](#input\_enable\_vnet\_integration) | Enable VNet integration for the Function App | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | `"dev"` | no |
| <a name="input_function_app_settings"></a> [function\_app\_settings](#input\_function\_app\_settings) | Additional app settings for the Function App | `map(string)` | `{}` | no |
| <a name="input_functions_sku_name"></a> [functions\_sku\_name](#input\_functions\_sku\_name) | SKU name for the Functions App Service Plan | `string` | `"EP1"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for resources | `string` | `"East US"` | no |
| <a name="input_maximum_elastic_worker_count"></a> [maximum\_elastic\_worker\_count](#input\_maximum\_elastic\_worker\_count) | Maximum number of elastic workers for EP1 | `number` | `3` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner of the resources (team name or email) | `string` | `"platform-team"` | no |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | Python version for Functions | `string` | `"3.13"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the existing resource group | `string` | n/a | yes |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID | `string` | n/a | yes |
| <a name="input_vnet_integration_subnet_id"></a> [vnet\_integration\_subnet\_id](#input\_vnet\_integration\_subnet\_id) | Subnet ID for VNet integration (required for EP1 SKU) | `string` | `null` | no |
| <a name="input_workload"></a> [workload](#input\_workload) | Name of the workload or application | `string` | `"azpolicy"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_always_ready_instances"></a> [always\_ready\_instances](#output\_always\_ready\_instances) | Number of always ready instances for EP1 |
| <a name="output_app_service_plan_id"></a> [app\_service\_plan\_id](#output\_app\_service\_plan\_id) | ID of the App Service Plan |
| <a name="output_app_service_plan_name"></a> [app\_service\_plan\_name](#output\_app\_service\_plan\_name) | Name of the App Service Plan |
| <a name="output_application_insights_connection_string"></a> [application\_insights\_connection\_string](#output\_application\_insights\_connection\_string) | Application Insights connection string |
| <a name="output_application_insights_instrumentation_key"></a> [application\_insights\_instrumentation\_key](#output\_application\_insights\_instrumentation\_key) | Application Insights instrumentation key |
| <a name="output_function_app_default_hostname"></a> [function\_app\_default\_hostname](#output\_function\_app\_default\_hostname) | Default hostname of the Function App |
| <a name="output_function_app_id"></a> [function\_app\_id](#output\_function\_app\_id) | ID of the Function App |
| <a name="output_function_app_name"></a> [function\_app\_name](#output\_function\_app\_name) | Name of the Function App |
| <a name="output_functions_sku_name"></a> [functions\_sku\_name](#output\_functions\_sku\_name) | SKU name of the App Service Plan |
| <a name="output_maximum_elastic_worker_count"></a> [maximum\_elastic\_worker\_count](#output\_maximum\_elastic\_worker\_count) | Maximum elastic worker count for EP1 |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | Name of the Functions storage account |
| <a name="output_vnet_integration_enabled"></a> [vnet\_integration\_enabled](#output\_vnet\_integration\_enabled) | Whether VNet integration is enabled |
| <a name="output_vnet_integration_subnet_id"></a> [vnet\_integration\_subnet\_id](#output\_vnet\_integration\_subnet\_id) | Subnet ID used for VNet integration |
<!-- END_TF_DOCS -->
