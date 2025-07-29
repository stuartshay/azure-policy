# Networking Module - Outputs
# This file defines all output values from the networking module

# Virtual Network Outputs
output "vnet_id" {
  description = "ID of the created virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the created virtual network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_address_space" {
  description = "Address space of the virtual network"
  value       = azurerm_virtual_network.main.address_space
}

output "vnet_location" {
  description = "Location of the virtual network"
  value       = azurerm_virtual_network.main.location
}

output "vnet_resource_group_name" {
  description = "Resource group name of the virtual network"
  value       = azurerm_virtual_network.main.resource_group_name
}

# Subnet Outputs
output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for subnet_name, subnet in azurerm_subnet.main : subnet_name => subnet.id
  }
}

output "subnet_names" {
  description = "Map of subnet keys to their actual names"
  value = {
    for subnet_name, subnet in azurerm_subnet.main : subnet_name => subnet.name
  }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes"
  value = {
    for subnet_name, subnet in azurerm_subnet.main : subnet_name => subnet.address_prefixes
  }
}

output "subnet_service_endpoints" {
  description = "Map of subnet names to their service endpoints"
  value = {
    for subnet_name, subnet in azurerm_subnet.main : subnet_name => subnet.service_endpoints
  }
}

# Network Security Group Outputs
output "nsg_ids" {
  description = "Map of NSG names to their IDs"
  value = {
    for nsg_name, nsg in azurerm_network_security_group.main : nsg_name => nsg.id
  }
}

output "nsg_names" {
  description = "Map of NSG keys to their actual names"
  value = {
    for nsg_name, nsg in azurerm_network_security_group.main : nsg_name => nsg.name
  }
}

output "nsg_locations" {
  description = "Map of NSG names to their locations"
  value = {
    for nsg_name, nsg in azurerm_network_security_group.main : nsg_name => nsg.location
  }
}

# Route Table Outputs (if enabled)
output "route_table_id" {
  description = "ID of the route table (if enabled)"
  value       = var.enable_custom_routes ? azurerm_route_table.main[0].id : null
}

output "route_table_name" {
  description = "Name of the route table (if enabled)"
  value       = var.enable_custom_routes ? azurerm_route_table.main[0].name : null
}

# Network Watcher Outputs (if enabled)
output "network_watcher_id" {
  description = "ID of the Network Watcher (if enabled)"
  value       = var.enable_network_watcher ? azurerm_network_watcher.main[0].id : null
}

output "network_watcher_name" {
  description = "Name of the Network Watcher (if enabled)"
  value       = var.enable_network_watcher ? azurerm_network_watcher.main[0].name : null
}

# Flow Logs Storage Account Outputs (if enabled)
output "flow_logs_storage_account_id" {
  description = "ID of the flow logs storage account (if enabled)"
  value       = var.enable_network_watcher && var.enable_flow_logs ? azurerm_storage_account.flow_logs[0].id : null
}

output "flow_logs_storage_account_name" {
  description = "Name of the flow logs storage account (if enabled)"
  value       = var.enable_network_watcher && var.enable_flow_logs ? azurerm_storage_account.flow_logs[0].name : null
}

output "flow_logs_storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the flow logs storage account (if enabled)"
  value       = var.enable_network_watcher && var.enable_flow_logs ? azurerm_storage_account.flow_logs[0].primary_blob_endpoint : null
}

# Flow Log Outputs (if enabled)
output "flow_log_ids" {
  description = "Map of flow log names to their IDs (if enabled)"
  value = var.enable_network_watcher && var.enable_flow_logs ? {
    for flow_log_name, flow_log in azurerm_network_watcher_flow_log.main : flow_log_name => flow_log.id
  } : {}
}

# Network Security Group Association Outputs
output "subnet_nsg_associations" {
  description = "Map of subnet names to their NSG association IDs"
  value = {
    for assoc_name, assoc in azurerm_subnet_network_security_group_association.main : assoc_name => assoc.id
  }
}

