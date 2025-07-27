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
output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = module.app_service.app_service_plan_id
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = module.app_service.app_service_plan_name
}

output "function_app_ids" {
  description = "Map of Function App names to their IDs"
  value       = module.app_service.function_app_ids
}

output "function_app_names" {
  description = "Map of Function App names"
  value       = module.app_service.function_app_names
}

output "function_app_urls" {
  description = "Map of Function App default hostnames"
  value       = module.app_service.function_app_urls
}

output "storage_account_id" {
  description = "ID of the storage account for Function Apps"
  value       = module.app_service.storage_account_id
}

output "storage_account_name" {
  description = "Name of the storage account for Function Apps"
  value       = module.app_service.storage_account_name
}

output "application_insights_id" {
  description = "ID of Application Insights (if enabled)"
  value       = module.app_service.application_insights_id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key (if enabled)"
  value       = module.app_service.application_insights_instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string (if enabled)"
  value       = module.app_service.application_insights_connection_string
  sensitive   = true
}

# Key Vault Outputs (if enabled)
output "key_vault_id" {
  description = "ID of the Key Vault (if enabled)"
  value       = module.app_service.key_vault_id
}

output "key_vault_name" {
  description = "Name of the Key Vault (if enabled)"
  value       = module.app_service.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault (if enabled)"
  value       = module.app_service.key_vault_uri
}

# Policy Outputs
output "policy_definition_ids" {
  description = "Map of policy definition names to their IDs"
  value       = module.policies.policy_definition_ids
}

output "policy_initiative_id" {
  description = "ID of the policy initiative"
  value       = module.policies.policy_initiative_id
}

output "policy_assignment_ids" {
  description = "Map of policy assignment names to their IDs"
  value       = module.policies.policy_assignment_ids
}

# Managed Identity Outputs
output "managed_identity_id" {
  description = "ID of the user-assigned managed identity"
  value       = module.app_service.managed_identity_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity"
  value       = module.app_service.managed_identity_principal_id
}

output "managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity"
  value       = module.app_service.managed_identity_client_id
}

# Cost Management Outputs
output "budget_id" {
  description = "ID of the cost management budget"
  value       = module.app_service.budget_id
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

# Connection Information for Applications
output "connection_info" {
  description = "Connection information for applications"
  value = {
    resource_group_name = azurerm_resource_group.main.name
    location           = azurerm_resource_group.main.location
    vnet_name          = module.networking.vnet_name
    subnet_ids         = module.networking.subnet_ids
    storage_account_name = module.app_service.storage_account_name
    app_service_plan_name = module.app_service.app_service_plan_name
    function_app_names = module.app_service.function_app_names
    key_vault_name     = module.app_service.key_vault_name
  }
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    timestamp = timestamp()
    environment = var.environment
    location = var.location
    resource_count = {
      resource_group = 1
      virtual_network = 1
      subnets = length(var.subnet_config)
      network_security_groups = length(var.subnet_config)
      app_service_plan = 1
      function_apps = length(var.function_apps)
      storage_account = 1
      application_insights = var.enable_application_insights ? 1 : 0
      key_vault = var.enable_key_vault ? 1 : 0
      managed_identity = 1
      policy_definitions = length(module.policies.policy_definition_ids)
      policy_initiative = 1
      policy_assignments = length(module.policies.policy_assignment_ids)
    }
    estimated_monthly_cost = {
      currency = "USD"
      app_service_plan = var.app_service_plan_sku == "B1" ? 13.14 : 0
      storage_account = 5.00
      application_insights = var.enable_application_insights ? 2.30 : 0
      key_vault = var.enable_key_vault ? 0.03 : 0
      total_estimate = var.app_service_plan_sku == "B1" ? 20.47 : 7.33
    }
  }
}
