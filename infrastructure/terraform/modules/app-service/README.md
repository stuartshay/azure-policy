# App Service Module

This module creates Azure App Service resources including App Service Plan and Web App.

## Usage

```hcl
module "app_service" {
  source = "./modules/app-service"

  resource_group_name = "rg-example"
  location           = "East US"
  environment        = "dev"
  workload           = "azurepolicy"

  tags = {
    Environment = "dev"
    Project     = "azurepolicy"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| azurerm_service_plan.main | resource |
| azurerm_linux_web_app.main | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| workload | Workload name | `string` | n/a | yes |
| sku_name | App Service Plan SKU | `string` | `"B1"` | no |
| always_on | Should app be always on | `bool` | `false` | no |
| python_version | Python version | `string` | `"3.11"` | no |
| app_settings | App settings | `map(string)` | `{}` | no |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| app_service_id | ID of the App Service |
| app_service_name | Name of the App Service |
| app_service_default_hostname | Default hostname of the App Service |
| app_service_plan_id | ID of the App Service Plan |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.37 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.38.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_linux_web_app.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_web_app) | resource |
| [azurerm_service_plan.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/service_plan) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_settings"></a> [app\_settings](#input\_app\_settings) | App settings for the web app | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The Azure region | `string` | n/a | yes |
| <a name="input_python_version"></a> [python\_version](#input\_python\_version) | The Python version | `string` | `"3.13"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU name for the App Service Plan | `string` | `"B1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_workload"></a> [workload](#input\_workload) | The workload name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_service_default_hostname"></a> [app\_service\_default\_hostname](#output\_app\_service\_default\_hostname) | The default hostname of the App Service |
| <a name="output_app_service_id"></a> [app\_service\_id](#output\_app\_service\_id) | The ID of the App Service |
| <a name="output_app_service_name"></a> [app\_service\_name](#output\_app\_service\_name) | The name of the App Service |
| <a name="output_app_service_plan_id"></a> [app\_service\_plan\_id](#output\_app\_service\_plan\_id) | The ID of the App Service Plan |
<!-- END_TF_DOCS -->
