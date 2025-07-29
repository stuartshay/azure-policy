output "resource_group_naming_policy_id" {
  description = "The ID of the resource group naming policy definition"
  value       = azurerm_policy_definition.resource_group_naming.id
}

output "storage_naming_policy_id" {
  description = "The ID of the storage naming policy definition"
  value       = azurerm_policy_definition.storage_naming.id
}

output "resource_group_naming_assignment_id" {
  description = "The ID of the resource group naming policy assignment"
  value       = var.enable_policy_assignments ? azurerm_resource_group_policy_assignment.resource_group_naming[0].id : null
}

output "storage_naming_assignment_id" {
  description = "The ID of the storage naming policy assignment"
  value       = var.enable_policy_assignments ? azurerm_resource_group_policy_assignment.storage_naming[0].id : null
}
