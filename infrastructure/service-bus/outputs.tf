# Azure Service Bus - Outputs
# This file defines outputs from the Azure Service Bus infrastructure

output "service_bus_namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.name
}

output "service_bus_namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.id
}

output "service_bus_namespace_hostname" {
  description = "Service Bus namespace hostname"
  value       = azurerm_servicebus_namespace.main.default_primary_connection_string
  sensitive   = true
}

output "function_app_connection_string" {
  description = "Connection string for Function App access to Service Bus"
  value       = azurerm_servicebus_namespace_authorization_rule.function_app_access.primary_connection_string
  sensitive   = true
}

output "function_app_connection_string_key_name" {
  description = "Key name for Function App Service Bus access"
  value       = azurerm_servicebus_namespace_authorization_rule.function_app_access.name
}

output "read_only_connection_string" {
  description = "Read-only connection string for monitoring/reporting"
  value       = azurerm_servicebus_namespace_authorization_rule.read_only.primary_connection_string
  sensitive   = true
}

output "service_bus_sku" {
  description = "SKU of the Service Bus namespace"
  value       = var.service_bus_sku
}

output "queue_names" {
  description = "List of created queue names"
  value       = keys(azurerm_servicebus_queue.queues)
}

output "topic_names" {
  description = "List of created topic names"
  value       = keys(azurerm_servicebus_topic.topics)
}

output "subscription_names" {
  description = "Map of topic subscriptions"
  value = {
    "policy-events"      = azurerm_servicebus_subscription.policy_events_all.name
    "compliance-reports" = azurerm_servicebus_subscription.compliance_reports_all.name
  }
}

output "private_endpoint_enabled" {
  description = "Whether private endpoint is enabled"
  value       = var.enable_private_endpoint
}

output "private_endpoint_ip" {
  description = "Private endpoint IP address (if enabled)"
  value       = var.enable_private_endpoint ? module.service_bus_private_endpoint[0].private_ip_address : null
}

output "private_endpoint_id" {
  description = "Private endpoint ID (if enabled)"
  value       = var.enable_private_endpoint ? module.service_bus_private_endpoint[0].id : null
}

output "private_endpoint_fqdn" {
  description = "Private endpoint FQDN (if enabled)"
  value       = var.enable_private_endpoint ? module.service_bus_private_endpoint[0].fqdn : null
}

output "private_endpoint_details" {
  description = "Complete private endpoint details (if enabled)"
  value = var.enable_private_endpoint ? {
    id                 = module.service_bus_private_endpoint[0].id
    name               = module.service_bus_private_endpoint[0].name
    private_ip_address = module.service_bus_private_endpoint[0].private_ip_address
    fqdn               = module.service_bus_private_endpoint[0].fqdn
    subnet_id          = module.service_bus_private_endpoint[0].subnet_id
    dns_configs        = module.service_bus_private_endpoint[0].custom_dns_configs
  } : null
}

output "zone_redundancy_enabled" {
  description = "Whether zone redundancy is enabled"
  value       = var.service_bus_sku == "Premium" ? var.enable_zone_redundancy : false
}

# Outputs for Function App integration
output "service_bus_config_for_functions" {
  description = "Service Bus configuration summary for Function App integration"
  value = {
    namespace_name    = azurerm_servicebus_namespace.main.name
    connection_string = azurerm_servicebus_namespace_authorization_rule.function_app_access.primary_connection_string
    queue_names       = keys(azurerm_servicebus_queue.queues)
    topic_names       = keys(azurerm_servicebus_topic.topics)
    sku               = var.service_bus_sku
    private_endpoint  = var.enable_private_endpoint
  }
  sensitive = true
}

# Key Vault integration outputs
output "keyvault_integration" {
  description = "Key Vault integration information"
  value = var.enable_keyvault_integration ? {
    enabled                 = true
    keyvault_name           = var.keyvault_name
    keyvault_resource_group = var.keyvault_resource_group_name
    secret_names = {
      namespace_connection_string    = var.keyvault_secret_names.namespace_connection_string
      function_app_connection_string = var.keyvault_secret_names.function_app_connection_string
      read_only_connection_string    = var.keyvault_secret_names.read_only_connection_string
      admin_connection_string        = var.keyvault_secret_names.admin_connection_string
    }
    secret_uris = {
      namespace_connection_string    = "https://${var.keyvault_name}.vault.azure.net/secrets/${var.keyvault_secret_names.namespace_connection_string}/"
      function_app_connection_string = "https://${var.keyvault_name}.vault.azure.net/secrets/${var.keyvault_secret_names.function_app_connection_string}/"
      read_only_connection_string    = "https://${var.keyvault_name}.vault.azure.net/secrets/${var.keyvault_secret_names.read_only_connection_string}/"
      admin_connection_string        = "https://${var.keyvault_name}.vault.azure.net/secrets/${var.keyvault_secret_names.admin_connection_string}/"
    }
    } : {
    enabled                 = false
    keyvault_name           = null
    keyvault_resource_group = null
    secret_names = {
      namespace_connection_string    = null
      function_app_connection_string = null
      read_only_connection_string    = null
      admin_connection_string        = null
    }
    secret_uris = {
      namespace_connection_string    = null
      function_app_connection_string = null
      read_only_connection_string    = null
      admin_connection_string        = null
    }
  }
}

# Service Bus configuration details
output "service_bus_configuration" {
  description = "Service Bus configuration details"
  value = {
    namespace_name           = azurerm_servicebus_namespace.main.name
    sku                      = var.service_bus_sku
    premium_messaging_units  = var.service_bus_sku == "Premium" ? var.premium_messaging_units : null
    zone_redundancy_enabled  = var.service_bus_sku == "Premium" ? var.enable_zone_redundancy : false
    private_endpoint_enabled = var.enable_private_endpoint
    queue_count              = length(keys(azurerm_servicebus_queue.queues))
    topic_count              = length(keys(azurerm_servicebus_topic.topics))
    partitioning_enabled     = var.enable_partitioning
    duplicate_detection      = var.enable_duplicate_detection
  }
}

# Cost optimization information
output "cost_optimization_info" {
  description = "Information about cost optimization settings"
  value = {
    sku                        = var.service_bus_sku
    premium_messaging_units    = var.service_bus_sku == "Premium" ? var.premium_messaging_units : null
    partitioning_enabled       = var.enable_partitioning
    estimated_monthly_cost_usd = var.service_bus_sku == "Basic" ? "5-10" : var.service_bus_sku == "Standard" ? "10-50" : "200-500"
    cost_optimization_notes    = "Basic SKU for development, Standard for production messaging, Premium for high-throughput scenarios"
  }
}
