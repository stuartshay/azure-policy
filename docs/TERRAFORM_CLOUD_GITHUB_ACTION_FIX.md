# Terraform Cloud GitHub Action Fix

## Problem Summary

The Terraform Apply GitHub Action was failing because it was not properly configured to use Terraform Cloud backend, causing it to attempt using local state instead of the remote state managed by Terraform Cloud.

## Root Cause

The GitHub Action workflow had the following issues:

1. **Incorrect environment variable**: The workflow was setting `TF_API_TOKEN` but Terraform Cloud requires `TF_TOKEN_app_terraform_io`
2. **Missing backend verification**: No checks to ensure Terraform Cloud backend was being used
3. **No local state prevention**: No safeguards to prevent local state file creation
4. **Missing outputs**: The app-service module was missing the `app_service_plan_name` output that the workflow expected

## Changes Made

### 1. GitHub Action Workflow (.github/workflows/terraform-apply.yml)

#### Environment Variables
```yaml
# BEFORE
env:
  TF_API_TOKEN: ${{ secrets.TF_API_TOKEN }}
  TF_WORKSPACE: ${{ ... }}

# AFTER
env:
  # Terraform Cloud authentication - this is the key fix
  TF_TOKEN_app_terraform_io: ${{ secrets.TF_API_TOKEN }}
```

#### Added Verification Steps
- **Terraform Cloud Configuration Verification**: Checks that the module has proper cloud backend configuration
- **Token Verification**: Ensures the Terraform Cloud token is available
- **Local State Prevention**: Actively checks for and fails if local state files are created
- **Backend Verification**: Confirms remote state is being used

#### Enhanced Logging
- Added detailed logging for debugging
- Clear success/failure indicators
- Better error messages for troubleshooting

### 2. App Service Module Outputs (infrastructure/app-service/outputs.tf)

Added missing output that the workflow expects:
```hcl
output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = module.app_service_plan.app_service_plan_name
}
```

## How It Works Now

### Authentication Flow
1. GitHub Action sets `TF_TOKEN_app_terraform_io` from the secret `TF_API_TOKEN`
2. Terraform automatically uses this token to authenticate with Terraform Cloud
3. The workflow verifies the token is available before proceeding

### Backend Verification
1. Checks that `main.tf` contains `cloud {` configuration
2. Verifies no local state files are created during operations
3. Confirms remote state is being used

### Module Compatibility
- The workflow now properly handles different module types (core, app-service, functions-app, etc.)
- Correctly retrieves outputs based on module type
- Provides appropriate error handling for missing outputs

## Testing the Fix

### Prerequisites
1. Ensure `TF_API_TOKEN` secret is set in GitHub repository
2. Verify Terraform Cloud organization and workspaces are configured
3. Confirm Azure credentials are properly set

### Test Steps
1. Navigate to GitHub Actions in the repository
2. Run the "Terraform Apply" workflow
3. Select module: `app-service`
4. Select environment: `dev`
5. Type `apply` to confirm
6. Monitor the workflow logs for:
   - ✅ Terraform Cloud backend configuration found
   - ✅ Terraform Cloud token is configured
   - ✅ No local state files found
   - ✅ Using Terraform Cloud remote state

### Expected Behavior
- **Success**: Workflow completes without creating local state files
- **Proper Authentication**: Token verification passes
- **Remote State**: All operations use Terraform Cloud backend
- **Clean Outputs**: Module outputs are properly retrieved

## Verification Commands

To verify the fix is working locally (using the Makefile approach):

```bash
# Test app-service module
cd infrastructure/app-service
make login    # Verify Terraform Cloud authentication
make init     # Initialize with cloud backend
make plan     # Plan changes (should use remote state)
```

## Key Benefits

1. **No Local State**: Eliminates the risk of local state file conflicts
2. **Consistent Backend**: All operations use Terraform Cloud consistently
3. **Better Debugging**: Enhanced logging for troubleshooting
4. **Proper Authentication**: Correct token handling for Terraform Cloud
5. **Module Compatibility**: Works with all infrastructure modules

## Troubleshooting

### Common Issues

1. **Token Not Found**
   - Verify `TF_API_TOKEN` secret is set in GitHub repository
   - Check token has proper permissions in Terraform Cloud

2. **Backend Configuration Missing**
   - Ensure module's `main.tf` has proper `cloud {}` block
   - Verify organization and workspace names are correct

3. **Local State Files Created**
   - This indicates backend configuration is not working
   - Check token authentication and workspace permissions

### Debug Steps
1. Check workflow logs for verification steps
2. Verify Terraform Cloud workspace exists and is accessible
3. Confirm Azure credentials are properly configured
4. Test locally using Makefile commands

## Related Files

- `.github/workflows/terraform-apply.yml` - Main workflow file
- `infrastructure/app-service/main.tf` - Backend configuration
- `infrastructure/app-service/outputs.tf` - Module outputs
- `Makefile` - Local development commands
- `infrastructure/app-service/Makefile` - Module-specific commands

## Next Steps

1. Test the workflow with the app-service module
2. Verify other modules work correctly
3. Consider applying similar fixes to terraform-destroy workflow if needed
4. Monitor for any remaining authentication issues
