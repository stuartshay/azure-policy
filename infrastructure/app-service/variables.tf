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

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"

  validation {
    condition     = contains(["East US", "East US 2"], var.location)
    error_message = "Location must be East US or East US 2."
  }
}


# Functions Configuration
variable "functions_sku_name" {
  description = "SKU name for the Functions App Service Plan"
  type        = string
  default     = "EP1" # Elastic Premium plan

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
  description = "Additional app settings for the Function App"
  type        = map(string)
  default     = {}
}

variable "enable_application_insights" {
  description = "Enable Application Insights for Functions"
  type        = bool
  default     = false
}

# VNet Integration Configuration
variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration (required for EP1 SKU)"
  type        = string
  default     = null
}

variable "enable_vnet_integration" {
  description = "Enable VNet integration for the Function App"
  type        = bool
  default     = false
}

# EP1 Specific Configuration
variable "always_ready_instances" {
  description = "Number of always ready instances for EP1"
  type        = number
  default     = 1

  validation {
    condition     = var.always_ready_instances >= 0 && var.always_ready_instances <= 20
    error_message = "Always ready instances must be between 0 and 20."
  }
}

variable "maximum_elastic_worker_count" {
  description = "Maximum number of elastic workers for EP1"
  type        = number
  default     = 3

  validation {
    condition     = var.maximum_elastic_worker_count >= 1 && var.maximum_elastic_worker_count <= 20
    error_message = "Maximum elastic worker count must be between 1 and 20."
  }
}

# Deployment Control
variable "deploy_function_app" {
  description = "Whether to deploy the Function App resource (set to false for infrastructure-only deployment)"
  type        = bool
  default     = false
}
