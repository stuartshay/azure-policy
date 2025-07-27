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
  description = "Enable NSG flow logs (requires Network Watcher)"
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Number of days to retain flow logs"
  type        = number
  default     = 30

  validation {
    condition     = var.flow_log_retention_days >= 1 && var.flow_log_retention_days <= 365
    error_message = "Flow log retention days must be between 1 and 365."
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

# Security Configuration
variable "allowed_ip_ranges" {
  description = "List of allowed IP ranges for network access"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for ip_range in var.allowed_ip_ranges : can(cidrhost(ip_range, 0))
    ])
    error_message = "All IP ranges must be valid CIDR notation."
  }
}

variable "enable_ddos_protection" {
  description = "Enable DDoS protection for the virtual network"
  type        = bool
  default     = false
}

variable "ddos_protection_plan_id" {
  description = "ID of the DDoS protection plan (if enabled)"
  type        = string
  default     = null
}

# DNS Configuration
variable "dns_servers" {
  description = "List of DNS servers for the virtual network"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for dns in var.dns_servers : can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", dns))
    ])
    error_message = "All DNS servers must be valid IP addresses."
  }
}

# Network Security Rules Configuration
variable "additional_security_rules" {
  description = "Additional security rules to apply to NSGs"
  type = map(list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_port_ranges         = optional(list(string), [])
    destination_port_ranges    = optional(list(string), [])
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = optional(string, "*")
    source_address_prefixes    = optional(list(string), [])
    destination_address_prefixes = optional(list(string), [])
  })))
  default = {}
}

# Peering Configuration (for future use)
variable "enable_peering" {
  description = "Enable VNet peering"
  type        = bool
  default     = false
}

variable "peering_vnets" {
  description = "List of VNets to peer with"
  type = list(object({
    name                = string
    resource_group_name = string
    allow_forwarded_traffic = optional(bool, false)
    allow_gateway_transit   = optional(bool, false)
    use_remote_gateways     = optional(bool, false)
  }))
  default = []
}

# Monitoring Configuration
variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for networking resources"
  type        = bool
  default     = true
}

variable "diagnostic_storage_account_id" {
  description = "Storage account ID for diagnostic logs"
  type        = string
  default     = null
}

variable "diagnostic_log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic logs"
  type        = string
  default     = null
}

variable "diagnostic_eventhub_authorization_rule_id" {
  description = "Event Hub authorization rule ID for diagnostic logs"
  type        = string
  default     = null
}

variable "diagnostic_eventhub_name" {
  description = "Event Hub name for diagnostic logs"
  type        = string
  default     = null
}

# Private Endpoint Configuration
variable "enable_private_dns_zones" {
  description = "Enable private DNS zones for private endpoints"
  type        = bool
  default     = false
}

variable "private_dns_zones" {
  description = "List of private DNS zones to create"
  type        = list(string)
  default     = []
}

# Network Performance Configuration
variable "enable_accelerated_networking" {
  description = "Enable accelerated networking where supported"
  type        = bool
  default     = false
}

# Cost Optimization
variable "enable_flow_log_storage_analytics" {
  description = "Enable storage analytics for flow log storage account"
  type        = bool
  default     = false
}

variable "flow_log_storage_tier" {
  description = "Storage tier for flow log storage account"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.flow_log_storage_tier)
    error_message = "Flow log storage tier must be Standard or Premium."
  }
}

variable "flow_log_storage_replication" {
  description = "Replication type for flow log storage account"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.flow_log_storage_replication)
    error_message = "Flow log storage replication must be a valid Azure storage replication type."
  }
}
