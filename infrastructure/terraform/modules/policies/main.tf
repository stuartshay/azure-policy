# Azure Policy Module
# This module creates Azure Policy definitions and assignments

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.37"
    }
  }
}

# Policy Definition for Resource Group Naming
resource "azurerm_policy_definition" "resource_group_naming" {
  name         = "resource-group-naming-policy"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Resource Group Naming Convention"
  description  = "Enforces naming convention for resource groups"

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Resources/resourceGroups"
    }
    then = {
      effect = "deny"
      details = {
        condition = {
          not = {
            field = "name"
            like  = "rg-*"
          }
        }
      }
    }
  })

  metadata = jsonencode({
    category = "General"
  })
}

# Policy Definition for Storage Naming
resource "azurerm_policy_definition" "storage_naming" {
  name         = "storage-naming-policy"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Storage Account Naming Convention"
  description  = "Enforces naming convention for storage accounts"

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Storage/storageAccounts"
    }
    then = {
      effect = "deny"
      details = {
        condition = {
          not = {
            field = "name"
            like  = "st*"
          }
        }
      }
    }
  })

  metadata = jsonencode({
    category = "Storage"
  })
}

# Policy Assignment for Resource Group Naming
resource "azurerm_resource_group_policy_assignment" "resource_group_naming" {
  count                = var.enable_policy_assignments ? 1 : 0
  name                 = "rg-naming-assignment"
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_definition.resource_group_naming.id
  display_name         = "Resource Group Naming Assignment"
  description          = "Assignment for resource group naming policy"
}

# Policy Assignment for Storage Naming
resource "azurerm_resource_group_policy_assignment" "storage_naming" {
  count                = var.enable_policy_assignments ? 1 : 0
  name                 = "storage-naming-assignment"
  resource_group_id    = var.resource_group_id
  policy_definition_id = azurerm_policy_definition.storage_naming.id
  display_name         = "Storage Naming Assignment"
  description          = "Assignment for storage naming policy"
}
