# Networking Module

This module creates Azure networking resources including VNet, subnets, and network security groups.

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  resource_group_name = "rg-example"
  location           = "East US"
  environment        = "dev"
  workload           = "azurepolicy"
  location_short     = "eastus"

  vnet_address_space = ["10.0.0.0/16"]
  subnet_config = {
    default = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = []
    }
  }

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
| azurerm_virtual_network.main | resource |
| azurerm_subnet.main | resource |
| azurerm_network_security_group.main | resource |
| azurerm_network_security_rule.* | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| workload | Workload name | `string` | n/a | yes |
| location_short | Short name for Azure region | `string` | n/a | yes |
| vnet_address_space | Address space for VNet | `list(string)` | n/a | yes |
| subnet_config | Subnet configuration | `map(object)` | n/a | yes |
| tags | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | ID of the virtual network |
| vnet_name | Name of the virtual network |
| subnet_ids | Map of subnet IDs |
| nsg_ids | Map of NSG IDs |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.39 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.38.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_rule.allow_app_service_management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_dns_outbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_function_app_management](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_https_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.allow_https_outbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_security_rule.deny_http_inbound](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule) | resource |
| [azurerm_network_watcher.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher) | resource |
| [azurerm_network_watcher_flow_log.nsg_legacy](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_network_watcher_flow_log.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_watcher_flow_log) | resource |
| [azurerm_route.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route) | resource |
| [azurerm_route_table.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table) | resource |
| [azurerm_storage_account.flow_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_subnet.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_route_table_association.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_custom_routes"></a> [enable\_custom\_routes](#input\_enable\_custom\_routes) | Enable custom route table and routes | `bool` | `false` | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Enable VNet flow logs (requires Network Watcher) | `bool` | `false` | no |
| <a name="input_enable_legacy_nsg_flow_logs"></a> [enable\_legacy\_nsg\_flow\_logs](#input\_enable\_legacy\_nsg\_flow\_logs) | Enable legacy NSG flow logs alongside VNet flow logs (deprecated - will be retired Sept 30, 2027) | `bool` | `false` | no |
| <a name="input_enable_network_watcher"></a> [enable\_network\_watcher](#input\_enable\_network\_watcher) | Enable Network Watcher for monitoring and diagnostics | `bool` | `false` | no |
| <a name="input_enable_traffic_analytics"></a> [enable\_traffic\_analytics](#input\_enable\_traffic\_analytics) | Enable traffic analytics for flow logs | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_flow_log_retention_days"></a> [flow\_log\_retention\_days](#input\_flow\_log\_retention\_days) | Number of days to retain flow logs | `number` | `91` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for networking resources | `string` | n/a | yes |
| <a name="input_location_short"></a> [location\_short](#input\_location\_short) | Short name for the Azure region | `string` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | Log Analytics workspace ID for traffic analytics | `string` | `null` | no |
| <a name="input_log_analytics_workspace_resource_id"></a> [log\_analytics\_workspace\_resource\_id](#input\_log\_analytics\_workspace\_resource\_id) | Log Analytics workspace resource ID for traffic analytics | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where networking resources will be created | `string` | n/a | yes |
| <a name="input_subnet_config"></a> [subnet\_config](#input\_subnet\_config) | Configuration for subnets | <pre>map(object({<br/>    address_prefixes  = list(string)<br/>    service_endpoints = optional(list(string), [])<br/>    delegation = optional(object({<br/>      name = string<br/>      service_delegation = object({<br/>        name    = string<br/>        actions = optional(list(string), [])<br/>      })<br/>    }), null)<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all networking resources | `map(string)` | `{}` | no |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | Address space for the virtual network | `list(string)` | n/a | yes |
| <a name="input_workload"></a> [workload](#input\_workload) | Workload name for resource naming | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_service_subnet_id"></a> [app\_service\_subnet\_id](#output\_app\_service\_subnet\_id) | ID of the App Service subnet (if exists) |
| <a name="output_app_service_subnet_name"></a> [app\_service\_subnet\_name](#output\_app\_service\_subnet\_name) | Name of the App Service subnet (if exists) |
| <a name="output_connectivity_info"></a> [connectivity\_info](#output\_connectivity\_info) | Information for connecting other resources to the network |
| <a name="output_flow_logs_storage_account_id"></a> [flow\_logs\_storage\_account\_id](#output\_flow\_logs\_storage\_account\_id) | ID of the flow logs storage account (if enabled) |
| <a name="output_flow_logs_storage_account_name"></a> [flow\_logs\_storage\_account\_name](#output\_flow\_logs\_storage\_account\_name) | Name of the flow logs storage account (if enabled) |
| <a name="output_flow_logs_storage_account_primary_blob_endpoint"></a> [flow\_logs\_storage\_account\_primary\_blob\_endpoint](#output\_flow\_logs\_storage\_account\_primary\_blob\_endpoint) | Primary blob endpoint of the flow logs storage account (if enabled) |
| <a name="output_functions_subnet_id"></a> [functions\_subnet\_id](#output\_functions\_subnet\_id) | ID of the Functions subnet (if exists) |
| <a name="output_functions_subnet_name"></a> [functions\_subnet\_name](#output\_functions\_subnet\_name) | Name of the Functions subnet (if exists) |
| <a name="output_legacy_nsg_flow_log_ids"></a> [legacy\_nsg\_flow\_log\_ids](#output\_legacy\_nsg\_flow\_log\_ids) | Map of legacy NSG flow log names to their IDs (deprecated - if enabled) |
| <a name="output_network_watcher_id"></a> [network\_watcher\_id](#output\_network\_watcher\_id) | ID of the Network Watcher (if enabled) |
| <a name="output_network_watcher_name"></a> [network\_watcher\_name](#output\_network\_watcher\_name) | Name of the Network Watcher (if enabled) |
| <a name="output_networking_summary"></a> [networking\_summary](#output\_networking\_summary) | Summary of networking configuration |
| <a name="output_nsg_ids"></a> [nsg\_ids](#output\_nsg\_ids) | Map of NSG names to their IDs |
| <a name="output_nsg_locations"></a> [nsg\_locations](#output\_nsg\_locations) | Map of NSG names to their locations |
| <a name="output_nsg_names"></a> [nsg\_names](#output\_nsg\_names) | Map of NSG keys to their actual names |
| <a name="output_private_endpoints_subnet_id"></a> [private\_endpoints\_subnet\_id](#output\_private\_endpoints\_subnet\_id) | ID of the Private Endpoints subnet (if exists) |
| <a name="output_private_endpoints_subnet_name"></a> [private\_endpoints\_subnet\_name](#output\_private\_endpoints\_subnet\_name) | Name of the Private Endpoints subnet (if exists) |
| <a name="output_resource_names"></a> [resource\_names](#output\_resource\_names) | Map of all created resource names for reference |
| <a name="output_route_table_id"></a> [route\_table\_id](#output\_route\_table\_id) | ID of the route table (if enabled) |
| <a name="output_route_table_name"></a> [route\_table\_name](#output\_route\_table\_name) | Name of the route table (if enabled) |
| <a name="output_security_summary"></a> [security\_summary](#output\_security\_summary) | Summary of network security configuration |
| <a name="output_subnet_address_prefixes"></a> [subnet\_address\_prefixes](#output\_subnet\_address\_prefixes) | Map of subnet names to their address prefixes |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet names to their IDs |
| <a name="output_subnet_names"></a> [subnet\_names](#output\_subnet\_names) | Map of subnet keys to their actual names |
| <a name="output_subnet_nsg_associations"></a> [subnet\_nsg\_associations](#output\_subnet\_nsg\_associations) | Map of subnet names to their NSG association IDs |
| <a name="output_subnet_route_table_associations"></a> [subnet\_route\_table\_associations](#output\_subnet\_route\_table\_associations) | Map of subnet names to their route table association IDs (if enabled) |
| <a name="output_subnet_service_endpoints"></a> [subnet\_service\_endpoints](#output\_subnet\_service\_endpoints) | Map of subnet names to their service endpoints |
| <a name="output_vnet_address_space"></a> [vnet\_address\_space](#output\_vnet\_address\_space) | Address space of the virtual network |
| <a name="output_vnet_flow_log_id"></a> [vnet\_flow\_log\_id](#output\_vnet\_flow\_log\_id) | ID of the VNet flow log (if enabled) |
| <a name="output_vnet_flow_log_name"></a> [vnet\_flow\_log\_name](#output\_vnet\_flow\_log\_name) | Name of the VNet flow log (if enabled) |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | ID of the created virtual network |
| <a name="output_vnet_location"></a> [vnet\_location](#output\_vnet\_location) | Location of the virtual network |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | Name of the created virtual network |
| <a name="output_vnet_resource_group_name"></a> [vnet\_resource\_group\_name](#output\_vnet\_resource\_group\_name) | Resource group name of the virtual network |
<!-- END_TF_DOCS -->
