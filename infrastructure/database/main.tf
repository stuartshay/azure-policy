# Azure Database for PostgreSQL Infrastructure
# This module creates a low-cost PostgreSQL Flexible Server for the Azure Policy project

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.37"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  # Local backend for deployment
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Random password for PostgreSQL admin
resource "random_password" "postgres_admin" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Data sources to get existing infrastructure
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Data source to get VNet information from core infrastructure
data "azurerm_virtual_network" "main" {
  name                = "vnet-${var.workload}-${var.environment}-${local.location_short}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Data source to get subnet for private endpoints
# data "azurerm_subnet" "private_endpoints" {
#   name                 = "snet-privateendpoints-${var.workload}-${var.environment}-${local.location_short}-001"
#   virtual_network_name = data.azurerm_virtual_network.main.name
#   resource_group_name  = data.azurerm_resource_group.main.name
# }

# Data source to get functions subnet for firewall rules
data "azurerm_subnet" "functions" {
  name                 = "snet-functions-${var.workload}-${var.environment}-${local.location_short}-001"
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

# Common configuration
locals {
  # Location mapping for consistent naming
  location_short_map = {
    "East US"   = "eastus"
    "East US 2" = "eastus2"
  }

  location_short = local.location_short_map[var.location]

  common_tags = {
    Environment = var.environment
    CostCenter  = var.cost_center
    Owner       = var.owner
    Workload    = var.workload
    ManagedBy   = "terraform"
    CreatedDate = timestamp()
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${var.workload}-${var.environment}-${local.location_short}-001"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  # Admin credentials
  administrator_login    = var.admin_username
  administrator_password = var.admin_password != null ? var.admin_password : random_password.postgres_admin.result

  # Server configuration - Lowest cost tier
  sku_name   = var.sku_name
  version    = var.postgres_version
  storage_mb = var.storage_mb

  # Backup configuration
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # Security configuration - Enable public access for development
  public_network_access_enabled = true

  # Zone configuration (optional for cost optimization)
  zone = var.availability_zone

  # Maintenance window configuration
  maintenance_window {
    day_of_week  = var.maintenance_window.day_of_week
    start_hour   = var.maintenance_window.start_hour
    start_minute = var.maintenance_window.start_minute
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
      administrator_password, # Prevent password changes on subsequent applies
      zone,                   # Prevent zone changes without high availability configuration
    ]
  }
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = local.common_tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-dns-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = data.azurerm_virtual_network.main.id

  tags = local.common_tags
}

# Private Endpoint for PostgreSQL (disabled for development)
# resource "azurerm_private_endpoint" "postgres" {
#   name                = "pe-${azurerm_postgresql_flexible_server.main.name}"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main.name
#   subnet_id           = data.azurerm_subnet.private_endpoints.id
#
#   private_service_connection {
#     name                           = "psc-${azurerm_postgresql_flexible_server.main.name}"
#     private_connection_resource_id = azurerm_postgresql_flexible_server.main.id
#     subresource_names              = ["postgresqlServer"]
#     is_manual_connection           = false
#   }
#
#   private_dns_zone_group {
#     name                 = "postgres-dns-zone-group"
#     private_dns_zone_ids = [azurerm_private_dns_zone.postgres.id]
#   }
#
#   tags = local.common_tags
# }

# Firewall rule to allow access from Functions subnet
resource "azurerm_postgresql_flexible_server_firewall_rule" "functions_subnet" {
  name             = "allow-functions-subnet"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = cidrhost(data.azurerm_subnet.functions.address_prefixes[0], 0)
  end_ip_address   = cidrhost(data.azurerm_subnet.functions.address_prefixes[0], -1)
}

# Firewall rule to allow access from development environment
resource "azurerm_postgresql_flexible_server_firewall_rule" "dev_access" {
  name             = "allow-dev-access"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "108.5.250.137"
  end_ip_address   = "108.5.250.137"
}

# Additional firewall rules for allowed CIDR blocks
resource "azurerm_postgresql_flexible_server_firewall_rule" "allowed_cidrs" {
  for_each = { for idx, cidr in var.allowed_cidrs : idx => cidr }

  name             = "allow-cidr-${each.key}"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = cidrhost(each.value, 0)
  end_ip_address   = cidrhost(each.value, -1)
}

# Default database for the application
resource "azurerm_postgresql_flexible_server_database" "app_database" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Additional databases (if specified)
resource "azurerm_postgresql_flexible_server_database" "additional_databases" {
  for_each = toset(var.additional_databases)

  name      = each.value
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# PostgreSQL configuration for optimal performance
resource "azurerm_postgresql_flexible_server_configuration" "shared_preload_libraries" {
  name      = "shared_preload_libraries"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "pg_stat_statements"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  name      = "log_statement"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "none"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_min_duration_statement" {
  name      = "log_min_duration_statement"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "1000" # Log queries taking longer than 1 second
}
