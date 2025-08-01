# Azure Functions - Variables
# This file defines all input variables for Azure Functions infrastructure

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

# Infrastructure Dependencies
variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
}


# Functions Configuration
variable "functions_sku_name" {
  description = "SKU name for the Functions App Service Plan"
  type        = string
  default     = "Y1" # Consumption plan

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

variable "enable_application_insights" {
  description = "Enable Application Insights for Functions"
  type        = bool
  default     = true
}
