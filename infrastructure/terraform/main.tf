# Azure Policy Infrastructure - Main Configuration
# This file defines the core infrastructure for the Azure Policy project

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

  # Terraform Cloud backend for state management
  # To set up:
  # 1. Create organization at app.terraform.io
  # 2. Create workspace for each environment (dev, staging, prod)
  # 3. Add TF_API_TOKEN secret to GitHub repository
  cloud {
    organization = "stuartshay-azure-policy" # Change this to your org name

    workspaces {
      tags = ["azure-policy"]
    }
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

# Random suffix for globally unique resources
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Local values for consistent naming and tagging
locals {
  # Naming components
  workload = var.workload
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
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  workload            = local.workload
  location_short      = local.location_short[var.location]

  # Network configuration
  vnet_address_space = var.vnet_address_space
  subnet_config      = var.subnet_config

  # Feature toggles
  enable_network_watcher = var.enable_network_watcher
  enable_flow_logs       = var.enable_flow_logs

  tags = local.common_tags
}

# App Service Module
module "app_service" {
  source = "./modules/app-service"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  workload            = local.workload

  tags = local.common_tags

  depends_on = [module.networking]
}

# Azure Policies Module
module "policies" {
  source = "./modules/policies"

  resource_group_id         = azurerm_resource_group.main.id
  enable_policy_assignments = var.enable_policy_assignments

  depends_on = [azurerm_resource_group.main]
}
