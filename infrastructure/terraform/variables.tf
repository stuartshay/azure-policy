# Azure Policy Infrastructure - Variables
# This file defines all input variables for the infrastructure

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

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "At least one address space must be provided."
  }
}

variable "subnet_config" {
  description = "Configuration for subnets"
  type = map(object({
    address_prefixes = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string), [])
      })
    }), null)
  }))

  default = {
    default = {
      address_prefixes = ["10.0.1.0/24"]
      service_endpoints = []
    }
    appservice = {
      address_prefixes = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      delegation = {
        name = "app-service-delegation"
        service_delegation = {
          name = "Microsoft.Web/serverFarms"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/action"
          ]
        }
      }
    }
    functions = {
      address_prefixes = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    privateendpoints = {
      address_prefixes = ["10.0.4.0/24"]
      service_endpoints = []
    }
  }
}

# App Service Configuration
variable "app_service_plan_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "B1"

  validation {
    condition = contains([
      "B1", "B2", "B3",           # Basic tier
      "S1", "S2", "S3",           # Standard tier
      "P1", "P2", "P3",           # Premium tier
      "P1v2", "P2v2", "P3v2",    # Premium v2 tier
      "P1v3", "P2v3", "P3v3"     # Premium v3 tier
    ], var.app_service_plan_sku)
    error_message = "App Service Plan SKU must be a valid Azure App Service Plan SKU."
  }
}

variable "enable_application_insights" {
  description = "Enable Application Insights for monitoring"
  type        = bool
  default     = true
}

# Azure Policy Configuration
variable "allowed_locations" {
  description = "List of allowed Azure regions for resource deployment"
  type        = list(string)
  default     = ["East US", "East US 2"]

  validation {
    condition     = length(var.allowed_locations) > 0
    error_message = "At least one allowed location must be specified."
  }
}

# Function App Configuration
variable "function_apps" {
  description = "Configuration for Azure Function Apps"
  type = map(object({
    name_suffix = string
    runtime_stack = optional(string, "python")
    runtime_version = optional(string, "3.11")
    always_on = optional(bool, false)
    app_settings = optional(map(string), {})
  }))

  default = {
    processor = {
      name_suffix = "processor"
      runtime_stack = "python"
      runtime_version = "3.11"
      always_on = false
      app_settings = {
        "FUNCTIONS_WORKER_RUNTIME" = "python"
        "PYTHON_ISOLATE_WORKER_DEPENDENCIES" = "1"
      }
    }
    validator = {
      name_suffix = "validator"
      runtime_stack = "python"
      runtime_version = "3.11"
      always_on = false
      app_settings = {
        "FUNCTIONS_WORKER_RUNTIME" = "python"
        "PYTHON_ISOLATE_WORKER_DEPENDENCIES" = "1"
      }
    }
  }
}

# Security Configuration
variable "enable_private_endpoints" {
  description = "Enable private endpoints for storage and other services"
  type        = bool
  default     = false  # Disabled for development to reduce costs
}

variable "enable_key_vault" {
  description = "Enable Azure Key Vault for secrets management"
  type        = bool
  default     = true
}

# Cost Management
variable "budget_amount" {
  description = "Monthly budget amount in USD for cost alerts"
  type        = number
  default     = 100

  validation {
    condition     = var.budget_amount > 0
    error_message = "Budget amount must be greater than 0."
  }
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds as percentages"
  type        = list(number)
  default     = [50, 80, 100]

  validation {
    condition = alltrue([
      for threshold in var.budget_alert_thresholds : threshold > 0 && threshold <= 100
    ])
    error_message = "Budget alert thresholds must be between 1 and 100."
  }
}

# Development Configuration
variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for development resources"
  type        = bool
  default     = true
}

variable "auto_shutdown_time" {
  description = "Time to auto-shutdown resources (24-hour format, e.g., '1900' for 7 PM)"
  type        = string
  default     = "1900"

  validation {
    condition     = can(regex("^([01]?[0-9]|2[0-3])[0-5][0-9]$", var.auto_shutdown_time))
    error_message = "Auto shutdown time must be in 24-hour format (HHMM)."
  }
}

variable "auto_shutdown_timezone" {
  description = "Timezone for auto-shutdown (e.g., 'Eastern Standard Time')"
  type        = string
  default     = "Eastern Standard Time"
}

# Monitoring Configuration
variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30

  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention days must be between 30 and 730."
  }
}

variable "enable_diagnostic_logs" {
  description = "Enable diagnostic logs for resources"
  type        = bool
  default     = true
}

# Backup Configuration
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 1 and 35."
  }
}

# Network Security
variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for network access"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Open for development, restrict for production

  validation {
    condition = alltrue([
      for ip_range in var.allowed_ip_ranges : can(cidrhost(ip_range, 0))
    ])
    error_message = "All IP ranges must be valid CIDR notation."
  }
}

# Feature Flags
variable "enable_advanced_threat_protection" {
  description = "Enable Advanced Threat Protection for storage accounts"
  type        = bool
  default     = false  # Disabled for development to reduce costs
}

variable "enable_backup" {
  description = "Enable backup for applicable resources"
  type        = bool
  default     = false  # Disabled for development
}

variable "enable_geo_redundancy" {
  description = "Enable geo-redundant storage and services"
  type        = bool
  default     = false  # Disabled for development
}
