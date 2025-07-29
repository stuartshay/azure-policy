# Azure App Service Module
# This module creates an Azure App Service with associated resources

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.workload}-${var.environment}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name

  tags = var.tags
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.workload}-${var.environment}-001"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = var.always_on

    application_stack {
      python_version = var.python_version
    }
  }

  app_settings = var.app_settings

  tags = var.tags
}
