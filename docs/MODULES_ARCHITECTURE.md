# Terraform Modules Architecture

## Overview
This document describes the module architecture for the Azure Policy infrastructure project when using Terraform Cloud.

## Module Structure

### Shared Modules Location
All shared Terraform modules are stored in a single location:
```
infrastructure/terraform/modules/
├── app-service/     # App Service module
├── networking/      # Networking module (VNet, Subnets, NSGs)
└── policies/        # Azure Policy definitions and assignments
```

### Workspace Structure
Each workspace references the shared modules:
```
infrastructure/
├── core/            # Core infrastructure workspace
├── functions/       # Azure Functions workspace
└── policies/        # Azure Policies workspace
```

## Module Sourcing Strategy

### For Terraform Cloud
When using Terraform Cloud, modules are referenced using Git-based sources:

```hcl
module "networking" {
  source = "git::https://github.com/stuartshay/azure-policy.git//infrastructure/terraform/modules/networking?ref=develop"
  # ... module configuration
}
```

### Benefits of Git-Based Module Sources
1. **No Duplication**: Modules exist in one place only
2. **Version Control**: Can reference specific branches, tags, or commits
3. **Terraform Cloud Compatible**: Works seamlessly with Terraform Cloud
4. **Team Collaboration**: Everyone uses the same module versions
5. **CI/CD Friendly**: Works in automated pipelines

### Module Versioning Best Practices

#### Development
```hcl
# Reference develop branch for active development
source = "git::https://github.com/stuartshay/azure-policy.git//infrastructure/terraform/modules/networking?ref=develop"
```

#### Staging/Production
```hcl
# Reference specific version tags for stability
source = "git::https://github.com/stuartshay/azure-policy.git//infrastructure/terraform/modules/networking?ref=v1.0.0"
```

## Module Dependencies

### Core Workspace
- Uses: `networking` module
- Creates: Resource groups, VNets, subnets, NSGs
- No dependencies on other workspaces

### Functions Workspace
- Depends on: Core workspace (for resource group)
- Creates: Function Apps, Storage Accounts, App Service Plans
- No module dependencies (resources defined inline)

### Policies Workspace
- Uses: `policies` module
- Depends on: Core workspace (for resource group)
- Creates: Policy definitions and assignments

## Migration from Local Modules

If you previously used local module paths (e.g., `./modules/networking`), follow these steps to migrate:

1. **Remove duplicate module directories** from workspace folders
2. **Update module sources** to use Git-based references
3. **Run `terraform init`** to download modules from Git
4. **Verify with `terraform plan`** that no changes are detected

## Troubleshooting

### Module Not Found
If Terraform can't find a module:
- Verify the Git repository is accessible
- Check the path after `//` matches the actual module location
- Ensure the branch/tag exists

### Module Changes Not Reflected
If module changes aren't being picked up:
- Run `terraform init -upgrade` to fetch the latest module version
- Clear the `.terraform` directory and re-initialize
- Verify you're referencing the correct branch/tag

## Security Considerations

1. **Public vs Private Repos**:
   - Public repos can be accessed without authentication
   - Private repos require Git credentials or SSH keys

2. **Version Pinning**:
   - Always use specific tags for production
   - Avoid using `main` or `develop` branches in production

3. **Module Review**:
   - Review module changes before updating references
   - Use pull requests for module modifications

## Future Improvements

1. **Semantic Versioning**: Implement proper semantic versioning for modules
2. **Module Registry**: Consider using Terraform Cloud's private module registry
3. **Automated Testing**: Add automated tests for module changes
4. **Documentation**: Generate module documentation automatically
