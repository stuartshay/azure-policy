# Azure Function App Deployment
# This module deploys the actual Function App that depends on the app-service infrastructure
# Requires: app-service module to be deployed first

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.39"
    }
  }

  backend "local" {}
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Data source to get app-service infrastructure outputs
data "terraform_remote_state" "app_service" {
  backend = "local"
  config = {
    path = "../app-service/terraform.tfstate"
  }
}

# Data sources for existing resources created by app-service module
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "functions" {
  name                = data.terraform_remote_state.app_service.outputs.storage_account_name
  resource_group_name = var.resource_group_name
}

# Function App
resource "azurerm_linux_function_app" "main" {
  name                       = "func-${var.workload}-${var.environment}-001"
  resource_group_name        = data.azurerm_resource_group.main.name
  location                   = data.azurerm_resource_group.main.location
  service_plan_id            = data.terraform_remote_state.app_service.outputs.app_service_plan_id
  storage_account_name       = data.azurerm_storage_account.functions.name
  storage_account_access_key = data.azurerm_storage_account.functions.primary_access_key

  # Security configurations
  https_only                    = true
  public_network_access_enabled = false

  # Function App Configuration
  site_config {
    always_on = var.functions_sku_name != "Y1" # Always on for non-consumption plans

    application_stack {
      python_version = var.python_version
    }

    # Pre-warmed instances for EP1
    pre_warmed_instance_count = var.functions_sku_name == "EP1" ? var.always_ready_instances : null
  }

  # VNet Integration (if enabled in app-service)
  virtual_network_subnet_id = data.terraform_remote_state.app_service.outputs.vnet_integration_enabled && data.terraform_remote_state.app_service.outputs.vnet_integration_subnet_id != null ? data.terraform_remote_state.app_service.outputs.vnet_integration_subnet_id : null

  # Function App Settings
  app_settings = merge(
    {
      # Required Function App settings
      "AzureWebJobsStorage"                      = data.azurerm_storage_account.functions.primary_connection_string
      "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = data.azurerm_storage_account.functions.primary_connection_string
      "WEBSITE_CONTENTSHARE"                     = "${lower(var.workload)}-functions-${var.environment}"
      "FUNCTIONS_EXTENSION_VERSION"              = "~4"
      "FUNCTIONS_WORKER_RUNTIME"                 = "python"
      "PYTHON_VERSION"                           = var.python_version

      # Application Insights (if enabled)
      "APPINSIGHTS_INSTRUMENTATIONKEY"        = data.terraform_remote_state.app_service.outputs.application_insights_instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = data.terraform_remote_state.app_service.outputs.application_insights_connection_string

      # EP1 specific settings
      "WEBSITE_MAX_DYNAMIC_APPLICATION_SCALE_OUT" = var.functions_sku_name == "EP1" ? var.maximum_elastic_worker_count : null
    },
    var.function_app_settings
  )

  # Tags
  tags = {
    Environment = var.environment
    Workload    = var.workload
    CostCenter  = var.cost_center
    Owner       = var.owner
    ManagedBy   = "terraform"
    CreatedDate = timestamp()
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}
