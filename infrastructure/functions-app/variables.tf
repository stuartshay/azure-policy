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
  default     = "3.13"

  validation {
    condition     = contains(["3.8", "3.9", "3.10", "3.11", "3.12", "3.13"], var.python_version)
    error_message = "Python version must be 3.8, 3.9, 3.10, 3.11, 3.12, or 3.13."
  }
}

variable "function_app_settings" {
  description = "Additional app settings for the Basic Function App"
  type        = map(string)
  default     = {}
}

variable "advanced_function_app_settings" {
  description = "Additional app settings for the Advanced Function App"
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

# Infrastructure Function Configuration
variable "enable_infrastructure_function" {
  description = "Enable the infrastructure function for secret rotation"
  type        = bool
  default     = true
}

variable "infrastructure_function_app_settings" {
  description = "Additional app settings for the Infrastructure Function App"
  type        = map(string)
  default     = {}
}

# Key Vault Configuration for Infrastructure Function
variable "key_vault_name" {
  description = "Name of the Key Vault for secret storage"
  type        = string
  default     = ""
}

variable "key_vault_resource_group_name" {
  description = "Resource group name containing the Key Vault"
  type        = string
  default     = ""
}

# Service Bus Configuration for Infrastructure Function
variable "service_bus_resource_group_name" {
  description = "Resource group name containing the Service Bus namespace"
  type        = string
  default     = ""
}

variable "service_bus_namespace_name" {
  description = "Name of the Service Bus namespace"
  type        = string
  default     = ""
}

# Secret Rotation Configuration
variable "rotation_enabled" {
  description = "Enable automatic secret rotation"
  type        = string
  default     = "true"

  validation {
    condition     = contains(["true", "false"], var.rotation_enabled)
    error_message = "Rotation enabled must be 'true' or 'false'."
  }
}

variable "rotate_admin_access" {
  description = "Include admin access rule in rotation"
  type        = string
  default     = "false"

  validation {
    condition     = contains(["true", "false"], var.rotate_admin_access)
    error_message = "Rotate admin access must be 'true' or 'false'."
  }
}
