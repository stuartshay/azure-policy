# Azure Naming Conventions and Standards

## Naming Convention Framework

### Pattern Structure

`{resource-type}-{workload}-{environment}-{region}-{instance}`

### Components

- **resource-type**: Azure resource abbreviation (rg, vnet, nsg, etc.)
- **workload**: Application or service name (azurepolicy)
- **environment**: Environment identifier (dev, staging, prod)
- **region**: Azure region abbreviation (eastus, eastus2)
- **instance**: Sequential number for multiple instances (001, 002)

## Resource Type Abbreviations

### Core Infrastructure

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Resource Group | rg | rg-azurepolicy-dev-eastus |
| Virtual Network | vnet | vnet-azurepolicy-dev-eastus-001 |
| Subnet | snet | snet-default-azurepolicy-dev-eastus-001 |
| Network Security Group | nsg | nsg-azurepolicy-default-dev-eastus-001 |
| Route Table | rt | rt-azurepolicy-dev-eastus-001 |
| Public IP | pip | pip-azurepolicy-dev-eastus-001 |

### Compute Resources

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Virtual Machine | vm | vm-azurepolicy-dev-eastus-001 |
| App Service Plan | asp | asp-azurepolicy-dev-eastus-001 |
| Function App | func | func-azurepolicy-processor-dev-eastus-001 |
| Container Instance | ci | ci-azurepolicy-dev-eastus-001 |

### Storage and Data

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Storage Account | st | stazurepolicydev001 |
| Key Vault | kv | kv-azurepolicy-dev-eastus-001 |
| SQL Database | sqldb | sqldb-azurepolicy-dev-eastus-001 |
| Cosmos DB | cosmos | cosmos-azurepolicy-dev-eastus-001 |

### Monitoring and Security

| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Application Insights | appi | appi-azurepolicy-dev-eastus-001 |
| Log Analytics Workspace | law | law-azurepolicy-dev-eastus-001 |
| User Assigned Identity | id | id-azurepolicy-dev-eastus-001 |

## Environment Naming

### Standard Environments

| Environment | Abbreviation | Purpose |
|-------------|--------------|---------|
| Development | dev | Development and testing |
| Staging | staging | Pre-production testing |
| Production | prod | Live production environment |
| Sandbox | sandbox | Experimental/learning |

### Environment-Specific Considerations

- **Development**: Use cost-effective SKUs, allow resource deletion
- **Staging**: Mirror production configuration, limited access
- **Production**: High availability, backup policies, strict access controls

## Region Abbreviations

### Primary Regions

| Azure Region | Abbreviation | Use Case |
|--------------|--------------|----------|
| East US | eastus | Primary region |
| East US 2 | eastus2 | Secondary/DR region |
| Central US | centralus | Alternative primary |
| West US 2 | westus2 | West coast primary |

## Tagging Strategy

### Required Tags

All resources must include these tags:

```hcl
locals {
  required_tags = {
    Environment   = var.environment
    CostCenter    = var.cost_center
    Project       = "azurepolicy"
    Owner         = var.owner
    CreatedBy     = "terraform"
    CreatedDate   = formatdate("YYYY-MM-DD", timestamp())
  }
}
```

### Optional Tags

Additional tags for enhanced management:

```hcl
locals {
  optional_tags = {
    Application   = "azure-policy-management"
    BusinessUnit  = var.business_unit
    Criticality   = var.criticality_level
    DataClass     = var.data_classification
    Backup        = var.backup_required
    Monitoring    = var.monitoring_level
  }
}
```

### Tag Values Standards

#### Environment Values

- `dev` - Development environment
- `staging` - Staging environment
- `prod` - Production environment
- `sandbox` - Sandbox/experimental

#### Cost Center Values

- `development` - Development team costs
- `operations` - Operations team costs
- `production` - Production workload costs
- `shared` - Shared infrastructure costs

#### Criticality Levels

- `low` - Non-critical, can tolerate downtime
- `medium` - Important but not mission-critical
- `high` - Mission-critical, minimal downtime tolerance
- `critical` - Zero downtime tolerance

## Subnet Design Standards

### Subnet Naming

`snet-{purpose}-{workload}-{environment}-{region}-{instance}`

### Standard Subnet Purposes

| Purpose | CIDR | Description |
|---------|------|-------------|
| default | 10.0.1.0/24 | General purpose subnet |
| appservice | 10.0.2.0/24 | App Service integration |
| functions | 10.0.3.0/24 | Azure Functions |
| privateendpoints | 10.0.4.0/24 | Private endpoints |
| gateway | 10.0.5.0/27 | VPN/ExpressRoute gateway |
| bastion | 10.0.6.0/27 | Azure Bastion |

