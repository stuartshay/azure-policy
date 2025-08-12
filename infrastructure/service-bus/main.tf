# Azure Service Bus Infrastructure
# This module creates Azure Service Bus namespace and queues for the Azure Policy project

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.37"
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

# Data sources to get existing infrastructure
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Data source to get VNet information from core infrastructure (for private endpoint support)
data "azurerm_virtual_network" "main" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "vnet-${var.workload}-${var.environment}-${local.location_short}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Data source to get subnet for private endpoints (using default subnet)
data "azurerm_subnet" "private_endpoints" {
  count                = var.enable_private_endpoint ? 1 : 0
  name                 = "snet-default-${var.workload}-${var.environment}-${local.location_short}-001"
  virtual_network_name = data.azurerm_virtual_network.main[0].name
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

  # Default queues for Azure Policy workflows
  default_queues = [
    "policy-compliance-checks",
    "policy-remediation-tasks",
    "policy-audit-logs",
    "policy-notifications"
  ]

  # Default topics for pub/sub scenarios
  default_topics = [
    "policy-events",
    "compliance-reports"
  ]

  # Merge default and custom queues
  all_queues = concat(local.default_queues, var.custom_queues)
  all_topics = concat(local.default_topics, var.custom_topics)
}

# Service Bus Namespace
resource "azurerm_servicebus_namespace" "main" {
  name                = "sb-${var.workload}-${var.environment}-${local.location_short}-001"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = var.service_bus_sku

  # Premium SKU specific settings
  capacity = var.service_bus_sku == "Premium" ? var.premium_messaging_units : null

  # Public network access
  public_network_access_enabled = var.enable_private_endpoint ? false : true

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Service Bus Queues
resource "azurerm_servicebus_queue" "queues" {
  for_each = toset(local.all_queues)

  name         = each.value
  namespace_id = azurerm_servicebus_namespace.main.id

  # Queue configuration
  partitioning_enabled                    = var.enable_partitioning
  max_size_in_megabytes                   = var.max_queue_size_mb
  default_message_ttl                     = var.default_message_ttl
  duplicate_detection_history_time_window = var.duplicate_detection_window
  requires_duplicate_detection            = var.enable_duplicate_detection
  dead_lettering_on_message_expiration    = true
  max_delivery_count                      = var.max_delivery_count

  # Auto-delete configuration
  auto_delete_on_idle = var.auto_delete_on_idle
}

# Service Bus Topics
resource "azurerm_servicebus_topic" "topics" {
  for_each = toset(local.all_topics)

  name         = each.value
  namespace_id = azurerm_servicebus_namespace.main.id

  # Topic configuration
  partitioning_enabled                    = var.enable_partitioning
  max_size_in_megabytes                   = var.max_topic_size_mb
  default_message_ttl                     = var.default_message_ttl
  duplicate_detection_history_time_window = var.duplicate_detection_window
  requires_duplicate_detection            = var.enable_duplicate_detection

  # Auto-delete configuration
  auto_delete_on_idle = var.auto_delete_on_idle
}

# Service Bus Topic Subscriptions
resource "azurerm_servicebus_subscription" "policy_events_all" {
  name     = "all-policy-events"
  topic_id = azurerm_servicebus_topic.topics["policy-events"].id

  max_delivery_count                   = var.max_delivery_count
  dead_lettering_on_message_expiration = true
  default_message_ttl                  = var.default_message_ttl
}

resource "azurerm_servicebus_subscription" "compliance_reports_all" {
  name     = "all-compliance-reports"
  topic_id = azurerm_servicebus_topic.topics["compliance-reports"].id

  max_delivery_count                   = var.max_delivery_count
  dead_lettering_on_message_expiration = true
  default_message_ttl                  = var.default_message_ttl
}

# Private Endpoint for Service Bus (if enabled)
resource "azurerm_private_endpoint" "service_bus" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-${azurerm_servicebus_namespace.main.name}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = data.azurerm_subnet.private_endpoints[0].id

  private_service_connection {
    name                           = "psc-${azurerm_servicebus_namespace.main.name}"
    private_connection_resource_id = azurerm_servicebus_namespace.main.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  tags = local.common_tags
}

# Authorization Rules for Function App access
resource "azurerm_servicebus_namespace_authorization_rule" "function_app_access" {
  name         = "FunctionAppAccess"
  namespace_id = azurerm_servicebus_namespace.main.id

  listen = true
  send   = true
  manage = false
}

# Additional authorization rule for read-only access (monitoring/reporting)
resource "azurerm_servicebus_namespace_authorization_rule" "read_only" {
  name         = "ReadOnlyAccess"
  namespace_id = azurerm_servicebus_namespace.main.id

  listen = true
  send   = false
  manage = false
}

# Additional authorization rule for admin access
resource "azurerm_servicebus_namespace_authorization_rule" "admin_access" {
  count        = var.create_admin_access_rule ? 1 : 0
  name         = "AdminAccess"
  namespace_id = azurerm_servicebus_namespace.main.id

  listen = true
  send   = true
  manage = true
}