# Route Table Association Outputs (if enabled)
output "subnet_route_table_associations" {
  description = "Map of subnet names to their route table association IDs (if enabled)"
  value = var.enable_custom_routes ? {
    for assoc_name, assoc in azurerm_subnet_route_table_association.main : assoc_name => assoc.id
  } : {}
}

# Networking Configuration Summary
output "networking_summary" {
  description = "Summary of networking configuration"
  value = {
    vnet_name                 = azurerm_virtual_network.main.name
    vnet_address_space        = azurerm_virtual_network.main.address_space
    subnet_count              = length(azurerm_subnet.main)
    nsg_count                 = length(azurerm_network_security_group.main)
    custom_routes_enabled     = var.enable_custom_routes
    network_watcher_enabled   = var.enable_network_watcher
    flow_logs_enabled         = var.enable_flow_logs
    traffic_analytics_enabled = var.enable_traffic_analytics
  }
}

# Subnet Details for App Service Integration
output "app_service_subnet_id" {
  description = "ID of the App Service subnet (if exists)"
  value       = contains(keys(var.subnet_config), "appservice") ? azurerm_subnet.main["appservice"].id : null
}

output "app_service_subnet_name" {
  description = "Name of the App Service subnet (if exists)"
  value       = contains(keys(var.subnet_config), "appservice") ? azurerm_subnet.main["appservice"].name : null
}

output "functions_subnet_id" {
  description = "ID of the Functions subnet (if exists)"
  value       = contains(keys(var.subnet_config), "functions") ? azurerm_subnet.main["functions"].id : null
}

output "functions_subnet_name" {
  description = "Name of the Functions subnet (if exists)"
  value       = contains(keys(var.subnet_config), "functions") ? azurerm_subnet.main["functions"].name : null
}

output "private_endpoints_subnet_id" {
  description = "ID of the Private Endpoints subnet (if exists)"
  value       = contains(keys(var.subnet_config), "privateendpoints") ? azurerm_subnet.main["privateendpoints"].id : null
}

output "private_endpoints_subnet_name" {
  description = "Name of the Private Endpoints subnet (if exists)"
  value       = contains(keys(var.subnet_config), "privateendpoints") ? azurerm_subnet.main["privateendpoints"].name : null
}

# Security Information
output "security_summary" {
  description = "Summary of network security configuration"
  value = {
    nsg_rules_count = {
      for nsg_name, nsg in azurerm_network_security_group.main : nsg_name => length(nsg.security_rule)
    }
    default_rules_applied = [
      "Allow-HTTPS-Inbound",
      "Allow-HTTP-Inbound",
      "Allow-HTTPS-Outbound",
      "Allow-DNS-Outbound"
    ]
    app_service_rules_applied  = contains(keys(var.subnet_config), "appservice")
    function_app_rules_applied = contains(keys(var.subnet_config), "functions")
  }
}

# Resource Names for Reference
output "resource_names" {
  description = "Map of all created resource names for reference"
  value = {
    vnet_name = azurerm_virtual_network.main.name
    subnet_names = {
      for subnet_name, subnet in azurerm_subnet.main : subnet_name => subnet.name
    }
    nsg_names = {
      for nsg_name, nsg in azurerm_network_security_group.main : nsg_name => nsg.name
    }
    route_table_name       = var.enable_custom_routes ? azurerm_route_table.main[0].name : null
    network_watcher_name   = var.enable_network_watcher ? azurerm_network_watcher.main[0].name : null
    flow_logs_storage_name = var.enable_network_watcher && var.enable_flow_logs ? azurerm_storage_account.flow_logs[0].name : null
  }
}

# Connectivity Information
output "connectivity_info" {
  description = "Information for connecting other resources to the network"
  value = {
    vnet_id             = azurerm_virtual_network.main.id
    vnet_name           = azurerm_virtual_network.main.name
    resource_group_name = azurerm_virtual_network.main.resource_group_name
    location            = azurerm_virtual_network.main.location
    subnet_ids = {
      for subnet_name, subnet in azurerm_subnet.main : subnet_name => subnet.id
    }
    nsg_ids = {
      for nsg_name, nsg in azurerm_network_security_group.main : nsg_name => nsg.id
    }
  }
}
