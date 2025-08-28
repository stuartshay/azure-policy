# Dependabot Configuration for Terraform Cloud Private Modules

This document outlines the Dependabot configuration that has been set up to work with Terraform Cloud private modules in the azure-policy project.

## Configuration Overview

### Registry Configuration
The `.github/dependabot.yml` file now includes a registry configuration for Terraform Cloud:

```yaml
registries:
  terraform-cloud:
    type: terraform-registry
    url: https://app.terraform.io
    token: ${{secrets.TF_API_TOKEN}}
```

This configuration uses the `TF_API_TOKEN` secret that you've already set up in your GitHub repository.

### Terraform Directories Monitored

Dependabot is now configured to monitor the following Terraform directories for dependency updates:

1. **Main Infrastructure** (`/infrastructure/terraform`) - 09:00 Tuesday
2. **Core Infrastructure** (`/infrastructure/core`) - 09:30 Tuesday
3. **Database Infrastructure** (`/infrastructure/database`) - 10:00 Tuesday
4. **Functions App Infrastructure** (`/infrastructure/functions-app`) - 10:30 Tuesday
5. **GitHub Runner Infrastructure** (`/infrastructure/github-runner`) - 11:00 Tuesday
6. **Monitoring Infrastructure** (`/infrastructure/monitoring`) - 11:30 Tuesday
7. **Policies Infrastructure** (`/infrastructure/policies`) - 12:00 Tuesday
8. **Service Bus Infrastructure** (`/infrastructure/service-bus`) - 12:30 Tuesday
9. **App Service Infrastructure** (`/infrastructure/app-service`) - 13:00 Tuesday

Each entry includes:
- Registry reference to `terraform-cloud` for private module access
- Staggered schedule times to avoid overwhelming the system
- Appropriate labels for categorization
- Assignment to `stuartshay`

## Current Module Sources

Based on the analysis, your project uses a mix of module sources:

### Terraform Cloud Private Modules (Already in use)
```hcl
# Example from infrastructure/app-service/main.tf
module "app_service_plan" {
  source  = "app.terraform.io/azure-policy-cloud/app-service-plan-function/azurerm"
  version = "1.1.34"
  # ...
}
```

### GitHub Sources (Ready for migration)
```hcl
# Example from infrastructure/core/main.tf
module "networking" {
  source = "github.com/stuartshay/azure-policy//infrastructure/terraform/modules/networking?ref=v0.1.0"
  # ...
}
```

### Git Sources
```hcl
# Example from infrastructure/policies/main.tf
module "policies" {
  source = "git::https://github.com/stuartshay/azure-policy.git//infrastructure/terraform/modules/policies?ref=88f58f3"
  # ...
}
```

### Local Sources
```hcl
# Example from infrastructure/terraform/main.tf
module "networking" {
  source = "./modules/networking"
  # ...
}
```

## How Dependabot Will Work

### For Terraform Cloud Private Modules
- Dependabot will authenticate using the `TF_API_TOKEN`
- It will check for new versions of private modules published to your `azure-policy-cloud` organization
- Pull requests will be created automatically when updates are available

### For Provider Updates
- Dependabot will check for updates to Terraform providers (e.g., `hashicorp/azurerm`)
- Version constraints like `~> 4.40` will be respected

### For GitHub/Git Sources
- Dependabot can detect new tags and commits
- It will suggest updates based on semantic versioning

## Required GitHub Secrets

Ensure these secrets are configured in your GitHub repository:

1. **TF_API_TOKEN** ✅ (Already configured)
   - Terraform Cloud API token with access to your organization
   - Used for authenticating with private module registry

2. **TF_CLOUD_ORGANIZATION** ✅ (Already configured)
   - Set to: `azure-policy-cloud`
   - Used by workflows and scripts

## Testing the Configuration

### Manual Trigger
You can manually trigger Dependabot checks:
1. Go to your GitHub repository
2. Navigate to "Insights" > "Dependency graph" > "Dependabot"
3. Click "Check for updates" on any of the Terraform configurations

### Expected Behavior
- Dependabot will run weekly on Tuesdays at the scheduled times
- It will create pull requests for available updates
- PRs will include appropriate labels and assignees
- Updates will respect version constraints in your Terraform files

## Migration Path for Remaining Modules

To fully leverage the Terraform Cloud private module registry:

1. **Publish remaining modules** to Terraform Cloud registry
2. **Update module sources** from GitHub/Git to registry format:
   ```hcl
   # Change from:
   source = "github.com/stuartshay/azure-policy//path/to/module?ref=v1.0.0"

   # To:
   source  = "azure-policy-cloud/module-name/azurerm"
   version = "~> 1.0.0"
   ```

3. **Use semantic versioning** for better dependency management

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify `TF_API_TOKEN` is valid and has proper permissions
   - Check token hasn't expired

2. **Module Not Found**
   - Ensure module is published to the correct organization
   - Verify module name and provider match exactly

3. **No Updates Detected**
   - Check if new versions are actually available
   - Verify version constraints aren't too restrictive

### Logs and Monitoring
- Check Dependabot logs in GitHub repository insights
- Monitor pull request creation patterns
- Review any failed update attempts

## Benefits

With this configuration, you get:

- **Automated dependency management** for all Terraform configurations
- **Security updates** for providers and modules
- **Consistent versioning** across your infrastructure
- **Reduced maintenance overhead** through automation
- **Better visibility** into dependency status

## Next Steps

1. **Monitor initial runs** to ensure configuration works correctly
2. **Review and merge** dependency update PRs as they're created
3. **Consider migrating** remaining GitHub/Git sources to private registry
4. **Adjust schedules** if needed based on your team's workflow

---

**Note**: This configuration supports both your current mixed module sources and your future migration to a fully private module registry setup.
