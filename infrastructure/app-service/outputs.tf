# Azure Functions - Outputs
# This file defines outputs from the Azure Functions infrastructure

output "function_app_name" {
  description = "Name of the Function App"
  value       = var.deploy_function_app ? azurerm_linux_function_app.main[0].name : null
}

output "function_app_id" {
  description = "ID of the Function App"
  value       = var.deploy_function_app ? azurerm_linux_function_app.main[0].id : null
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = var.deploy_function_app ? azurerm_linux_function_app.main[0].default_hostname : null
}

output "storage_account_name" {
  description = "Name of the Functions storage account"
  value       = azurerm_storage_account.functions.name
}

output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = module.app_service_plan.app_service_plan_id
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = module.app_service_plan.app_service_plan_name
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = var.enable_application_insights ? azurerm_application_insights.functions[0].connection_string : null
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = var.enable_application_insights ? azurerm_application_insights.functions[0].instrumentation_key : null
  sensitive   = true
}

output "vnet_integration_enabled" {
  description = "Whether VNet integration is enabled"
  value       = var.enable_vnet_integration
}

output "vnet_integration_subnet_id" {
  description = "Subnet ID used for VNet integration"
  value       = var.enable_vnet_integration ? (var.vnet_integration_subnet_id != null ? var.vnet_integration_subnet_id : data.azurerm_subnet.functions[0].id) : null
}

output "functions_sku_name" {
  description = "SKU name of the App Service Plan"
  value       = var.functions_sku_name
}

output "maximum_elastic_worker_count" {
  description = "Maximum elastic worker count for EP1"
  value       = var.functions_sku_name == "EP1" ? var.maximum_elastic_worker_count : null
}

output "always_ready_instances" {
  description = "Number of always ready instances for EP1"
  value       = var.functions_sku_name == "EP1" ? var.always_ready_instances : null
}
