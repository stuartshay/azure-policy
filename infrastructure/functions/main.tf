# Azure Functions Infrastructure
# This file defines the Azure Functions deployment infrastructure

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.37"
    }
  }

  # Terraform Cloud backend for state management
  cloud {
    organization = "azure-policy-cloud"

    workspaces {
      name = "azure-policy-functions"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Data sources to get existing infrastructure
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Common tags for Functions resources
locals {
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

  tags = local.common_tags
}

# Function App
resource "azurerm_linux_function_app" "main" {
  name                = "func-${var.workload}-${var.environment}-001"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key
  service_plan_id            = azurerm_service_plan.functions.id

  # Security configurations
  https_only                    = true
  public_network_access_enabled = false

  site_config {
    application_stack {
      python_version = var.python_version
    }

    application_insights_connection_string = var.enable_application_insights ? azurerm_application_insights.functions[0].connection_string : null
    application_insights_key               = var.enable_application_insights ? azurerm_application_insights.functions[0].instrumentation_key : null
  }

  app_settings = merge(
    var.function_app_settings,
    {
      "FUNCTIONS_WORKER_RUNTIME"           = "python"
      "PYTHON_ISOLATE_WORKER_DEPENDENCIES" = "1"
    }
  )

  tags = local.common_tags
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
