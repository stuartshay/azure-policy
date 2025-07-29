# Azure Policy Infrastructure - Outputs
# This file defines all output values from the infrastructure

# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Location of the created resource group"
  value       = azurerm_resource_group.main.location
}

# Networking Outputs
output "vnet_id" {
  description = "ID of the created virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the created virtual network"
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

# App Service Outputs
output "app_service_id" {
  description = "ID of the App Service"
  value       = module.app_service.app_service_id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = module.app_service.app_service_name
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = module.app_service.app_service_default_hostname
}

output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = module.app_service.app_service_plan_id
}

# Policy Outputs
output "resource_group_naming_policy_id" {
  description = "ID of the resource group naming policy"
  value       = module.policies.resource_group_naming_policy_id
}

output "storage_naming_policy_id" {
  description = "ID of the storage naming policy"
  value       = module.policies.storage_naming_policy_id
}

# Environment Information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "location" {
  description = "Azure region"
  value       = var.location
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}
