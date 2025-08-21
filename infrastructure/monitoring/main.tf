# Azure Monitoring Infrastructure
# This file defines the monitoring infrastructure using the monitoring module

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40"
    }
  }

  # Terraform Cloud backend for state management
  cloud {
    organization = "azure-policy-cloud"

    workspaces {
      name = "azure-policy-monitoring"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }

    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    application_insights {
      disable_generated_rule = false
    }
  }
}

# Data source to get existing core infrastructure
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Data source to get VNet information for private endpoints (if enabled)
data "azurerm_virtual_network" "main" {
  count               = var.enable_private_endpoints ? 1 : 0
  name                = "vnet-${var.workload}-${var.environment}-${local.location_short}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Data source to get private endpoint subnet
data "azurerm_subnet" "private_endpoints" {
  count                = var.enable_private_endpoints ? 1 : 0
  name                 = "snet-privateendpoints-${var.workload}-${var.environment}-${local.location_short}-001"
  virtual_network_name = data.azurerm_virtual_network.main[0].name
  resource_group_name  = data.azurerm_resource_group.main.name
}

# Data sources for existing Function Apps to monitor
data "azurerm_linux_function_app" "basic" {
  count               = var.monitor_existing_functions ? 1 : 0
  name                = "func-${var.workload}-${var.environment}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_linux_function_app" "advanced" {
  count               = var.monitor_existing_functions ? 1 : 0
  name                = "func-${var.workload}-advanced-${var.environment}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_linux_function_app" "infrastructure" {
  count               = var.monitor_existing_functions && var.monitor_infrastructure_function ? 1 : 0
  name                = "func-${var.workload}-infrastructure-${var.environment}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Local values for consistent naming and configuration
locals {
  # Location mapping for consistent naming
  location_short_map = {
    "East US"   = "eastus"
    "East US 2" = "eastus2"
  }

  location_short = local.location_short_map[var.location]

  # Common tags applied to all resources
  common_tags = {
    Environment = var.environment
    CostCenter  = var.cost_center
    Project     = "azurepolicy"
    Owner       = var.owner
    CreatedBy   = "terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    Component   = "monitoring"
  }

  # Function Apps to monitor (if they exist)
  monitored_function_apps = var.monitor_existing_functions ? merge(
    var.monitor_basic_function && length(data.azurerm_linux_function_app.basic) > 0 ? {
      basic = {
        resource_id = data.azurerm_linux_function_app.basic[0].id
        name        = data.azurerm_linux_function_app.basic[0].name
      }
    } : {},
    var.monitor_advanced_function && length(data.azurerm_linux_function_app.advanced) > 0 ? {
      advanced = {
        resource_id = data.azurerm_linux_function_app.advanced[0].id
        name        = data.azurerm_linux_function_app.advanced[0].name
      }
    } : {},
    var.monitor_infrastructure_function && length(data.azurerm_linux_function_app.infrastructure) > 0 ? {
      infrastructure = {
        resource_id = data.azurerm_linux_function_app.infrastructure[0].id
        name        = data.azurerm_linux_function_app.infrastructure[0].name
      }
    } : {}
  ) : {}
}

# Monitoring Module
module "monitoring" {
  # Local source path
  source = "../terraform/modules/monitoring"

  # Required variables
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  workload            = var.workload
  environment         = var.environment
  location_short      = local.location_short
  subscription_id     = var.subscription_id

  # Log Analytics configuration
  log_analytics_sku       = var.log_analytics_sku
  log_retention_days      = var.log_retention_days
  daily_quota_gb          = var.daily_quota_gb
  reservation_capacity_gb = var.reservation_capacity_gb

  # Application Insights configuration
  sampling_percentage = var.sampling_percentage

  # Notification configuration
  notification_emails   = var.notification_emails
  notification_sms      = var.notification_sms
  notification_webhooks = var.notification_webhooks

  # Alert thresholds
  cpu_threshold           = var.cpu_threshold
  memory_threshold        = var.memory_threshold
  error_threshold         = var.error_threshold
  response_time_threshold = var.response_time_threshold
  exception_threshold     = var.exception_threshold
  availability_threshold  = var.availability_threshold
  performance_threshold   = var.performance_threshold

  # Monitored resources
  monitored_function_apps = local.monitored_function_apps

  # Feature toggles
  enable_storage_monitoring    = var.enable_storage_monitoring
  enable_vm_insights           = var.enable_vm_insights
  enable_workspace_diagnostics = var.enable_workspace_diagnostics
  enable_private_endpoints     = var.enable_private_endpoints
  enable_security_center       = var.enable_security_center
  enable_update_management     = var.enable_update_management
  enable_workbook              = var.enable_workbook
  enable_log_alerts            = var.enable_log_alerts
  enable_activity_log_alerts   = var.enable_activity_log_alerts
  enable_budget_alerts         = var.enable_budget_alerts
  enable_smart_detection       = var.enable_smart_detection
  enable_availability_tests    = var.enable_availability_tests

  # Private endpoint configuration
  private_endpoint_subnet_id = var.enable_private_endpoints && length(data.azurerm_subnet.private_endpoints) > 0 ? data.azurerm_subnet.private_endpoints[0].id : null
  private_dns_zone_ids       = var.private_dns_zone_ids

  # Budget configuration
  budget_amount              = var.budget_amount
  budget_notification_emails = var.budget_notification_emails

  # Smart detection configuration
  smart_detection_emails = var.smart_detection_emails

  tags = local.common_tags
}

# Diagnostic Settings for existing resources (if enabled)
resource "azurerm_monitor_diagnostic_setting" "function_app_basic" {
  count = var.monitor_existing_functions && var.monitor_basic_function && length(data.azurerm_linux_function_app.basic) > 0 ? 1 : 0

  name                       = "diag-${data.azurerm_linux_function_app.basic[0].name}"
  target_resource_id         = data.azurerm_linux_function_app.basic[0].id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "function_app_advanced" {
  count = var.monitor_existing_functions && var.monitor_advanced_function && length(data.azurerm_linux_function_app.advanced) > 0 ? 1 : 0

  name                       = "diag-${data.azurerm_linux_function_app.advanced[0].name}"
  target_resource_id         = data.azurerm_linux_function_app.advanced[0].id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "function_app_infrastructure" {
  count = var.monitor_existing_functions && var.monitor_infrastructure_function && length(data.azurerm_linux_function_app.infrastructure) > 0 ? 1 : 0

  name                       = "diag-${data.azurerm_linux_function_app.infrastructure[0].name}"
  target_resource_id         = data.azurerm_linux_function_app.infrastructure[0].id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
