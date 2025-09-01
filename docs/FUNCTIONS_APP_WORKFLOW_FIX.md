# Functions App GitHub Workflow Fix Summary

## Problem Resolution
**Date:** 2025-01-27
**Issue:** GitHub Actions workflow for destroying the Terraform "functions-app" module was failing due to workspace naming mismatches.

## Root Cause Analysis
The issue was a three-way naming inconsistency:
- **Directory:** `infrastructure/functions-app/`
- **Terraform Workspace:** `azure-policy-functions-app`
- **Workflow Module Option:** Some references were using "functions" instead of "functions-app"

## Solution Summary

### 1. Manual Resource Cleanup
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

### 2. Workflow Consistency Fixes

#### terraform-apply.yml
- ✅ Module option "functions-app" already present
- ✅ Added workspace mapping logic: `functions-app → azure-policy-functions-app`

#### terraform-destroy.yml
- ✅ Added module option "functions-app"
- ✅ Added workspace mapping logic: `functions-app → azure-policy-functions-app`
- ✅ Fixed incorrect mapping from "azure-policy-functions" to "azure-policy-functions-app"

### 3. Workspace Mapping Logic
Both workflows now use identical logic:

```yaml
TF_WORKSPACE: ${{ github.event.inputs.module == 'functions-app' && 'azure-policy-functions-app' || format('azure-policy-{0}', github.event.inputs.module) }}
```

## Current State

### ✅ Fixed Components
1. **terraform-apply.yml**: Correctly maps functions-app module to azure-policy-functions-app workspace
2. **terraform-destroy.yml**: Correctly maps functions-app module to azure-policy-functions-app workspace
3. **Resource State**: All function apps manually deleted, clean slate for redeployment
4. **Test Suite**: All 39 tests pass (38 passed, 1 skipped)

### 📁 Workspace Structure
- **Directory**: `infrastructure/functions-app/`
- **Terraform Workspace**: `azure-policy-functions-app`
- **Workflow Module Option**: `functions-app`

## Usage Instructions

### Deploy Functions App
```bash
# Via GitHub Actions
1. Go to Actions → Terraform Apply
2. Select module: "functions-app"
3. Select environment: "dev"
4. Type "apply" to confirm
5. Run workflow
```

### Destroy Functions App
```bash
# Via GitHub Actions
1. Go to Actions → Terraform Destroy
2. Select module: "functions-app"
3. Select environment: "dev"
4. Type "destroy" to confirm
5. Run workflow

# Via Makefile (alternative)
make terraform-functions-app-destroy
```

## Future Maintenance

### Naming Convention
- **Module directories**: Use consistent naming (e.g., `functions-app`)
- **Workspace names**: Use pattern `azure-policy-{module-name}`
- **Workflow options**: Match directory names exactly

### Adding New Modules
When adding new modules, ensure:
1. Directory name matches workflow module option
2. Terraform workspace follows `azure-policy-{module-name}` pattern
3. Add module option to both apply and destroy workflows
4. Update workspace mapping logic if non-standard naming needed

### Testing Changes
Always run the test suite after workflow modifications:
```bash
make test  # or
source functions/basic/.venv/bin/activate && python -m pytest tests/ -v
```

## Verification Commands

### Check Workspace Mapping
```bash
# Verify both workflows have identical TF_WORKSPACE logic
grep -n "TF_WORKSPACE.*functions-app" .github/workflows/terraform-*.yml

# Should show identical lines in both files
```

### Verify Module Options
```bash
# Check both workflows include functions-app option
grep -A 5 -B 5 "functions-app" .github/workflows/terraform-*.yml
```

### Check Resource State
```bash
# Verify no function apps exist
az functionapp list --resource-group rg-azure-policy-dev

# Should return empty list: []
```

## Related Files Modified
- `.github/workflows/terraform-apply.yml`
- `.github/workflows/terraform-destroy.yml`

## Notes
- All Azure Function Apps were manually deleted as part of this fix
- Local Terraform state files were cleared
- Clean slate ready for fresh deployment via corrected workflows
- Both workflows now use consistent naming and mapping logic
