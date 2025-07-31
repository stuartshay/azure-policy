# Azure Policy - Variables
# This file defines all input variables for Azure Policy management

# Azure Configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

# Resource Group Configuration
variable "resource_group_name" {
  description = "Name of the resource group to apply policies to"
  type        = string
  default     = "rg-azpolicy-dev-eastus"
}

# Policy Configuration
variable "enable_policy_assignments" {
  description = "Enable Azure Policy assignments"
  type        = bool
  default     = true
}
