# Azure Infrastructure - Outputs
# This file defines outputs from the core infrastructure

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value       = module.networking.subnet_ids
}

output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value       = module.networking.nsg_ids
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "location" {
  description = "Azure location"
  value       = var.location
}

output "storage_account_id" {
  description = "ID of the storage account for logs"
  value       = module.networking.flow_logs_storage_account_id
}

output "storage_account_name" {
  description = "Name of the storage account for logs"
  value       = module.networking.flow_logs_storage_account_name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = module.networking.flow_logs_storage_account_primary_blob_endpoint
}
