# Azure Function App Deployment - Variables
# This file defines all input variables for Function App deployment

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
}

variable "workload" {
  description = "Name of the workload or application"
  type        = string
  default     = "azpolicy"
}

# Infrastructure Dependencies
variable "resource_group_name" {
  description = "Name of the existing resource group (created by app-service module)"
  type        = string
}

# Tagging Variables
variable "cost_center" {
  description = "Cost center for resource billing"
  type        = string
  default     = "development"
}

variable "owner" {
  description = "Owner of the resources (team name or email)"
  type        = string
  default     = "platform-team"
}

# Function App Configuration
variable "functions_sku_name" {
  description = "SKU name for the Functions App Service Plan (must match app-service module)"
  type        = string
  default     = "EP1"

  validation {
    condition     = contains(["Y1", "EP1", "EP2", "EP3", "B1", "B2", "B3", "S1", "S2", "S3"], var.functions_sku_name)
    error_message = "Functions SKU must be a valid App Service Plan SKU."
  }
}

variable "python_version" {
  description = "Python version for Functions"
  type        = string
  default     = "3.11"

  validation {
    condition     = contains(["3.8", "3.9", "3.10", "3.11"], var.python_version)
    error_message = "Python version must be 3.8, 3.9, 3.10, or 3.11."
  }
}

variable "function_app_settings" {
  description = "Additional app settings for the Function App"
  type        = map(string)
  default     = {}
}

# EP1 Specific Configuration
variable "always_ready_instances" {
  description = "Number of always ready instances for EP1 (must match app-service module)"
  type        = number
  default     = 1

  validation {
    condition     = var.always_ready_instances >= 0 && var.always_ready_instances <= 20
    error_message = "Always ready instances must be between 0 and 20."
  }
}

variable "maximum_elastic_worker_count" {
  description = "Maximum number of elastic workers for EP1 (must match app-service module)"
  type        = number
  default     = 3

  validation {
    condition     = var.maximum_elastic_worker_count >= 1 && var.maximum_elastic_worker_count <= 20
    error_message = "Maximum elastic worker count must be between 1 and 20."
  }
}
