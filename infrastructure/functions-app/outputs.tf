# Azure Function App Deployment - Outputs
# This file defines outputs from the Function App deployment

output "function_app_name" {
  description = "Name of the deployed Function App"
  value       = azurerm_linux_function_app.main.name
}

output "function_app_id" {
  description = "ID of the deployed Function App"
  value       = azurerm_linux_function_app.main.id
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_linux_function_app.main.default_hostname
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${azurerm_linux_function_app.main.default_hostname}"
}

output "function_app_kind" {
  description = "Kind of the Function App"
  value       = azurerm_linux_function_app.main.kind
}

output "service_plan_id" {
  description = "ID of the App Service Plan used by the Function App"
  value       = azurerm_linux_function_app.main.service_plan_id
}

output "storage_account_name" {
  description = "Name of the storage account used by the Function App"
  value       = azurerm_linux_function_app.main.storage_account_name
}

output "python_version" {
  description = "Python version used by the Function App"
  value       = var.python_version
}

output "app_settings_summary" {
  description = "Summary of key app settings"
  value = {
    runtime_version      = azurerm_linux_function_app.main.app_settings["FUNCTIONS_EXTENSION_VERSION"]
    worker_runtime       = azurerm_linux_function_app.main.app_settings["FUNCTIONS_WORKER_RUNTIME"]
    python_version       = azurerm_linux_function_app.main.app_settings["PYTHON_VERSION"]
    always_on            = azurerm_linux_function_app.main.site_config[0].always_on
    pre_warmed_instances = azurerm_linux_function_app.main.site_config[0].pre_warmed_instance_count
  }
}
