# Azure Function App Deployment Troubleshooting Guide

## Issue: GitHub Actions Deployment Fails with 403 Forbidden

### Problem Description
GitHub Actions workflow fails when trying to deploy to Azure Function App with error:
- SCM site returns 403 Forbidden
- "GitHub Actions cannot deploy to this Function App"
- Access restrictions prevent deployment

### Root Cause Analysis
The issue occurs when Azure Function Apps have network security restrictions that block external access to the SCM (Source Control Manager) endpoint used for deployments.

### Quick Diagnosis
Run the diagnosis script to check your Function App status:
```bash
./scripts/diagnose-function-access.sh
```

### Solution Options

#### Option 1: Use Updated Workflow with Better Access Management ✅ RECOMMENDED
The workflow has been updated to handle access restrictions more intelligently:

1. **Automatic IP Detection**: Gets the GitHub Actions runner IP
2. **Temporary Access Rules**: Creates specific access rules for deployment
3. **SCM Site Testing**: Validates connectivity before attempting deployment
4. **Cleanup**: Removes temporary rules after deployment

**Key Improvements:**
- Uses higher priority rules (priority 50 vs 100)
- Adds rules for both main site and SCM site
- Better timing and retry logic
- Proper environment variable tracking for cleanup

#### Option 2: Use Self-Hosted Runner in VNet 🔒 MOST SECURE
For maximum security, use the self-hosted runner workflow:

1. **Deploy a self-hosted GitHub Actions runner within your Azure VNet**
2. **Use the `deploy-function-self-hosted.yml` workflow**
3. **No need to modify Function App access restrictions**

**Benefits:**
- No temporary exposure of Function App
- Consistent with VNet security model
- No complex access rule management

#### Option 3: Temporary Access Fix 🚨 EMERGENCY USE ONLY
For immediate deployment needs:

```bash
# Temporarily allow all access
./scripts/diagnose-function-access.sh --fix-access

# Deploy your function (run GitHub Actions workflow)

# Restore security
./scripts/diagnose-function-access.sh --restore-security
```

### Verification Steps

#### 1. Check Function App Configuration
```bash
az functionapp show \
  --resource-group rg-azpolicy-dev-eastus \
  --name func-azpolicy-dev-001 \
  --query "{name:name, state:state, publicNetworkAccess:publicNetworkAccessEnabled}"
```

#### 2. Test SCM Connectivity
```bash
curl -I https://func-azpolicy-dev-001.scm.azurewebsites.net
```

#### 3. Review Access Restrictions
```bash
az functionapp config access-restriction show \
  --resource-group rg-azpolicy-dev-eastus \
  --name func-azpolicy-dev-001
```

### Understanding HTTP Status Codes

| Status Code | Meaning | Action Required |
|------------|---------|-----------------|
| 200 | OK - Site accessible | ✅ Deployment should work |
| 401 | Unauthorized - Authentication required | ✅ Normal for SCM endpoint |
| 403 | Forbidden - Access blocked | ❌ Need to fix access restrictions |
| 000 | Timeout/Network error | ❌ Check VNet/firewall settings |

### Best Practices for Production

#### 1. Network Security
- Use VNet integration for Function Apps
- Deploy self-hosted runners within the VNet
- Avoid temporary access rule changes in production

#### 2. Access Management
- Use least privilege access principles
- Clean up temporary GitHub Actions rules regularly
- Monitor access logs for suspicious activity

#### 3. Deployment Strategy
- Use separate environments (dev/staging/prod)
- Test deployments in development first
- Implement proper CI/CD governance

### Monitoring and Maintenance

#### Clean Up Old GitHub Actions Rules
```bash
./scripts/diagnose-function-access.sh --clean-github-rules
```

#### Regular Security Audits
1. Review Function App access restrictions monthly
2. Validate VNet integration settings
3. Check for unnecessary public network access

### Advanced Troubleshooting

#### Enable Detailed Logging
Add to your workflow for debugging:
```yaml
- name: Debug Network Access
  run: |
    echo "Current IP: $(curl -s https://api.ipify.org)"
    nslookup ${{ env.AZURE_FUNCTIONAPP_NAME }}.scm.azurewebsites.net
    az functionapp config access-restriction list \
      --resource-group rg-azpolicy-dev-eastus \
      --name ${{ env.AZURE_FUNCTIONAPP_NAME }}
```

#### Test from Different Networks
The access restrictions may behave differently from:
- GitHub Actions runners (various IP ranges)
- Your local development machine
- Azure VNet internal networks

### Getting Help

If issues persist:
1. Run the diagnosis script with full output
2. Check the GitHub Actions logs for specific error messages
3. Review Azure Function App logs in the Azure Portal
4. Consider using Azure DevOps for VNet-integrated deployments

### Related Resources
- [Azure Function App Network Security](https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options)
- [GitHub Actions Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Azure VNet Integration](https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options#virtual-network-integration)
