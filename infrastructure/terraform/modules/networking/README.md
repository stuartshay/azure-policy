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
