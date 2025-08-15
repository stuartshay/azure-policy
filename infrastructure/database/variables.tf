# Azure Database for PostgreSQL - Variables
# This file defines all input variables for PostgreSQL infrastructure

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

variable "workload" {
  description = "Name of the workload or application"
  type        = string
  default     = "azpolicy"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.workload))
    error_message = "Workload name must contain only lowercase letters, numbers, and hyphens."
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

# Infrastructure Dependencies
variable "resource_group_name" {
  description = "Name of the existing resource group"
  type        = string
}

# PostgreSQL Server Configuration
variable "admin_username" {
  description = "Administrator username for PostgreSQL server"
  type        = string
  default     = "psqladmin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{2,62}$", var.admin_username))
    error_message = "Admin username must start with a letter, be 3-63 characters long, and contain only letters, numbers, and underscores."
  }
}

variable "admin_password" {
  description = "Administrator password for PostgreSQL server (if not provided, a random password will be generated)"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition = var.admin_password == null || (
      length(var.admin_password) >= 8 &&
      length(var.admin_password) <= 128 &&
      can(regex("[A-Z]", var.admin_password)) &&
      can(regex("[a-z]", var.admin_password)) &&
      can(regex("[0-9]", var.admin_password)) &&
      can(regex("[^A-Za-z0-9]", var.admin_password))
    )
    error_message = "Password must be 8-128 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character."
  }
}

variable "sku_name" {
  description = "SKU name for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"

  validation {
    condition = contains([
      "B_Standard_B1ms",    # Burstable - 1 vCore, 2 GB RAM (lowest cost)
      "B_Standard_B2s",     # Burstable - 2 vCore, 4 GB RAM
      "GP_Standard_D2s_v3", # General Purpose - 2 vCore, 8 GB RAM
      "GP_Standard_D4s_v3", # General Purpose - 4 vCore, 16 GB RAM
      "MO_Standard_E2s_v3"  # Memory Optimized - 2 vCore, 16 GB RAM
    ], var.sku_name)
    error_message = "SKU must be a valid PostgreSQL Flexible Server SKU."
  }
}

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"

  validation {
    condition     = contains(["11", "12", "13", "14", "15"], var.postgres_version)
    error_message = "PostgreSQL version must be 11, 12, 13, 14, or 15."
  }
}

variable "storage_mb" {
  description = "Storage size in MB for PostgreSQL server"
  type        = number
  default     = 32768 # 32 GB (minimum for Flexible Server)

  validation {
    condition     = var.storage_mb >= 32768 && var.storage_mb <= 16777216
    error_message = "Storage size must be between 32 GB (32768 MB) and 16 TB (16777216 MB)."
  }
}

variable "backup_retention_days" {
  description = "Backup retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup (increases cost)"
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "Availability zone for the PostgreSQL server (1, 2, 3, or null for no preference)"
  type        = string
  default     = null

  validation {
    condition     = var.availability_zone == null || contains(["1", "2", "3"], var.availability_zone)
    error_message = "Availability zone must be 1, 2, 3, or null."
  }
}

# Database Configuration
variable "database_name" {
  description = "Name of the default database to create"
  type        = string
  default     = "azurepolicy"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.database_name))
    error_message = "Database name must start with a letter, be 1-63 characters long, and contain only letters, numbers, and underscores."
  }
}

variable "additional_databases" {
  description = "List of additional database names to create"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for db in var.additional_databases :
      can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", db))
    ])
    error_message = "All database names must start with a letter, be 1-63 characters long, and contain only letters, numbers, and underscores."
  }
}

# Network Configuration
variable "dev_access_ip" {
  description = "IP address for development access to the database"
  type        = string
  default     = null
  sensitive   = true

  validation {
    condition     = var.dev_access_ip == null || can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.dev_access_ip))
    error_message = "Development access IP must be a valid IPv4 address."
  }
}

variable "allowed_cidrs" {
  description = "List of CIDR blocks allowed to access the database (in addition to VNet subnets)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidrs :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All entries must be valid CIDR blocks."
  }
}

# Performance and Monitoring
variable "enable_query_store" {
  description = "Enable Query Store for performance monitoring"
  type        = bool
  default     = true
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for monitoring"
  type        = bool
  default     = true
}

# Maintenance Configuration
variable "maintenance_window" {
  description = "Maintenance window configuration"
  type = object({
    day_of_week  = optional(number, 0) # 0 = Sunday, 1 = Monday, etc.
    start_hour   = optional(number, 2) # Hour in UTC (0-23)
    start_minute = optional(number, 0) # Minute (0-59)
  })
  default = {
    day_of_week  = 0 # Sunday
    start_hour   = 2 # 2 AM UTC
    start_minute = 0
  }

  validation {
    condition = (
      var.maintenance_window.day_of_week >= 0 && var.maintenance_window.day_of_week <= 6 &&
      var.maintenance_window.start_hour >= 0 && var.maintenance_window.start_hour <= 23 &&
      var.maintenance_window.start_minute >= 0 && var.maintenance_window.start_minute <= 59
    )
    error_message = "Maintenance window values must be valid: day_of_week (0-6), start_hour (0-23), start_minute (0-59)."
  }
}

# Key Vault Integration
variable "enable_keyvault_integration" {
  description = "Enable storing database credentials in Key Vault"
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
    admin_username    = optional(string, "postgres-admin-username")
    admin_password    = optional(string, "postgres-admin-password") # pragma: allowlist secret
    connection_string = optional(string, "postgres-connection-string")
  })
  default = {
    admin_username    = "postgres-admin-username"
    admin_password    = "postgres-admin-password" # pragma: allowlist secret
    connection_string = "postgres-connection-string"
  }
}
