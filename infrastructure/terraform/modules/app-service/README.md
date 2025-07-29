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
