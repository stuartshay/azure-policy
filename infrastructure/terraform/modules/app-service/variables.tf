variable "workload" {
  description = "The workload name"
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region"
  type        = string
}

variable "sku_name" {
  description = "The SKU name for the App Service Plan"
  type        = string
  default     = "B1"
}

variable "always_on" {
  description = "Should the app be loaded at all times"
  type        = bool
  default     = false
}

variable "python_version" {
  description = "The Python version"
  type        = string
  default     = "3.11"
}

variable "app_settings" {
  description = "App settings for the web app"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
