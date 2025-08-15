# Azure Function Deployment Progress Notes

**Date: August 14, 2025**
**Session Focus: Resolving Azure Function App deployment failures in GitHub Actions**

## Executive Summary

We've been working to resolve persistent Azure Function App deployment failures related to 403 Forbidden errors on the SCM endpoint. Our approach has evolved from simple fixes to sophisticated access restriction management, but we're still encountering issues.

## Current Status: **PAUSED** ⏸️

- **Latest Workflow Run**: [#16955004781](https://github.com/stuartshay/azure-policy/actions/runs/16955004781/job/48055176915)
- **Status**: Failed ❌
- **Key Issue**: SCM access rule cleanup is still failing, though the main deployment logic appears to work
- **Branch**: `develop`
- **Last Commit**: `9a0f52eea193676149379072c22c9dfa16f4cb67`

## Key Insights from GitHub Documentation

Based on [GitHub's Azure Private Networking documentation](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/configuring-private-networking-for-hosted-compute-products/about-azure-private-networking-for-github-hosted-runners-in-your-enterprise):

### Critical Discovery 🔍
1. **Dynamic IP Addresses**: GitHub-hosted runners use dynamic, unpredictable IP addresses
2. **VNET Integration**: When using VNET integration, runners deploy NICs into your Azure VNET
3. **Access Restriction Limitations**: Our approach of managing Function App access restrictions based on runner IPs is fundamentally flawed due to IP unpredictability

### Strategic Implications
- The current approach of temporary access restriction management may not be the best solution
- Alternative approaches should be considered (ARM/Bicep deployment, service principal authentication, etc.)

## Technical Progress Made

### 1. Enhanced Workflow Logic ✅
- **File**: `.github/workflows/deploy-function.yml`
- **Improvements Made**:
  - Dynamic runner IP detection
  - Temporary access rule creation with unique names
  - SCM-specific access rules
  - Robust cleanup logic with environment variable tracking
  - Correct handling of `publicNetworkAccess` property (string vs boolean)
  - Removal of unsupported `--no-wait` flags from Azure CLI commands
  - Resilient access restriction cleanup to prevent pipe failures

### 2. Diagnostics and Documentation ✅
- **Created**: `scripts/diagnose-function-access.sh` - Diagnostic script for access issues
- **Created**: `docs/FUNCTION_DEPLOYMENT_TROUBLESHOOTING.md` - Comprehensive troubleshooting guide
- **Enhanced**: Pre-commit hooks and code quality checks

### 3. Azure Configuration Analysis ✅
**Current Function App State**:
```json
{
  "publicNetworkAccessEnabled": true,
  "scmIpSecurityRestrictions": [
    {
      "action": "Allow",
      "ipAddress": "Any",
      "name": "Allow all",
      "priority": 2147483647
    }
  ]
}
```

**Key Finding**: The SCM site already allows all access, so the 403 errors may be caused by something else.

## Current Issues Still Pending 🔄

### 1. SCM Access Rule Management
- **Issue**: SCM-specific access rules fail to remove properly
- **Error**: `No rule found with the specified criteria`
- **Impact**: Cleanup phase fails, though main deployment may succeed

### 2. Deployment Success Unclear
- **Issue**: Hard to determine if the actual function deployment succeeds
- **Problem**: The cleanup failures mask deployment success/failure
- **Need**: Better separation of deployment vs cleanup phases

### 3. Access Restriction Strategy
- **Issue**: Current approach may be architecturally flawed for GitHub runners
- **Problem**: Dynamic IPs make temporary access rules unreliable
- **Need**: Alternative deployment strategy

## Files Modified in This Session

### Primary Files
1. **`.github/workflows/deploy-function.yml`** - Main workflow file (multiple iterations)
2. **`scripts/diagnose-function-access.sh`** - New diagnostic script
3. **`docs/FUNCTION_DEPLOYMENT_TROUBLESHOOTING.md`** - New troubleshooting documentation

### Key Changes Made
- Enhanced error handling and resilience
- Improved cleanup logic
- Correct property handling for Azure resources
- Better logging and diagnostics
- Removal of unsupported CLI flags

## Next Steps (For Future Sessions) 📋

### Immediate Actions (High Priority)
1. **Separate Deployment from Cleanup**: Modify workflow to clearly separate deployment success from cleanup failures
2. **Test Alternate Approaches**:
   - Try deployment without access restrictions
   - Consider using service principal authentication
   - Explore ARM/Bicep template deployment
3. **Validate SCM Access**: Confirm if 403 errors are still occurring or if they're resolved

### Research Tasks (Medium Priority)
1. **Study GitHub Runner Networking**: Understand how GitHub runners interact with Azure VNETs
2. **Evaluate Alternative Deployment Methods**:
   - Azure CLI with different authentication methods
   - Azure DevOps integration
   - Direct ARM template deployment
3. **Review Azure Function App Security**: Best practices for secure deployments

### Long-term Improvements (Low Priority)
1. **Implement Blue-Green Deployment**: Zero-downtime deployment strategy
2. **Enhanced Monitoring**: Better deployment success/failure detection
3. **Automated Rollback**: Rollback mechanism for failed deployments

## Key Learnings & Technical Debt

### What We Learned
- Azure CLI access restriction management is complex and error-prone
- GitHub runners have dynamic IPs that make IP-based restrictions challenging
- SCM endpoints may have different access rules than main Function App endpoints
- Pre-commit hooks and code quality checks are essential for workflow reliability

### Technical Debt Created
- Complex workflow logic that may be over-engineered
- Multiple cleanup strategies that may conflict
- Potential race conditions in access rule management
- Heavy reliance on Azure CLI quirks and timing

## Resource Links

- [GitHub Actions Workflow History](https://github.com/stuartshay/azure-policy/actions)
- [Latest Failed Run](https://github.com/stuartshay/azure-policy/actions/runs/16955004781/job/48055176915)
- [GitHub Azure Private Networking Docs](https://docs.github.com/en/enterprise-cloud@latest/admin/configuring-settings/configuring-private-networking-for-hosted-compute-products/about-azure-private-networking-for-github-hosted-runners-in-your-enterprise)
- [Azure Function App Access Restrictions Docs](https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options)

## Session Summary

**Duration**: ~3 hours
**Commits Made**: 6+
**Workflow Runs**: 5+
**Status**: Issues identified but not fully resolved
**Recommendation**: Consider alternative deployment approach based on GitHub documentation insights

---

*This document serves as a checkpoint for resuming work on Azure Function deployment automation.*
