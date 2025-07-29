# Policies Module

This module creates Azure Policy definitions and assignments for governance.

## Usage

```hcl
module "policies" {
  source = "./modules/policies"

  resource_group_id = "/subscriptions/xxx/resourceGroups/rg-example"
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
| azurerm_policy_definition.resource_group_naming | resource |
| azurerm_policy_definition.storage_naming | resource |
| azurerm_resource_group_policy_assignment.resource_group_naming | resource |
| azurerm_resource_group_policy_assignment.storage_naming | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_id | ID of the resource group | `string` | n/a | yes |
| enable_policy_assignments | Enable policy assignments | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_naming_policy_id | ID of the resource group naming policy |
| storage_naming_policy_id | ID of the storage naming policy |
| resource_group_naming_assignment_id | ID of the resource group naming assignment |
| storage_naming_assignment_id | ID of the storage naming assignment |
