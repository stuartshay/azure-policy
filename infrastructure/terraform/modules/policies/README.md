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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
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
| [azurerm_policy_definition.resource_group_naming](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) | resource |
| [azurerm_policy_definition.storage_naming](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/policy_definition) | resource |
| [azurerm_resource_group_policy_assignment.resource_group_naming](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |
| [azurerm_resource_group_policy_assignment.storage_naming](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_policy_assignment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_policy_assignments"></a> [enable\_policy\_assignments](#input\_enable\_policy\_assignments) | Whether to enable policy assignments | `bool` | `true` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The ID of the resource group for policy assignments | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_group_naming_assignment_id"></a> [resource\_group\_naming\_assignment\_id](#output\_resource\_group\_naming\_assignment\_id) | The ID of the resource group naming policy assignment |
| <a name="output_resource_group_naming_policy_id"></a> [resource\_group\_naming\_policy\_id](#output\_resource\_group\_naming\_policy\_id) | The ID of the resource group naming policy definition |
| <a name="output_storage_naming_assignment_id"></a> [storage\_naming\_assignment\_id](#output\_storage\_naming\_assignment\_id) | The ID of the storage naming policy assignment |
| <a name="output_storage_naming_policy_id"></a> [storage\_naming\_policy\_id](#output\_storage\_naming\_policy\_id) | The ID of the storage naming policy definition |
<!-- END_TF_DOCS -->