### IP Address Planning

- **VNet**: 10.0.0.0/16 (65,536 addresses)
- **Subnets**: /24 networks (254 usable addresses each)
- **Reserved**: First 4 and last 1 IP in each subnet
- **Growth**: Plan for 3x current requirements

## Security Group Standards

### NSG Naming

`nsg-{workload}-{subnet-purpose}-{environment}-{region}-{instance}`

### Standard Security Rules

#### Inbound Rules Priority Range

- **100-199**: Allow rules for specific services
- **200-299**: Allow rules for management
- **300-399**: Deny rules for specific threats
- **4000-4096**: Default deny rules

#### Common Inbound Rules

```hcl
# HTTPS from Internet
priority = 100
name     = "Allow-HTTPS-Inbound"
access   = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "443"
source_address_prefix = "Internet"
destination_address_prefix = "*"

# HTTP redirect (if needed)
priority = 110
name     = "Allow-HTTP-Redirect"
access   = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "80"
source_address_prefix = "Internet"
destination_address_prefix = "*"
```

#### Outbound Rules

```hcl
# HTTPS to Internet
priority = 100
name     = "Allow-HTTPS-Outbound"
access   = "Allow"
protocol = "Tcp"
source_port_range = "*"
destination_port_range = "443"
source_address_prefix = "*"
destination_address_prefix = "Internet"

# DNS
priority = 110
name     = "Allow-DNS-Outbound"
access   = "Allow"
protocol = "Udp"
source_port_range = "*"
destination_port_range = "53"
source_address_prefix = "*"
destination_address_prefix = "Internet"
```

## Storage Account Naming

### Special Considerations

- Must be globally unique
- 3-24 characters, lowercase letters and numbers only
- No hyphens or special characters

### Naming Pattern

`st{workload}{environment}{instance}`

Examples:

- `stazurepolicydev001` - Development storage
- `stazurepolicyprod001` - Production storage
- `stazurepolicylog001` - Log storage

## Function App Naming

### Pattern

`func-{workload}-{function-purpose}-{environment}-{region}-{instance}`

### Examples

- `func-azurepolicy-processor-dev-eastus-001`
- `func-azurepolicy-validator-dev-eastus-001`
- `func-azurepolicy-reporter-dev-eastus-001`

## Key Vault Naming

### Pattern

`kv-{workload}-{environment}-{region}-{random-suffix}`

### Considerations

- Must be globally unique
- 3-24 characters
- Include random suffix for uniqueness
- Use for storing secrets, certificates, keys

### Example

```hcl
resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

locals {
  key_vault_name = "kv-azurepolicy-dev-${random_string.kv_suffix.result}"
}
```

## Application Insights Naming

### Pattern

`appi-{workload}-{environment}-{region}-{instance}`

### Example

`appi-azurepolicy-dev-eastus-001`

## Resource Group Organization

### Single Resource Group Strategy

For this project, use a single resource group per environment:

- `rg-azurepolicy-dev-eastus`
- `rg-azurepolicy-staging-eastus`
- `rg-azurepolicy-prod-eastus`

### Benefits

- Simplified management
- Easier cost tracking
- Consistent lifecycle management
- Simplified RBAC

## Validation Rules

### Terraform Validation Examples

```hcl
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string

  validation {
    condition     = can(regex("^rg-azurepolicy-(dev|staging|prod)-eastus2?$", var.resource_group_name))
    error_message = "Resource group name must follow naming convention: rg-azurepolicy-{env}-{region}."
  }
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string

  validation {
    condition     = can(regex("^stazurepolicy(dev|staging|prod)[0-9]{3}$", var.storage_account_name))
    error_message = "Storage account name must follow naming convention: stazurepolicy{env}{instance}."
  }
}
```

## Azure Policy for Naming Enforcement

### Policy Definition Example

```json
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Resources/resourceGroups"
        },
        {
          "not": {
            "field": "name",
            "match": "rg-azurepolicy-*-eastus*"
          }
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  }
}
```

## Best Practices Summary

1. **Consistency**: Use the same pattern across all resources
2. **Uniqueness**: Ensure global uniqueness where required
3. **Readability**: Names should be self-documenting
4. **Length**: Keep within Azure limits while being descriptive
5. **Automation**: Use Terraform locals for consistent naming
6. **Validation**: Implement validation rules in Terraform
7. **Documentation**: Maintain naming standards documentation
8. **Governance**: Use Azure Policy to enforce standards
9. **Flexibility**: Allow for future growth and changes
10. **Compliance**: Follow organizational naming standards
