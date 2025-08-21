# Monitoring Module - Outputs
# This file defines outputs from the monitoring module

# Log Analytics Workspace Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_resource_id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_primary_shared_key" {
  description = "Primary shared key for Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "log_analytics_secondary_shared_key" {
  description = "Secondary shared key for Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_id_key" {
  description = "Workspace ID for Log Analytics"
  value       = azurerm_log_analytics_workspace.main.workspace_id
  sensitive   = true
}

# Application Insights Outputs
output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = azurerm_application_insights.main.id
}

output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "application_insights_app_id" {
  description = "App ID for Application Insights"
  value       = azurerm_application_insights.main.app_id
}

# Action Group Outputs
output "action_group_id" {
  description = "ID of the monitoring action group"
  value       = azurerm_monitor_action_group.main.id
}

output "action_group_name" {
  description = "Name of the monitoring action group"
  value       = azurerm_monitor_action_group.main.name
}

output "action_group_short_name" {
  description = "Short name of the monitoring action group"
  value       = azurerm_monitor_action_group.main.short_name
}

# Storage Account Outputs (if enabled)
output "monitoring_storage_account_id" {
  description = "ID of the monitoring storage account"
  value       = var.enable_storage_monitoring ? azurerm_storage_account.monitoring[0].id : null
}

output "monitoring_storage_account_name" {
  description = "Name of the monitoring storage account"
  value       = var.enable_storage_monitoring ? azurerm_storage_account.monitoring[0].name : null
}

output "monitoring_storage_primary_connection_string" {
  description = "Primary connection string for monitoring storage account"
  value       = var.enable_storage_monitoring ? azurerm_storage_account.monitoring[0].primary_connection_string : null
  sensitive   = true
}

# Data Collection Rule Outputs (if enabled)
output "vm_insights_data_collection_rule_id" {
  description = "ID of the VM Insights data collection rule"
  value       = var.enable_vm_insights ? azurerm_monitor_data_collection_rule.vm_insights[0].id : null
}

# Private Endpoint Outputs (if enabled)
output "log_analytics_private_endpoint_id" {
  description = "ID of the Log Analytics private endpoint"
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.log_analytics[0].id : null
}

output "log_analytics_private_endpoint_ip" {
  description = "Private IP address of the Log Analytics private endpoint"
  value       = var.enable_private_endpoints ? azurerm_private_endpoint.log_analytics[0].private_service_connection[0].private_ip_address : null
}

# Workbook Outputs (if enabled)
output "monitoring_workbook_id" {
  description = "ID of the monitoring workbook"
  value       = var.enable_workbook ? azurerm_application_insights_workbook.main[0].id : null
}

# Alert Rule Outputs
output "metric_alert_ids" {
  description = "Map of metric alert IDs by function app"
  value = {
    cpu_alerts           = { for k, v in azurerm_monitor_metric_alert.function_app_cpu : k => v.id }
    memory_alerts        = { for k, v in azurerm_monitor_metric_alert.function_app_memory : k => v.id }
    error_alerts         = { for k, v in azurerm_monitor_metric_alert.function_app_errors : k => v.id }
    response_time_alerts = { for k, v in azurerm_monitor_metric_alert.function_app_response_time : k => v.id }
  }
}

output "log_alert_ids" {
  description = "List of log query alert IDs"
  value = var.enable_log_alerts ? [
    azurerm_monitor_scheduled_query_rules_alert_v2.function_exceptions[0].id,
    azurerm_monitor_scheduled_query_rules_alert_v2.function_availability[0].id,
    azurerm_monitor_scheduled_query_rules_alert_v2.function_performance[0].id
  ] : []
}

output "activity_log_alert_ids" {
  description = "List of activity log alert IDs"
  value = var.enable_activity_log_alerts ? [
    azurerm_monitor_activity_log_alert.resource_health[0].id,
    azurerm_monitor_activity_log_alert.service_health[0].id
  ] : []
}

# Smart Detection Rule Outputs
output "smart_detection_rule_ids" {
  description = "List of smart detection rule IDs"
  value = [
    azurerm_application_insights_smart_detection_rule.failure_anomalies.id,
    azurerm_application_insights_smart_detection_rule.performance_anomalies.id,
    azurerm_application_insights_smart_detection_rule.trace_severity.id
  ]
}

# Budget Alert Outputs (if enabled)
output "budget_alert_id" {
  description = "ID of the budget alert"
  value       = var.enable_budget_alerts ? azurerm_consumption_budget_resource_group.monitoring[0].id : null
}

# Diagnostic Settings Outputs
output "log_analytics_diagnostic_setting_id" {
  description = "ID of the Log Analytics diagnostic setting"
  value       = var.enable_workspace_diagnostics ? azurerm_monitor_diagnostic_setting.log_analytics[0].id : null
}

# Solution Outputs
output "security_center_solution_id" {
  description = "ID of the Security Center solution"
  value       = var.enable_security_center ? azurerm_log_analytics_solution.security_center[0].id : null
}

output "update_management_solution_id" {
  description = "ID of the Update Management solution"
  value       = var.enable_update_management ? azurerm_log_analytics_solution.updates[0].id : null
}

# Monitoring Configuration Summary
output "monitoring_configuration" {
  description = "Summary of monitoring configuration"
  value = {
    log_analytics_workspace = {
      name           = azurerm_log_analytics_workspace.main.name
      sku            = azurerm_log_analytics_workspace.main.sku
      retention_days = azurerm_log_analytics_workspace.main.retention_in_days
      daily_quota_gb = azurerm_log_analytics_workspace.main.daily_quota_gb
    }
    application_insights = {
      name                = azurerm_application_insights.main.name
      application_type    = azurerm_application_insights.main.application_type
      sampling_percentage = azurerm_application_insights.main.sampling_percentage
      workspace_based     = true
    }
    action_group = {
      name       = azurerm_monitor_action_group.main.name
      short_name = azurerm_monitor_action_group.main.short_name
    }
    features_enabled = {
      storage_monitoring    = var.enable_storage_monitoring
      vm_insights           = var.enable_vm_insights
      workspace_diagnostics = var.enable_workspace_diagnostics
      private_endpoints     = var.enable_private_endpoints
      security_center       = var.enable_security_center
      update_management     = var.enable_update_management
      workbook              = var.enable_workbook
      log_alerts            = var.enable_log_alerts
      activity_log_alerts   = var.enable_activity_log_alerts
      budget_alerts         = var.enable_budget_alerts
      smart_detection       = var.enable_smart_detection
      availability_tests    = var.enable_availability_tests
    }
    alert_thresholds = {
      cpu_threshold           = var.cpu_threshold
      memory_threshold        = var.memory_threshold
      error_threshold         = var.error_threshold
      response_time_threshold = var.response_time_threshold
      exception_threshold     = var.exception_threshold
      availability_threshold  = var.availability_threshold
      performance_threshold   = var.performance_threshold
    }
  }
}

# Resource Names for Reference
output "resource_names" {
  description = "Names of created monitoring resources"
  value = {
    log_analytics_workspace = azurerm_log_analytics_workspace.main.name
    application_insights    = azurerm_application_insights.main.name
    action_group            = azurerm_monitor_action_group.main.name
    storage_account         = var.enable_storage_monitoring ? azurerm_storage_account.monitoring[0].name : null
    workbook                = var.enable_workbook ? azurerm_application_insights_workbook.main[0].name : null
  }
}
