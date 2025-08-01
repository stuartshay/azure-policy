# Azure Policy Management
# This file defines Azure Policy definitions and assignments

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
      name = "azure-policy-policies"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Data source to get the resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Azure Policies Module
module "policies" {
  source = "../terraform/modules/policies"

  resource_group_id         = data.azurerm_resource_group.main.id
  enable_policy_assignments = var.enable_policy_assignments
}
