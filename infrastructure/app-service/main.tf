# Azure App Service Infrastructure
# This file defines the Azure App Service deployment infrastructure

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.39"
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

    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    application_insights {
      disable_generated_rule = false
    }
  }
}

# Data sources to get existing infrastructure
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Data source to get VNet information from core infrastructure
data "azurerm_virtual_network" "main" {
  count               = var.enable_vnet_integration ? 1 : 0
  name                = "vnet-${var.workload}-${var.environment}-${local.location_short}-001"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Data source to get subnet for VNet integration
data "azurerm_subnet" "functions" {
  count                = var.enable_vnet_integration ? 1 : 0
  name                 = "snet-functions-${var.workload}-${var.environment}-${local.location_short}-001"
  virtual_network_name = data.azurerm_virtual_network.main[0].name
  resource_group_name  = data.azurerm_resource_group.main.name
}

# Common tags for Functions resources
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
    Project     = "azurepolicy"
    Owner       = var.owner
    CreatedBy   = "terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    Component   = "functions"
  }
}

# Storage Account for Functions
resource "azurerm_storage_account" "functions" {
  #checkov:skip=CKV2_AZURE_40:Shared access key is required for Function Apps
  name                     = "stfunc${var.workload}${var.environment}001"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # Security configurations
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true # Required for Function Apps
  public_network_access_enabled   = true # Required for Function Apps

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  # SAS expiration policy
  sas_policy {
    expiration_period = "01.00:00:00" # 1 day
    expiration_action = "Log"
  }

  tags = local.common_tags
}

# App Service Plan for Functions
resource "azurerm_service_plan" "functions" {
  name                = "asp-${var.workload}-functions-${var.environment}-001"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.functions_sku_name

  # EP1 specific configurations
  maximum_elastic_worker_count = var.functions_sku_name == "EP1" ? var.maximum_elastic_worker_count : null

  tags = local.common_tags
}

# Function App
resource "azurerm_linux_function_app" "main" {
  count = var.deploy_function_app ? 1 : 0

  name                = "func-${var.workload}-${var.environment}-001"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  service_plan_id            = azurerm_service_plan.functions.id

  # Security configurations
  https_only                    = true
  public_network_access_enabled = var.enable_vnet_integration ? false : true

  # VNet Integration
  dynamic "site_config" {
    for_each = [1]
    content {
      application_stack {
        python_version = var.python_version
      }

      # EP1 specific configurations
      always_on                 = var.functions_sku_name != "Y1" ? true : false
      pre_warmed_instance_count = var.functions_sku_name == "EP1" ? var.always_ready_instances : null
      elastic_instance_minimum  = var.functions_sku_name == "EP1" ? var.always_ready_instances : null

      # VNet integration settings
      vnet_route_all_enabled = var.enable_vnet_integration

      application_insights_connection_string = var.enable_application_insights ? azurerm_application_insights.functions[0].connection_string : null
      application_insights_key               = var.enable_application_insights ? azurerm_application_insights.functions[0].instrumentation_key : null
    }
  }

  app_settings = merge(
    var.function_app_settings,
    {
      "FUNCTIONS_WORKER_RUNTIME"           = "python"
      "PYTHON_ISOLATE_WORKER_DEPENDENCIES" = "1"
      "WEBSITE_VNET_ROUTE_ALL"             = var.enable_vnet_integration ? "1" : "0"
    }
  )

  tags = local.common_tags
}

# VNet Integration for Function App
resource "azurerm_app_service_virtual_network_swift_connection" "functions" {
  count          = var.deploy_function_app && var.enable_vnet_integration ? 1 : 0
  app_service_id = azurerm_linux_function_app.main[0].id
  subnet_id      = var.vnet_integration_subnet_id != null ? var.vnet_integration_subnet_id : data.azurerm_subnet.functions[0].id
}

# Application Insights (optional)
resource "azurerm_application_insights" "functions" {
  count = var.enable_application_insights ? 1 : 0

  name                = "appi-${var.workload}-functions-${var.environment}-001"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  application_type    = "web"

  tags = local.common_tags
}
