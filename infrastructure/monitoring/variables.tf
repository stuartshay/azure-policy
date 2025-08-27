# Azure Monitoring Infrastructure - Variables
# This file defines all input variables for the monitoring infrastructure

# Azure Configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"

  validation {
    condition     = contains(["East US", "East US 2"], var.location)
    error_message = "Location must be East US or East US 2."
  }
}

variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
}

# Project Configuration
variable "workload" {
  description = "Name of the workload or application"
  type        = string
  default     = "azpolicy"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.workload))
    error_message = "Workload name must contain only lowercase letters, numbers, and hyphens."
  }
}

# Tagging Variables
variable "cost_center" {
  description = "Cost center for resource billing"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "operations", "production", "shared"], var.cost_center)
    error_message = "Cost center must be development, operations, production, or shared."
  }
}

variable "owner" {
  description = "Owner of the resources (team name or email)"
  type        = string
  default     = "platform-team"

  validation {
    condition     = length(var.owner) > 0
    error_message = "Owner must not be empty."
  }
}

# Log Analytics Configuration
variable "log_analytics_sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"

  validation {
    condition     = contains(["Free", "PerNode", "PerGB2018", "Standalone", "Standard", "Premium"], var.log_analytics_sku)
    error_message = "Log Analytics SKU must be one of: Free, PerNode, PerGB2018, Standalone, Standard, Premium."
  }
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Log Analytics"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention must be between 30 and 730 days."
  }
}

variable "daily_quota_gb" {
  description = "Daily ingestion quota in GB for Log Analytics (-1 for unlimited)"
  type        = number
  default     = -1

  validation {
    condition     = var.daily_quota_gb == -1 || var.daily_quota_gb >= 0.023
    error_message = "Daily quota must be -1 (unlimited) or at least 0.023 GB."
  }
}

variable "reservation_capacity_gb" {
  description = "Reservation capacity in GB per day for cost optimization"
  type        = number
  default     = null

  validation {
    condition     = var.reservation_capacity_gb == null || (var.reservation_capacity_gb >= 100 && var.reservation_capacity_gb <= 5000)
    error_message = "Reservation capacity must be between 100 and 5000 GB or null."
  }
}

# Application Insights Configuration
variable "sampling_percentage" {
  description = "Sampling percentage for Application Insights"
  type        = number
  default     = 100

  validation {
    condition     = var.sampling_percentage > 0 && var.sampling_percentage <= 100
    error_message = "Sampling percentage must be between 1 and 100."
  }
}

# Notification Configuration
variable "notification_emails" {
  description = "Map of email addresses for notifications"
  type        = map(string)
  default = {
    admin = "admin@example.com"
  }

  validation {
    condition = alltrue([
      for email in values(var.notification_emails) : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All notification emails must be valid email addresses."
  }
}

variable "notification_sms" {
  description = "Map of SMS numbers for notifications"
  type = map(object({
    country_code = string
    phone_number = string
  }))
  default = {}
}

variable "notification_webhooks" {
  description = "Map of webhook URLs for notifications"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for webhook in values(var.notification_webhooks) : can(regex("^https://", webhook))
    ])
    error_message = "All webhook URLs must use HTTPS."
  }
}

# Alert Thresholds
variable "cpu_threshold" {
  description = "CPU usage threshold for alerts (percentage)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_threshold > 0 && var.cpu_threshold <= 100
    error_message = "CPU threshold must be between 1 and 100."
  }
}

variable "memory_threshold" {
  description = "Memory usage threshold for alerts (percentage)"
  type        = number
  default     = 85

  validation {
    condition     = var.memory_threshold > 0 && var.memory_threshold <= 100
    error_message = "Memory threshold must be between 1 and 100."
  }
}

variable "error_threshold" {
  description = "Number of HTTP errors to trigger alert"
  type        = number
  default     = 10

  validation {
    condition     = var.error_threshold > 0
    error_message = "Error threshold must be greater than 0."
  }
}

