# Networking Module - Variables
# This file defines all input variables for the networking module

# Required Variables
variable "resource_group_name" {
  description = "Name of the resource group where networking resources will be created"
  type        = string

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource group name must not be empty."
  }
}

variable "location" {
  description = "Azure region for networking resources"
  type        = string

  validation {
    condition     = length(var.location) > 0
    error_message = "Location must not be empty."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "workload" {
  description = "Workload name for resource naming"
  type        = string

  validation {
    condition     = length(var.workload) > 0
    error_message = "Workload name must not be empty."
  }
}

variable "location_short" {
  description = "Short name for the Azure region"
  type        = string

  validation {
    condition     = length(var.location_short) > 0
    error_message = "Location short name must not be empty."
  }
}

variable "tags" {
  description = "Tags to apply to all networking resources"
  type        = map(string)
  default     = {}
}

# Network Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)

  validation {
    condition     = length(var.vnet_address_space) > 0
    error_message = "At least one address space must be provided."
  }

  validation {
    condition = alltrue([
      for cidr in var.vnet_address_space : can(cidrhost(cidr, 0))
    ])
    error_message = "All address spaces must be valid CIDR notation."
  }
}

variable "subnet_config" {
  description = "Configuration for subnets"
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string), [])
      })
    }), null)
  }))

  validation {
    condition     = length(var.subnet_config) > 0
    error_message = "At least one subnet must be configured."
  }
}

# Optional Features
variable "enable_custom_routes" {
  description = "Enable custom route table and routes"
  type        = bool
  default     = false
}

variable "enable_network_watcher" {
  description = "Enable Network Watcher for monitoring and diagnostics"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VNet flow logs (requires Network Watcher)"
  type        = bool
  default     = false
}

variable "enable_legacy_nsg_flow_logs" {
  description = "Enable legacy NSG flow logs alongside VNet flow logs (deprecated - will be retired Sept 30, 2027)"
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 91

  validation {
    condition     = var.flow_log_retention_days >= 91 && var.flow_log_retention_days <= 365
    error_message = "Flow log retention days must be between 91 and 365 for security compliance."
  }
}

variable "enable_traffic_analytics" {
  description = "Enable traffic analytics for flow logs"
  type        = bool
  default     = false
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for traffic analytics"
  type        = string
  default     = null
}

variable "log_analytics_workspace_resource_id" {
  description = "Log Analytics workspace resource ID for traffic analytics"
  type        = string
  default     = null
}
