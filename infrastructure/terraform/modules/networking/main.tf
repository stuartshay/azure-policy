# Networking Module - Main Configuration
# This module creates VNet, Subnets, and Network Security Groups

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.39"
    }
  }
}

# Local values for consistent naming
locals {
  vnet_name = "vnet-${var.workload}-${var.environment}-${var.location_short}-001"

  # Create NSG names for each subnet
  nsg_names = {
    for subnet_name, subnet_config in var.subnet_config :
    subnet_name => "nsg-${var.workload}-${subnet_name}-${var.environment}-${var.location_short}-001"
  }

  # Create subnet names
  subnet_names = {
    for subnet_name, subnet_config in var.subnet_config :
    subnet_name => "snet-${subnet_name}-${var.workload}-${var.environment}-${var.location_short}-001"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = local.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = var.tags
}

# Network Security Groups
resource "azurerm_network_security_group" "main" {
  for_each = var.subnet_config

  name                = local.nsg_names[each.key]
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Default NSG Rules for all subnets
resource "azurerm_network_security_rule" "allow_https_inbound" {
  for_each = var.subnet_config

  name                        = "Allow-HTTPS-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[each.key].name
}

resource "azurerm_network_security_rule" "deny_http_inbound" {
  for_each = var.subnet_config

  name                        = "Deny-HTTP-Inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[each.key].name
}

# App Service specific rules for app service subnet
resource "azurerm_network_security_rule" "allow_app_service_management" {
  count = contains(keys(var.subnet_config), "appservice") ? 1 : 0

  name                        = "Allow-AppService-Management"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["454-455"]
  source_address_prefix       = "AppServiceManagement"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main["appservice"].name
}

# Function App specific rules for functions subnet
resource "azurerm_network_security_rule" "allow_function_app_management" {
  count = contains(keys(var.subnet_config), "functions") ? 1 : 0

  name                        = "Allow-FunctionApp-Management"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_ranges     = ["454-455"]
  source_address_prefix       = "AppServiceManagement"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main["functions"].name
}

# Outbound rules - Allow HTTPS and DNS
resource "azurerm_network_security_rule" "allow_https_outbound" {
  for_each = var.subnet_config

  name                        = "Allow-HTTPS-Outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[each.key].name
}

resource "azurerm_network_security_rule" "allow_dns_outbound" {
  for_each = var.subnet_config

  name                        = "Allow-DNS-Outbound"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "53"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.main[each.key].name
}

# Subnets
resource "azurerm_subnet" "main" {
  for_each = var.subnet_config

  name                 = local.subnet_names[each.key]
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  # Delegation configuration (if specified)
  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# Associate NSGs with Subnets
resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = var.subnet_config

  subnet_id                 = azurerm_subnet.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main[each.key].id
}

# Route Table (optional, for future use)
resource "azurerm_route_table" "main" {
  count = var.enable_custom_routes ? 1 : 0

  name                = "rt-${var.workload}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Enable BGP route propagation for more control
  bgp_route_propagation_enabled = true

  tags = var.tags
}

# Default route (if custom routes enabled)
resource "azurerm_route" "default" {
  count = var.enable_custom_routes ? 1 : 0

  name                = "default-route"
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.main[0].name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

# Associate route table with subnets (if enabled)
resource "azurerm_subnet_route_table_association" "main" {
  for_each = var.enable_custom_routes ? var.subnet_config : {}

  subnet_id      = azurerm_subnet.main[each.key].id
  route_table_id = azurerm_route_table.main[0].id
}

# Network Watcher (for monitoring and diagnostics)
resource "azurerm_network_watcher" "main" {
  count = var.enable_network_watcher ? 1 : 0

  name                = "nw-${var.workload}-${var.environment}-${var.location_short}-001"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Flow logs storage account (for VNet flow logs)
resource "azurerm_storage_account" "flow_logs" {
  #checkov:skip=CKV2_AZURE_40:Shared access key is required for VNet flow logs functionality
  count = var.enable_network_watcher && var.enable_flow_logs ? 1 : 0

  name                     = "stflowlogs${var.workload}${var.environment}001"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security configurations
  shared_access_key_enabled       = true # Required for flow logs
  allow_nested_items_to_be_public = false

  # SAS expiration policy
  sas_policy {
    expiration_period = "01.00:00:00"
    expiration_action = "Log"
  }

  # Blob soft delete
  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# VNet Flow Logs (replaces NSG flow logs - future-proof for NSG flow log retirement in Sept 2027)
resource "azurerm_network_watcher_flow_log" "vnet" {
  count = var.enable_network_watcher && var.enable_flow_logs ? 1 : 0

  network_watcher_name = azurerm_network_watcher.main[0].name
  resource_group_name  = var.resource_group_name
  name                 = "fl-vnet-${var.workload}-${var.environment}"

  # Target the VNet instead of individual NSGs
  target_resource_id = azurerm_virtual_network.main.id
  storage_account_id = azurerm_storage_account.flow_logs[0].id
  enabled            = true
  version            = 2 # VNet flow logs use version 2

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics && var.log_analytics_workspace_id != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_id
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_resource_id
    }
  }

  tags = var.tags
}

# Legacy NSG Flow Logs (deprecated - will be removed after VNet flow logs are validated)
# These will be retired on September 30, 2027. New NSG flow logs cannot be created after June 30, 2025.
# Note: This resource is being phased out in favor of VNet flow logs
resource "azurerm_network_watcher_flow_log" "nsg_legacy" {
  for_each = var.enable_legacy_nsg_flow_logs && var.enable_network_watcher && var.enable_flow_logs ? var.subnet_config : {}

  network_watcher_name = azurerm_network_watcher.main[0].name
  resource_group_name  = var.resource_group_name
  name                 = "fl-nsg-${each.key}-${var.environment}-legacy"

  target_resource_id = azurerm_network_security_group.main[each.key].id
  storage_account_id = azurerm_storage_account.flow_logs[0].id
  enabled            = true

  retention_policy {
    enabled = true
    days    = var.flow_log_retention_days
  }

  dynamic "traffic_analytics" {
    for_each = var.enable_traffic_analytics && var.log_analytics_workspace_id != null ? [1] : []
    content {
      enabled               = true
      workspace_id          = var.log_analytics_workspace_id
      workspace_region      = var.location
      workspace_resource_id = var.log_analytics_workspace_resource_id
    }
  }

  tags = merge(var.tags, {
    "Deprecated"     = "true"
    "RetirementDate" = "2027-09-30"
    "ReplacedBy"     = "VNet Flow Logs"
  })
}
