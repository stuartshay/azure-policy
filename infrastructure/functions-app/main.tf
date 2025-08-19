# Azure Function App Deployment
# This module deploys the actual Function App that depends on the app-service infrastructure
# Requires: app-service module to be deployed first

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40"
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

# Function App - Basic
resource "azurerm_linux_function_app" "basic" {
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
      "WEBSITE_CONTENTSHARE"                     = "${lower(var.workload)}-functions-basic-${var.environment}"
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
    Environment  = var.environment
    Workload     = var.workload
    FunctionType = "basic"
    CostCenter   = var.cost_center
    Owner        = var.owner
    ManagedBy    = "terraform"
    CreatedDate  = timestamp()
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# Data source to get Key Vault information for infrastructure function
data "azurerm_key_vault" "main" {
  count               = var.enable_infrastructure_function ? 1 : 0
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name
}

# Function App - Infrastructure (Secret Rotation)
resource "azurerm_linux_function_app" "infrastructure" {
  count                      = var.enable_infrastructure_function ? 1 : 0
  name                       = "func-${var.workload}-infrastructure-${var.environment}-001"
  resource_group_name        = data.azurerm_resource_group.main.name
  location                   = data.azurerm_resource_group.main.location
  service_plan_id            = data.terraform_remote_state.app_service.outputs.app_service_plan_id
  storage_account_name       = data.azurerm_storage_account.functions.name
  storage_account_access_key = data.azurerm_storage_account.functions.primary_access_key

  # Security configurations
  https_only                    = true
  public_network_access_enabled = false

  # Managed Identity for accessing Azure services
  identity {
    type = "SystemAssigned"
  }

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
      "WEBSITE_CONTENTSHARE"                     = "${lower(var.workload)}-functions-infrastructure-${var.environment}"
      "FUNCTIONS_EXTENSION_VERSION"              = "~4"
      "FUNCTIONS_WORKER_RUNTIME"                 = "python"
      "PYTHON_VERSION"                           = var.python_version

      # Application Insights (if enabled)
      "APPINSIGHTS_INSTRUMENTATIONKEY"        = data.terraform_remote_state.app_service.outputs.application_insights_instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = data.terraform_remote_state.app_service.outputs.application_insights_connection_string

      # EP1 specific settings
      "WEBSITE_MAX_DYNAMIC_APPLICATION_SCALE_OUT" = var.functions_sku_name == "EP1" ? var.maximum_elastic_worker_count : null

      # Infrastructure Function specific settings
      "AZURE_SUBSCRIPTION_ID"      = var.subscription_id
      "SERVICE_BUS_RESOURCE_GROUP" = var.service_bus_resource_group_name
      "SERVICE_BUS_NAMESPACE"      = var.service_bus_namespace_name
      "KEY_VAULT_URI"              = var.enable_infrastructure_function ? data.azurerm_key_vault.main[0].vault_uri : ""
      "ROTATION_ENABLED"           = var.rotation_enabled
      "ROTATE_ADMIN_ACCESS"        = var.rotate_admin_access
    },
    var.infrastructure_function_app_settings
  )

  # Tags
  tags = {
    Environment  = var.environment
    Workload     = var.workload
    FunctionType = "infrastructure"
    CostCenter   = var.cost_center
    Owner        = var.owner
    ManagedBy    = "terraform"
    CreatedDate  = timestamp()
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}

# RBAC Role Assignment - Service Bus Data Owner for Infrastructure Function
resource "azurerm_role_assignment" "infrastructure_servicebus" {
  count                = var.enable_infrastructure_function ? 1 : 0
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${var.service_bus_resource_group_name}/providers/Microsoft.ServiceBus/namespaces/${var.service_bus_namespace_name}"
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_linux_function_app.infrastructure[0].identity[0].principal_id
}

# RBAC Role Assignment - Key Vault Secrets Officer for Infrastructure Function
resource "azurerm_role_assignment" "infrastructure_keyvault" {
  count                = var.enable_infrastructure_function ? 1 : 0
  scope                = data.azurerm_key_vault.main[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_linux_function_app.infrastructure[0].identity[0].principal_id
}

# Function App - Advanced
resource "azurerm_linux_function_app" "advanced" {
  name                       = "func-${var.workload}-advanced-${var.environment}-001"
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
      "WEBSITE_CONTENTSHARE"                     = "${lower(var.workload)}-functions-advanced-${var.environment}"
      "FUNCTIONS_EXTENSION_VERSION"              = "~4"
      "FUNCTIONS_WORKER_RUNTIME"                 = "python"
      "PYTHON_VERSION"                           = var.python_version

      # Application Insights (if enabled)
      "APPINSIGHTS_INSTRUMENTATIONKEY"        = data.terraform_remote_state.app_service.outputs.application_insights_instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = data.terraform_remote_state.app_service.outputs.application_insights_connection_string

      # EP1 specific settings
      "WEBSITE_MAX_DYNAMIC_APPLICATION_SCALE_OUT" = var.functions_sku_name == "EP1" ? var.maximum_elastic_worker_count : null
    },
    var.advanced_function_app_settings
  )

  # Tags
  tags = {
    Environment  = var.environment
    Workload     = var.workload
    FunctionType = "advanced"
    CostCenter   = var.cost_center
    Owner        = var.owner
    ManagedBy    = "terraform"
    CreatedDate  = timestamp()
  }

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"],
    ]
  }
}
