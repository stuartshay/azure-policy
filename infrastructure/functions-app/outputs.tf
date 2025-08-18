# Azure Function App Deployment - Outputs
# This file defines outputs from the Function App deployment

# Basic Function App Outputs
output "basic_function_app_name" {
  description = "Name of the Basic Function App"
  value       = azurerm_linux_function_app.basic.name
}

output "basic_function_app_id" {
  description = "ID of the Basic Function App"
  value       = azurerm_linux_function_app.basic.id
}

output "basic_function_app_default_hostname" {
  description = "Default hostname of the Basic Function App"
  value       = azurerm_linux_function_app.basic.default_hostname
}

output "basic_function_app_url" {
  description = "URL of the Basic Function App"
  value       = "https://${azurerm_linux_function_app.basic.default_hostname}"
}

# Advanced Function App Outputs
output "advanced_function_app_name" {
  description = "Name of the Advanced Function App"
  value       = azurerm_linux_function_app.advanced.name
}

output "advanced_function_app_id" {
  description = "ID of the Advanced Function App"
  value       = azurerm_linux_function_app.advanced.id
}

output "advanced_function_app_default_hostname" {
  description = "Default hostname of the Advanced Function App"
  value       = azurerm_linux_function_app.advanced.default_hostname
}

output "advanced_function_app_url" {
  description = "URL of the Advanced Function App"
  value       = "https://${azurerm_linux_function_app.advanced.default_hostname}"
}

# Legacy outputs for backwards compatibility (pointing to basic function app)
output "function_app_name" {
  description = "Name of the deployed Function App (legacy - points to basic)"
  value       = azurerm_linux_function_app.basic.name
}

output "function_app_id" {
  description = "ID of the deployed Function App (legacy - points to basic)"
  value       = azurerm_linux_function_app.basic.id
}

output "function_app_default_hostname" {
  description = "Default hostname of the Function App (legacy - points to basic)"
  value       = azurerm_linux_function_app.basic.default_hostname
}

output "function_app_url" {
  description = "URL of the Function App (legacy - points to basic)"
  value       = "https://${azurerm_linux_function_app.basic.default_hostname}"
}

output "function_app_kind" {
  description = "Kind of the Function App (legacy - points to basic)"
  value       = azurerm_linux_function_app.basic.kind
}

# Shared infrastructure outputs
output "service_plan_id" {
  description = "ID of the App Service Plan used by the Function Apps"
  value       = azurerm_linux_function_app.basic.service_plan_id
}

output "storage_account_name" {
  description = "Name of the storage account used by the Function Apps"
  value       = azurerm_linux_function_app.basic.storage_account_name
}

output "python_version" {
  description = "Python version used by the Function Apps"
  value       = var.python_version
}

output "app_settings_summary" {
  description = "Summary of key app settings"
  value = {
    runtime_version      = azurerm_linux_function_app.basic.app_settings["FUNCTIONS_EXTENSION_VERSION"]
    worker_runtime       = azurerm_linux_function_app.basic.app_settings["FUNCTIONS_WORKER_RUNTIME"]
    python_version       = azurerm_linux_function_app.basic.app_settings["PYTHON_VERSION"]
    always_on            = azurerm_linux_function_app.basic.site_config[0].always_on
    pre_warmed_instances = azurerm_linux_function_app.basic.site_config[0].pre_warmed_instance_count
  }
}

# Summary of both function apps
output "function_apps_summary" {
  description = "Summary of both function apps"
  value = {
    basic = {
      name = azurerm_linux_function_app.basic.name
      url  = "https://${azurerm_linux_function_app.basic.default_hostname}"
    }
    advanced = {
      name = azurerm_linux_function_app.advanced.name
      url  = "https://${azurerm_linux_function_app.advanced.default_hostname}"
    }
  }
}