variable "response_time_threshold" {
  description = "Response time threshold in seconds"
  type        = number
  default     = 5

  validation {
    condition     = var.response_time_threshold > 0
    error_message = "Response time threshold must be greater than 0."
  }
}

variable "exception_threshold" {
  description = "Number of exceptions to trigger alert"
  type        = number
  default     = 5

  validation {
    condition     = var.exception_threshold > 0
    error_message = "Exception threshold must be greater than 0."
  }
}

variable "availability_threshold" {
  description = "Availability percentage threshold"
  type        = number
  default     = 95

  validation {
    condition     = var.availability_threshold > 0 && var.availability_threshold <= 100
    error_message = "Availability threshold must be between 1 and 100."
  }
}

variable "performance_threshold" {
  description = "Performance threshold in milliseconds"
  type        = number
  default     = 5000

  validation {
    condition     = var.performance_threshold > 0
    error_message = "Performance threshold must be greater than 0."
  }
}

# Function App Monitoring Configuration
variable "monitor_existing_functions" {
  description = "Enable monitoring of existing Function Apps"
  type        = bool
  default     = true
}

variable "monitor_basic_function" {
  description = "Monitor the basic Function App"
  type        = bool
  default     = true
}

variable "monitor_advanced_function" {
  description = "Monitor the advanced Function App"
  type        = bool
  default     = true
}

variable "monitor_infrastructure_function" {
  description = "Monitor the infrastructure Function App"
  type        = bool
  default     = false
}

# Feature Toggles
variable "enable_storage_monitoring" {
  description = "Enable storage account for monitoring data"
  type        = bool
  default     = false
}

variable "enable_vm_insights" {
  description = "Enable VM Insights data collection"
  type        = bool
  default     = false
}

variable "enable_workspace_diagnostics" {
  description = "Enable diagnostic settings for Log Analytics workspace"
  type        = bool
  default     = true
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for monitoring resources"
  type        = bool
  default     = false
}

variable "enable_security_center" {
  description = "Enable Security Center solution"
  type        = bool
  default     = true
}

variable "enable_update_management" {
  description = "Enable Update Management solution"
  type        = bool
  default     = false
}

variable "enable_workbook" {
  description = "Enable monitoring workbook"
  type        = bool
  default     = true
}

variable "enable_log_alerts" {
  description = "Enable log query alerts"
  type        = bool
  default     = true
}

variable "enable_activity_log_alerts" {
  description = "Enable activity log alerts"
  type        = bool
  default     = true
}

variable "enable_budget_alerts" {
  description = "Enable budget alerts"
  type        = bool
  default     = false
}

variable "enable_smart_detection" {
  description = "Enable Application Insights smart detection"
  type        = bool
  default     = true
}

variable "enable_availability_tests" {
  description = "Enable availability test alerts"
  type        = bool
  default     = false
}

# Private Endpoint Configuration
variable "private_dns_zone_ids" {
  description = "List of private DNS zone IDs"
  type        = list(string)
  default     = []
}

# Budget Configuration
variable "budget_amount" {
  description = "Budget amount for monitoring resources"
  type        = number
  default     = 100

  validation {
    condition     = var.budget_amount > 0
    error_message = "Budget amount must be greater than 0."
  }
}

variable "budget_notification_emails" {
  description = "List of email addresses for budget notifications"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.budget_notification_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All budget notification emails must be valid email addresses."
  }
}

variable "budget_start_date" {
  description = "The start date for the budget period (format: YYYY-MM-DD or RFC3339). Required for budget alert time_period."
  type        = string
  default     = "2025-01-01"
}

# Smart Detection Configuration
variable "smart_detection_emails" {
  description = "List of email addresses for smart detection notifications"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for email in var.smart_detection_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All smart detection emails must be valid email addresses."
  }
}
