# Azure Policy Infrastructure - Main Configuration
# This file defines the core infrastructure for the Azure Policy project

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  backend "azurerm" {
    # Backend configuration will be provided via backend config file
    # or environment variables during terraform init
  }
}

provider "azurerm" {
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

# Get current client configuration
data "azurerm_client_config" "current" {}

# Random suffix for globally unique resources
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Local values for consistent naming and tagging
locals {
  # Naming components
  workload = "azurepolicy"
  location_short = {
    "East US"   = "eastus"
    "East US 2" = "eastus2"
  }

  # Resource names
  resource_group_name = "rg-${local.workload}-${var.environment}-${local.location_short[var.location]}"

  # Common tags applied to all resources
  common_tags = {
    Environment = var.environment
    CostCenter  = var.cost_center
    Project     = "azurepolicy"
    Owner       = var.owner
    CreatedBy   = "terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  workload           = local.workload
  location_short     = local.location_short[var.location]

  # Network configuration
  vnet_address_space = var.vnet_address_space
  subnet_config      = var.subnet_config

  tags = local.common_tags
}

# App Service Module
module "app_service" {
  source = "./modules/app-service"

  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  workload           = local.workload
  location_short     = local.location_short[var.location]
  random_suffix      = random_string.suffix.result

  # Network integration
  app_service_subnet_id = module.networking.subnet_ids["appservice"]

  # App Service configuration
  app_service_plan_sku = var.app_service_plan_sku
  enable_application_insights = var.enable_application_insights

  tags = local.common_tags

  depends_on = [module.networking]
}

# Azure Policies Module
module "policies" {
  source = "./modules/policies"

  resource_group_name = azurerm_resource_group.main.name
  environment        = var.environment
  workload           = local.workload
  location_short     = local.location_short[var.location]

  # Policy configuration
  allowed_locations = var.allowed_locations
  required_tags     = keys(local.common_tags)

  tags = local.common_tags
}
