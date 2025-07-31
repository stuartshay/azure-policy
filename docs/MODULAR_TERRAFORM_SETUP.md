# Modular Terraform Setup Documentation

## Overview

The Azure Policy project has been successfully restructured from a monolithic Terraform configuration into three separate, decoupled workflows:

1. **Infrastructure** - Core Azure resources (networking, resource groups, storage)
2. **Policies** - Azure policy definitions and assignments
3. **Functions** - Azure Functions applications

## Workspace Structure

### Directory Layout
```
infrastructure/
├── terraform/           # Original monolithic configuration (preserved)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
├── infrastructure/      # NEW: Core infrastructure workflow
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── policies/           # NEW: Policy workflow
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── functions/          # NEW: Functions workflow
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

### Terraform Cloud Workspaces

The following workspaces have been created in the `azure-policy-cloud` organization:

| Workspace Name | Purpose | Working Directory |
|----------------|---------|-------------------|
| `azure-policy-infrastructure` | Core infrastructure deployment | `infrastructure/infrastructure` |
| `azure-policy-policies` | Policy definitions and assignments | `infrastructure/policies` |
| `azure-policy-functions` | Azure Functions deployment | `infrastructure/functions` |

## Configuration Details

### Infrastructure Workflow
- **Purpose**: Deploys core Azure resources
- **Resources**: Resource Groups, Virtual Networks, Storage Accounts, Key Vault
- **Dependencies**: None (base layer)
- **State**: Remote state in Terraform Cloud

### Policies Workflow
- **Purpose**: Manages Azure Policy definitions and assignments
- **Resources**: Policy definitions, policy assignments, policy set definitions
- **Dependencies**: May reference infrastructure outputs via data sources
- **State**: Remote state in Terraform Cloud (separate from infrastructure)

### Functions Workflow
- **Purpose**: Deploys Azure Functions applications
- **Resources**: Function Apps, App Service Plans, Application Insights
- **Dependencies**: References infrastructure outputs for networking and storage
- **State**: Remote state in Terraform Cloud (separate from other workflows)

## Benefits of Modular Approach

1. **Independent Deployments**: Each workflow can be deployed, updated, or destroyed independently
2. **Reduced Blast Radius**: Issues in one workflow don't affect others
3. **Faster Operations**: Smaller state files mean faster planning and applying
4. **Team Collaboration**: Different teams can own different workflows
5. **Easier Troubleshooting**: Isolated configurations are easier to debug
6. **Selective Destruction**: Can destroy policies or functions without affecting core infrastructure

## Usage Examples

### Deploy Infrastructure Only
```bash
cd infrastructure/infrastructure
terraform plan
terraform apply
```

### Deploy Policies Only
```bash
cd infrastructure/policies
terraform plan
terraform apply
```

### Deploy Functions Only
```bash
cd infrastructure/functions
terraform plan
terraform apply
```

## State Management

Each workflow maintains its own remote state in Terraform Cloud:
- No shared state between workflows
- Cross-workflow dependencies handled via data sources
- Each workspace has independent versioning and locking

## Next Steps

1. **Test Each Workflow**: Validate that each can be deployed independently
2. **Update CI/CD**: Modify GitHub Actions to handle multiple workflows
3. **Add Data Sources**: Configure cross-workflow references where needed
4. **Documentation**: Update deployment guides for the new structure

## Migration Notes

- Original monolithic configuration preserved in `infrastructure/terraform/`
- New modular configurations are independent and don't interfere with existing deployments
- Existing state in original workspace remains intact
- Can gradually migrate from monolithic to modular approach
