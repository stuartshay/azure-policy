# Azure Infrastructure - Variables
# This file defines all input variables for the core infrastructure

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

  default = {
    default = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = []
    }
    appservice = {
      address_prefixes  = ["10.0.2.0/24"]
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
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    }
    privateendpoints = {
      address_prefixes  = ["10.0.4.0/24"]
      service_endpoints = []
    }
  }
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

# Feature Toggles
variable "enable_network_watcher" {
  description = "Enable Network Watcher for network monitoring"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable Network Security Group flow logs"
  type        = bool
  default     = true
}
