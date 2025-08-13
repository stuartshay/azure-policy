# Azure Database for PostgreSQL - Outputs
# This file defines outputs from the PostgreSQL infrastructure

output "postgresql_server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgresql_server_id" {
  description = "ID of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "postgresql_server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_server_version" {
  description = "PostgreSQL server version"
  value       = azurerm_postgresql_flexible_server.main.version
}

output "postgresql_admin_username" {
  description = "Administrator username for PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "postgresql_admin_password" {
  description = "Administrator password for PostgreSQL server"
  value       = var.admin_password != null ? var.admin_password : random_password.postgres_admin.result
  sensitive   = true
}

output "database_name" {
  description = "Name of the default database"
  value       = azurerm_postgresql_flexible_server_database.app_database.name
}

output "additional_database_names" {
  description = "Names of additional databases created"
  value       = [for db in azurerm_postgresql_flexible_server_database.additional_databases : db.name]
}

# output "private_endpoint_ip" {
#   description = "Private IP address of the PostgreSQL server"
#   value       = azurerm_private_endpoint.postgres.private_service_connection[0].private_ip_address
# }

output "private_dns_zone_name" {
  description = "Name of the private DNS zone"
  value       = azurerm_private_dns_zone.postgres.name
}

# Connection strings for Function App integration
output "connection_string_full" {
  description = "Full PostgreSQL connection string for applications"
  value = format(
    "postgresql://%s:%s@%s:5432/%s?sslmode=require",
    azurerm_postgresql_flexible_server.main.administrator_login,
    var.admin_password != null ? var.admin_password : random_password.postgres_admin.result,
    azurerm_postgresql_flexible_server.main.fqdn,
    azurerm_postgresql_flexible_server_database.app_database.name
  )
  sensitive = true
}

output "connection_string_template" {
  description = "PostgreSQL connection string template (password placeholder)"
  value = format(
    "postgresql://%s:{password}@%s:5432/%s?sslmode=require",
    azurerm_postgresql_flexible_server.main.administrator_login,
    azurerm_postgresql_flexible_server.main.fqdn,
    azurerm_postgresql_flexible_server_database.app_database.name
  )
}

# Individual connection components for Function App settings
output "connection_components" {
  description = "Individual connection components for Function App configuration"
  value = {
    host     = azurerm_postgresql_flexible_server.main.fqdn
    port     = "5432"
    database = azurerm_postgresql_flexible_server_database.app_database.name
    username = azurerm_postgresql_flexible_server.main.administrator_login
    password = var.admin_password != null ? var.admin_password : random_password.postgres_admin.result
    sslmode  = "require"
  }
  sensitive = true
}

# Configuration summary for Function App integration
output "database_config_for_functions" {
  description = "Database configuration summary for Function App integration"
  value = {
    server_name    = azurerm_postgresql_flexible_server.main.name
    server_fqdn    = azurerm_postgresql_flexible_server.main.fqdn
    database_name  = azurerm_postgresql_flexible_server_database.app_database.name
    admin_username = azurerm_postgresql_flexible_server.main.administrator_login
    admin_password = var.admin_password != null ? var.admin_password : random_password.postgres_admin.result
    connection_string = format(
      "postgresql://%s:%s@%s:5432/%s?sslmode=require",
      azurerm_postgresql_flexible_server.main.administrator_login,
      var.admin_password != null ? var.admin_password : random_password.postgres_admin.result,
      azurerm_postgresql_flexible_server.main.fqdn,
      azurerm_postgresql_flexible_server_database.app_database.name
    )
    private_endpoint_enabled = false
    # private_ip               = azurerm_private_endpoint.postgres.private_service_connection[0].private_ip_address
    ssl_enforcement  = true
    postgres_version = azurerm_postgresql_flexible_server.main.version
  }
  sensitive = true
}

# Server configuration details
output "server_configuration" {
  description = "PostgreSQL server configuration details"
  value = {
    sku_name                     = var.sku_name
    storage_mb                   = var.storage_mb
    backup_retention_days        = var.backup_retention_days
    geo_redundant_backup_enabled = var.geo_redundant_backup_enabled
    availability_zone            = var.availability_zone
    high_availability_enabled    = false
    public_network_access        = true
    ssl_enforcement_enabled      = true
    ssl_minimal_tls_version      = "TLS1_2"
  }
}

# Network configuration
output "network_configuration" {
  description = "Network configuration details"
  value = {
    # private_endpoint_id = azurerm_private_endpoint.postgres.id
    private_dns_zone_id = azurerm_private_dns_zone.postgres.id
    vnet_integration    = false
    # subnet_id           = data.azurerm_subnet.private_endpoints.id
    functions_subnet_id = data.azurerm_subnet.functions.id
  }
}

# Cost optimization information
output "cost_optimization_info" {
  description = "Information about cost optimization settings"
  value = {
    tier                       = "Burstable"
    sku                        = var.sku_name
    high_availability_disabled = true
    geo_redundant_backup       = var.geo_redundant_backup_enabled
    minimum_storage_gb         = var.storage_mb / 1024
    estimated_monthly_cost_usd = "12-15" # Approximate for B_Standard_B1ms
  }
}

# Monitoring and performance outputs
output "monitoring_configuration" {
  description = "Monitoring and performance configuration"
  value = {
    query_store_enabled          = var.enable_query_store
    performance_insights_enabled = var.enable_performance_insights
    log_min_duration_statement   = "1000ms"
    shared_preload_libraries     = "pg_stat_statements"
  }
}
