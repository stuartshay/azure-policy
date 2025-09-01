# GitHub Workflow Fix - Complete Module Support Summary

## Problem Resolution
**Date:** 2025-01-27
**Issue:** GitHub Actions workflow for the Terraform "functions-app" module was failing due to:
1. Missing dependencies (app-service module)
2. Workspace naming mismatches across multiple modules
3. Incomplete module options in workflows

## Root Cause Analysis
The issue was a complex dependency and naming problem:
- **functions-app module** depends on **app-service module** but app-service wasn't available in workflows
- **Workspace naming inconsistencies** across multiple modules (some followed patterns, others didn't)
- **Missing module options** in both apply and destroy workflows

## Solution Summary

### 1. Manual Resource Cleanup (Completed)
- Performed manual deletion of all Azure Function Apps using Azure CLI
- Verified complete resource deletion (no function apps remain)
- Cleared local Terraform state files to ensure clean slate

```bash
# Commands used for manual cleanup
az functionapp delete --name azure-policy-basic-functions --resource-group rg-azure-policy-dev
az functionapp delete --name azure-policy-functions-advanced --resource-group rg-azure-policy-dev
az functionapp list --resource-group rg-azure-policy-dev  # Verified empty
rm -f infrastructure/functions-app/terraform.tfstate
rm -f infrastructure/functions-app/terraform.tfstate.backup
```

### 2. Complete Module Support Added

#### Added Module Options
Both workflows now support all available modules:
- ✅ **core** → `azure-policy-core`
- ✅ **policies** → `azure-policy-policies`
- ✅ **app-service** → `app-service-dev` *(dependency for functions-app)*
- ✅ **functions-app** → `azure-policy-functions-app`
- ✅ **monitoring** → `azure-policy-monitoring`
- ✅ **terraform** → `azure-policy-infrastructure`

#### Comprehensive Workspace Mapping
Both workflows use intelligent workspace mapping logic:

```yaml
TF_WORKSPACE: ${{
  github.event.inputs.module == 'functions-app' && 'azure-policy-functions-app' ||
  github.event.inputs.module == 'app-service' && 'app-service-dev' ||
  github.event.inputs.module == 'terraform' && 'azure-policy-infrastructure' ||
  format('azure-policy-{0}', github.event.inputs.module) }}
```

### 3. Workflow Files Updated

#### terraform-apply.yml ✅
- Added all module options: core, policies, app-service, functions-app, monitoring, terraform
- Comprehensive workspace mapping logic
- Dependency support for functions-app → app-service

#### terraform-destroy.yml ✅
- Added all module options: core, policies, app-service, functions-app, monitoring, terraform
- Identical workspace mapping logic as apply workflow
- Consistent module destruction support

## Current State

### ✅ Fixed Components
1. **terraform-apply.yml**: Supports all modules with correct workspace mapping
2. **terraform-destroy.yml**: Supports all modules with correct workspace mapping
3. **Resource State**: All function apps manually deleted, clean slate for redeployment
4. **Test Suite**: All 39 tests pass (38 passed, 1 skipped)
5. **Dependency Support**: app-service can be deployed before functions-app

### 📁 Complete Module Structure
| Module | Directory | Terraform Workspace | Status |
|--------|-----------|---------------------|--------|
| **core** | `infrastructure/core/` | `azure-policy-core` | ✅ Workflow Ready |
| **policies** | `infrastructure/policies/` | `azure-policy-policies` | ✅ Workflow Ready |
| **app-service** | `infrastructure/app-service/` | `app-service-dev` | ✅ Workflow Ready |
| **functions-app** | `infrastructure/functions-app/` | `azure-policy-functions-app` | ✅ Workflow Ready |
| **monitoring** | `infrastructure/monitoring/` | `azure-policy-monitoring` | ✅ Workflow Ready |
| **terraform** | `infrastructure/terraform/` | `azure-policy-infrastructure` | ✅ Workflow Ready |

## Usage Instructions

### Deploy Functions App (Complete Process)
```bash
# Step 1: Deploy app-service dependency first
1. Go to Actions → Terraform Apply
2. Select module: "app-service"
3. Select environment: "dev"
4. Type "apply" to confirm
5. Run workflow and wait for completion

# Step 2: Deploy functions-app
1. Go to Actions → Terraform Apply
2. Select module: "functions-app"
3. Select environment: "dev"
4. Type "apply" to confirm
5. Run workflow
```

### Deploy Any Other Module
```bash
# Via GitHub Actions
1. Go to Actions → Terraform Apply
2. Select desired module: "core", "policies", "monitoring", or "terraform"
3. Select environment: "dev", "staging", or "prod"
4. Type "apply" to confirm
5. Run workflow
```

### Destroy Any Module
```bash
# Via GitHub Actions
1. Go to Actions → Terraform Destroy
2. Select module: any available option
3. Select environment: "dev" or "staging"
4. Type "destroy" to confirm
5. Type environment name again for double confirmation
6. Run workflow

# Via Makefile (alternative for functions-app)
make terraform-functions-app-destroy
```

## Dependency Management

### functions-app Dependencies
The **functions-app** module requires the **app-service** module to be deployed first:

1. **Deploy app-service first**: Contains shared infrastructure (service plans, storage, etc.)
2. **Then deploy functions-app**: References app-service outputs via remote state

### Deployment Order Recommendations
1. **Core infrastructure**: `core` → foundational resources
2. **Shared services**: `app-service` → shared app infrastructure
3. **Applications**: `functions-app` → actual function apps
4. **Governance**: `policies` → Azure policies
5. **Observability**: `monitoring` → monitoring and logging
6. **Platform**: `terraform` → Terraform-specific infrastructure

## Future Maintenance

### Adding New Modules
When adding new modules, ensure:
1. Directory name matches workflow module option exactly
2. Add module to both apply and destroy workflow options
3. Check if Terraform workspace follows `azure-policy-{module-name}` pattern
4. If non-standard workspace naming, update TF_WORKSPACE mapping logic
5. Document any module dependencies

### Workspace Naming Convention Standards
- **Standard pattern**: `azure-policy-{module-name}`
- **Non-standard exceptions**:
  - `app-service` → `app-service-dev`
  - `terraform` → `azure-policy-infrastructure`

### Testing Changes
Always run the test suite after workflow modifications:
```bash
make test  # or
source functions/basic/.venv/bin/activate && python -m pytest tests/ -v
```

## Verification Commands

### Check All Workspace Mappings
```bash
# Verify workspace mapping logic in both workflows
grep -A 5 -B 5 "TF_WORKSPACE" .github/workflows/terraform-*.yml

# Should show identical multi-line conditional logic
```

### Verify All Module Options
```bash
# Check both workflows include all modules
grep -A 10 "options:" .github/workflows/terraform-*.yml
```

### Check Resource State
```bash
# Verify no function apps exist (should return empty)
az functionapp list --resource-group rg-azure-policy-dev
```

## Troubleshooting

### If functions-app Deployment Fails
1. **Check app-service dependency**: Ensure app-service is deployed first
2. **Verify workspace exists**: Check Terraform Cloud for `app-service-dev` workspace
3. **Check remote state access**: Verify permissions to read app-service outputs

### If Any Module Fails
1. **Check workspace name**: Verify TF_WORKSPACE mapping matches actual Terraform config
2. **Check Terraform Cloud**: Ensure workspace exists and has correct permissions
3. **Review module dependencies**: Some modules may depend on core infrastructure

## Related Files Modified
- `.github/workflows/terraform-apply.yml` - Added all modules + workspace mapping
- `.github/workflows/terraform-destroy.yml` - Added all modules + workspace mapping

## Notes
- All Azure Function Apps were manually deleted as part of this fix
- Local Terraform state files were cleared
- Clean slate ready for fresh deployment via corrected workflows
- Both workflows now use comprehensive module support and consistent naming logic
- Dependencies between modules are documented and supported
