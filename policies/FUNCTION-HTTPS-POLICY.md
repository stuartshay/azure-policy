# Azure Function App HTTPS-Only Policy

## Overview
This custom Azure Policy ensures that all Azure Function Apps are configured to accept only HTTPS traffic, blocking HTTP connections for enhanced security.

## Policy Details

- **Name**: `enforce-function-app-https-only`
- **Display Name**: Function Apps should only be accessible over HTTPS
- **Category**: App Service
- **Mode**: Indexed
- **Version**: 1.0.0

## What it Does

This policy targets Azure Function Apps (`Microsoft.Web/sites` with `kind` matching `functionapp*`) and ensures that:

1. The `httpsOnly` property is set to `true`
2. Prevents creation or update of Function Apps that allow HTTP traffic
3. Applies to all Function App types (consumption, premium, dedicated)

## Policy Rule Logic

The policy triggers when:
- Resource type is `Microsoft.Web/sites`
- Resource kind matches `functionapp*` (covers all Function App variants)
- Either:
  - The `httpsOnly` property doesn't exist, OR
  - The `httpsOnly` property is set to `false`

## Available Effects

- **Deny**: Hardcoded effect that blocks creation/update of non-compliant Function Apps
- This policy does not use parameters - the Deny effect is always enforced

## Security Benefits

✅ **Data Protection**: Encrypts all data in transit  
✅ **Attack Prevention**: Prevents man-in-the-middle attacks  
✅ **API Security**: Ensures secure function invocations  
✅ **Compliance**: Meets security compliance requirements  
✅ **Zero Trust**: Enforces secure-by-default principle  

## Files Included

1. **`enforce-function-app-https-only.json`** - The policy definition
2. **`enforce-function-app-https-only-parameters.json`** - Default parameters
3. **`deploy-function-https-policy.ps1`** - PowerShell deployment script

## Deployment

### Option 1: Using the PowerShell Script (Recommended)

```powershell
# Deploy to subscription with hardcoded Deny effect
./deploy-function-https-policy.ps1

# Deploy to specific resource group
./deploy-function-https-policy.ps1 -ResourceGroup "AzurePolicy"
```

### Option 2: Using Azure CLI

```bash
# Create policy definition
az policy definition create \
    --name "enforce-function-app-https-only" \
    --display-name "Function Apps should only be accessible over HTTPS" \
    --description "This policy ensures that Azure Function Apps are only accessible over HTTPS" \
    --rules "./policies/enforce-function-app-https-only.json" \
    --mode "Indexed"

# Create policy assignment (no parameters needed)
az policy assignment create \
    --name "assign-function-https-only" \
    --display-name "Assign Function App HTTPS-Only Policy" \
    --policy "enforce-function-app-https-only"
```

### Option 3: Using the existing script framework

Add this as option 6 to `07-create-custom-policy.sh`:

```bash
6)
    POLICY_NAME="enforce-function-app-https-only"
    DISPLAY_NAME="Function Apps should only be accessible over HTTPS"
    DESCRIPTION="This policy ensures that Azure Function Apps are only accessible over HTTPS"
    
    cp "../policies/enforce-function-app-https-only.json" "$POLICIES_DIR/${POLICY_NAME}.json"
    ;;
```

## Testing the Policy

### 1. Test Non-Compliant Resource (Should be blocked with Deny effect)

```bash
# This should fail if policy effect is "Deny"
az functionapp create \
    --name "test-http-function" \
    --resource-group "AzurePolicy" \
    --storage-account "mystorageaccount" \
    --consumption-plan-location "eastus"
```

### 2. Test Compliant Resource (Should succeed)

```bash
# Create Function App
az functionapp create \
    --name "test-https-function" \
    --resource-group "AzurePolicy" \
    --storage-account "mystorageaccount" \
    --consumption-plan-location "eastus"

# Enable HTTPS-only (makes it compliant)
az functionapp update \
    --name "test-https-function" \
    --resource-group "AzurePolicy" \
    --set httpsOnly=true
```

## Compliance Monitoring

Check compliance status:

```powershell
# View compliance for specific resource group
./05-compliance-report.ps1 -ResourceGroup "AzurePolicy"

# View subscription-wide compliance
./05-compliance-report.ps1
```

## Related Policies

This policy complements other App Service security policies:
- App Service apps should use the latest TLS version
- App Service apps should have Client Certificates enabled
- App Service apps should use managed identity

## Troubleshooting

### Common Issues

1. **Permission Errors**: Ensure you have `Policy Contributor` role
2. **Assignment Conflicts**: Check for existing conflicting policies
3. **Scope Issues**: Verify resource group exists and is accessible

### Verification Commands

```bash
# Check if policy exists
az policy definition show --name "enforce-function-app-https-only"

# List assignments
az policy assignment list --query "[?displayName=='Assign Function App HTTPS-Only Policy']"

# View compliance state
az policy state list --filter "policyDefinitionName eq 'enforce-function-app-https-only'"
```

## References

- [Azure Policy definition structure](https://docs.microsoft.com/azure/governance/policy/concepts/definition-structure)
- [Function App HTTPS configuration](https://docs.microsoft.com/azure/azure-functions/security-concepts)
- [App Service security best practices](https://docs.microsoft.com/azure/app-service/security-recommendations)
