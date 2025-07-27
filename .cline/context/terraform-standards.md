# Terraform Standards and Best Practices

## Module Structure

### Standard Module Layout

```
modules/{module-name}/
├── main.tf          # Primary resource definitions
├── variables.tf     # Input variables with validation
├── outputs.tf       # Output values
├── versions.tf      # Provider version constraints
├── README.md        # Module documentation
└── examples/        # Usage examples
    └── basic/
        ├── main.tf
        └── variables.tf
```

## Variable Standards

### Variable Naming

- Use snake_case for variable names
- Use descriptive names that indicate purpose
- Group related variables together
- Use consistent prefixes for related variables

### Variable Validation

```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  validation {
    condition     = contains(["East US", "East US 2"], var.location)
    error_message = "Location must be East US or East US 2."
  }
}
```

### Variable Documentation

```hcl
variable "resource_group_name" {
  description = "Name of the Azure Resource Group where resources will be created"
  type        = string

  validation {
    condition     = can(regex("^rg-", var.resource_group_name))
    error_message = "Resource group name must start with 'rg-'."
  }
}
```

## Resource Standards

### Naming Convention Implementation

```hcl
locals {
  # Standard naming components
  workload     = "azurepolicy"
  environment  = var.environment
  location_short = {
    "East US"   = "eastus"
    "East US 2" = "eastus2"
  }

  # Naming patterns
  resource_group_name = "rg-${local.workload}-${local.environment}-${local.location_short[var.location]}"
  vnet_name          = "vnet-${local.workload}-${local.environment}-${local.location_short[var.location]}-001"
  storage_name       = "st${local.workload}${local.environment}001"
}
```

### Required Tags

```hcl
locals {
  common_tags = {
    Environment = var.environment
    CostCenter  = var.cost_center
    Project     = "azurepolicy"
    Owner       = var.owner
    CreatedBy   = "terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Apply to all resources
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.common_tags
}
```

## Provider Configuration

### Version Constraints

```hcl
# versions.tf
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
    # Configuration provided via backend config file
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
  }
}
```

## State Management

### Backend Configuration

```hcl
# backend-config.tf.example
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-prod-eastus"
    storage_account_name = "stterraformstateprod001"
    container_name       = "tfstate"
    key                  = "azurepolicy/dev/terraform.tfstate"
  }
}
```

### State File Organization

- Separate state files per environment
- Use descriptive key names
- Include environment in the path
- Use consistent naming pattern

## Output Standards

### Output Naming

```hcl
# outputs.tf
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}

output "vnet_id" {
  description = "ID of the created virtual network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs"
  value = {
    for subnet in azurerm_subnet.main : subnet.name => subnet.id
  }
}
```

## Data Sources

### Standard Data Source Usage

```hcl
# Get current client configuration
data "azurerm_client_config" "current" {}

# Get existing resource group
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

# Get existing subnet
data "azurerm_subnet" "app_service" {
  name                 = var.app_service_subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}
```

## Security Best Practices

### Managed Identity

```hcl
resource "azurerm_user_assigned_identity" "main" {
  name                = "id-${local.workload}-${local.environment}-${local.location_short[var.location]}-001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = local.common_tags
}
```

### Key Vault Integration

```hcl
resource "azurerm_key_vault" "main" {
  name                = "kv-${local.workload}-${local.environment}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled   = false  # Development only
  soft_delete_retention_days = 7      # Minimum for development

  tags = local.common_tags
}
```

## Error Handling

### Conditional Resource Creation

```hcl
resource "azurerm_application_insights" "main" {
  count = var.enable_application_insights ? 1 : 0

  name                = "appi-${local.workload}-${local.environment}-${local.location_short[var.location]}-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"

  tags = local.common_tags
}
```

### Lifecycle Management

```hcl
resource "azurerm_storage_account" "main" {
  name                     = local.storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  lifecycle {
    prevent_destroy = false  # Allow destroy in development
    ignore_changes = [
      tags["CreatedDate"]    # Ignore timestamp changes
    ]
  }

  tags = local.common_tags
}
```

## Module Documentation Template

```markdown
# Module Name

## Description
Brief description of what this module creates and its purpose.

## Usage
```hcl
module "example" {
  source = "./modules/module-name"

  # Required variables
  resource_group_name = "rg-example-dev-eastus"
  location           = "East US"
  environment        = "dev"

  # Optional variables
  enable_feature = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| azurerm | ~> 3.80 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.80 |

## Resources

| Name | Type |
|------|------|
| azurerm_resource_group.main | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| resource_group_id | ID of the created resource group |

```

## Testing Standards

### Validation Tests
```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Security scan (if using tools like tfsec)
tfsec .

# Plan check
terraform plan -detailed-exitcode
```

### Integration Testing

```hcl
# test/integration_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestTerraformModule(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../examples/basic",
    }

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
    assert.Contains(t, resourceGroupName, "rg-azurepolicy")
}
