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
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.service_bus[0].private_service_connection[0].private_ip_address : null
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
