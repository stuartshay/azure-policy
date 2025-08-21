# Azure Monitoring Infrastructure - Outputs
# This file defines outputs from the monitoring infrastructure

# Log Analytics Workspace Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = module.monitoring.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics Workspace"
  value       = module.monitoring.log_analytics_workspace_name
}

output "log_analytics_workspace_resource_id" {
  description = "Resource ID of the Log Analytics Workspace"
  value       = module.monitoring.log_analytics_workspace_resource_id
}

output "log_analytics_primary_shared_key" {
  description = "Primary shared key for Log Analytics Workspace"
  value       = module.monitoring.log_analytics_primary_shared_key
  sensitive   = true
}

output "log_analytics_workspace_id_key" {
  description = "Workspace ID for Log Analytics"
  value       = module.monitoring.log_analytics_workspace_id_key
  sensitive   = true
}

# Application Insights Outputs
output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = module.monitoring.application_insights_id
}

output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = module.monitoring.application_insights_name
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = module.monitoring.application_insights_instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = module.monitoring.application_insights_connection_string
  sensitive   = true
}

output "application_insights_app_id" {
  description = "App ID for Application Insights"
  value       = module.monitoring.application_insights_app_id
}

# Action Group Outputs
output "action_group_id" {
  description = "ID of the monitoring action group"
  value       = module.monitoring.action_group_id
}

output "action_group_name" {
  description = "Name of the monitoring action group"
  value       = module.monitoring.action_group_name
}

# Alert Rule Outputs
output "metric_alert_ids" {
  description = "Map of metric alert IDs by function app"
  value       = module.monitoring.metric_alert_ids
}

output "log_alert_ids" {
  description = "List of log query alert IDs"
  value       = module.monitoring.log_alert_ids
}

output "activity_log_alert_ids" {
  description = "List of activity log alert IDs"
  value       = module.monitoring.activity_log_alert_ids
}

output "smart_detection_rule_ids" {
  description = "List of smart detection rule IDs"
  value       = module.monitoring.smart_detection_rule_ids
}

# Monitoring Configuration Summary
output "monitoring_configuration" {
  description = "Summary of monitoring configuration"
  value       = module.monitoring.monitoring_configuration
}

# Resource Names for Reference
output "resource_names" {
  description = "Names of created monitoring resources"
  value       = module.monitoring.resource_names
}

# Integration Outputs for Other Modules
output "monitoring_integration" {
  description = "Key outputs for integration with other infrastructure modules"
  value = {
    # For Function Apps
    application_insights_connection_string   = module.monitoring.application_insights_connection_string
    application_insights_instrumentation_key = module.monitoring.application_insights_instrumentation_key

    # For Diagnostic Settings
    log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

    # For Custom Alerts
    action_group_id = module.monitoring.action_group_id

    # For Resource References
    log_analytics_workspace_name = module.monitoring.log_analytics_workspace_name
    application_insights_name    = module.monitoring.application_insights_name
  }
  sensitive = true
}

# Monitored Function Apps Summary
output "monitored_function_apps" {
  description = "Summary of monitored Function Apps"
  value = {
    basic_function = {
      monitored = var.monitor_existing_functions && var.monitor_basic_function
      name      = var.monitor_existing_functions && var.monitor_basic_function ? "func-${var.workload}-${var.environment}-001" : null
    }
    advanced_function = {
      monitored = var.monitor_existing_functions && var.monitor_advanced_function
      name      = var.monitor_existing_functions && var.monitor_advanced_function ? "func-${var.workload}-advanced-${var.environment}-001" : null
    }
    infrastructure_function = {
      monitored = var.monitor_existing_functions && var.monitor_infrastructure_function
      name      = var.monitor_existing_functions && var.monitor_infrastructure_function ? "func-${var.workload}-infrastructure-${var.environment}-001" : null
    }
  }
}

# Deployment Information
output "deployment_info" {
  description = "Information about the monitoring deployment"
  value = {
    workspace_name = "azure-policy-monitoring"
    environment    = var.environment
    location       = var.location
    workload       = var.workload
    deployed_at    = timestamp()
    features_enabled = {
      log_alerts          = var.enable_log_alerts
      activity_log_alerts = var.enable_activity_log_alerts
      smart_detection     = var.enable_smart_detection
      workbook            = var.enable_workbook
      budget_alerts       = var.enable_budget_alerts
      private_endpoints   = var.enable_private_endpoints
      storage_monitoring  = var.enable_storage_monitoring
    }
    alert_thresholds = {
      cpu_threshold           = var.cpu_threshold
      memory_threshold        = var.memory_threshold
      error_threshold         = var.error_threshold
      response_time_threshold = var.response_time_threshold
      availability_threshold  = var.availability_threshold
    }
  }
}
