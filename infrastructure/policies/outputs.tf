# Azure Policy - Outputs
# This file defines outputs from the Azure Policy configuration

output "resource_group_naming_policy_id" {
  description = "ID of the resource group naming policy"
  value       = module.policies.resource_group_naming_policy_id
}

output "storage_naming_policy_id" {
  description = "ID of the storage naming policy"
  value       = module.policies.storage_naming_policy_id
}
