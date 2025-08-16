# Azure Service Bus - Variables
# This file defines all input variables for Azure Service Bus infrastructure

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

# Service Bus Configuration
variable "service_bus_sku" {
  description = "SKU for the Service Bus namespace"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.service_bus_sku)
    error_message = "Service Bus SKU must be Basic, Standard, or Premium."
  }
}

variable "premium_messaging_units" {
  description = "Number of premium messaging units (1-8, Premium SKU only)"
  type        = number
  default     = 1

  validation {
    condition     = var.premium_messaging_units >= 1 && var.premium_messaging_units <= 8
    error_message = "Premium messaging units must be between 1 and 8."
  }
}

variable "enable_zone_redundancy" {
  description = "Enable zone redundancy (Premium SKU only)"
  type        = bool
  default     = false
}

# Queue Configuration
variable "custom_queues" {
  description = "List of custom queue names to create in addition to default queues"
  type        = list(string)
  default     = []
}

variable "custom_topics" {
  description = "List of custom topic names to create in addition to default topics"
  type        = list(string)
  default     = []
}

variable "max_queue_size_mb" {
  description = "Maximum size of queues in megabytes"
  type        = number
  default     = 1024

  validation {
    condition = contains([
      1024, 2048, 3072, 4096, 5120
    ], var.max_queue_size_mb)
    error_message = "Queue size must be 1024, 2048, 3072, 4096, or 5120 MB."
  }
}

variable "max_topic_size_mb" {
  description = "Maximum size of topics in megabytes"
  type        = number
  default     = 1024

  validation {
    condition = contains([
      1024, 2048, 3072, 4096, 5120
    ], var.max_topic_size_mb)
    error_message = "Topic size must be 1024, 2048, 3072, 4096, or 5120 MB."
  }
}

variable "enable_partitioning" {
  description = "Enable partitioning for queues and topics"
  type        = bool
  default     = false
}

variable "default_message_ttl" {
  description = "Default message time-to-live in ISO 8601 format"
  type        = string
  default     = "P14D" # 14 days
}

variable "duplicate_detection_window" {
  description = "Duplicate detection history time window in ISO 8601 format"
  type        = string
  default     = "PT10M" # 10 minutes
}

variable "enable_duplicate_detection" {
  description = "Enable duplicate detection for queues and topics"
  type        = bool
  default     = true
}

variable "max_delivery_count" {
  description = "Maximum number of delivery attempts before dead lettering"
  type        = number
  default     = 10

  validation {
    condition     = var.max_delivery_count >= 1 && var.max_delivery_count <= 2000
    error_message = "Max delivery count must be between 1 and 2000."
  }
}

variable "auto_delete_on_idle" {
  description = "Auto delete queues/topics when idle for specified duration (ISO 8601)"
  type        = string
  default     = "P10675199DT2H48M5.4775807S" # Never auto-delete (max value)
}

# Security Configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint for Service Bus"
  type        = bool
  default     = false
}

variable "create_admin_access_rule" {
  description = "Create an admin access authorization rule"
  type        = bool
  default     = false
}

# Key Vault Integration
variable "enable_keyvault_integration" {
  description = "Enable storing Service Bus connection strings in Key Vault"
  type        = bool
  default     = false
}

variable "keyvault_name" {
  description = "Name of the existing Key Vault"
  type        = string
  default     = ""
}

variable "keyvault_resource_group_name" {
  description = "Resource group name where the Key Vault exists"
  type        = string
  default     = ""
}

variable "keyvault_secret_names" {
  description = "Names for the secrets to be stored in Key Vault"
  type = object({
    namespace_connection_string    = optional(string, "servicebus-namespace-connection-string")
    function_app_connection_string = optional(string, "servicebus-function-app-connection-string")
    read_only_connection_string    = optional(string, "servicebus-read-only-connection-string")
    admin_connection_string        = optional(string, "servicebus-admin-connection-string")
  })
  default = {
    namespace_connection_string    = "servicebus-namespace-connection-string"
    function_app_connection_string = "servicebus-function-app-connection-string"
    read_only_connection_string    = "servicebus-read-only-connection-string"
    admin_connection_string        = "servicebus-admin-connection-string"
  }
}

variable "keyvault_secret_expiration_days" {
  description = "Number of days until Key Vault secrets expire (30-365 days recommended)"
  type        = number
  default     = 90

  validation {
    condition     = var.keyvault_secret_expiration_days >= 30 && var.keyvault_secret_expiration_days <= 365
# Constants for Key Vault secret expiration bounds
locals {
  keyvault_secret_expiration_days_min = 30
  keyvault_secret_expiration_days_max = 365
}

variable "keyvault_secret_expiration_days" {
  description = "Number of days until Key Vault secrets expire (${local.keyvault_secret_expiration_days_min}-${local.keyvault_secret_expiration_days_max} days recommended)"
  type        = number
  default     = 90

  validation {
    condition     = var.keyvault_secret_expiration_days >= local.keyvault_secret_expiration_days_min && var.keyvault_secret_expiration_days <= local.keyvault_secret_expiration_days_max
    error_message = "Secret expiration days must be between ${local.keyvault_secret_expiration_days_min} and ${local.keyvault_secret_expiration_days_max} days."
  }
}
