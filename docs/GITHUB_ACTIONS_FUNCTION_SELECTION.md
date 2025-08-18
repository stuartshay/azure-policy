# GitHub Actions Function Selection Guide

This document explains the updated `deploy-function.yml` GitHub Action workflow that now supports deploying either Basic or Advanced Azure Functions.

## Overview

The GitHub Action has been enhanced to provide flexibility in deploying different types of Azure Functions:

- **Basic Function**: Simple HTTP-triggered functions (hello, health, info endpoints)
- **Advanced Function**: Timer-triggered function with Service Bus integration plus HTTP endpoints

## How to Use

### Manual Deployment (Workflow Dispatch)

1. Go to the **Actions** tab in your GitHub repository
2. Select the **Deploy Azure Function** workflow
3. Click **Run workflow**
4. Choose your function type from the dropdown:
   - `basic` (default) - Deploys the Basic HTTP Functions
   - `advanced` - Deploys the Advanced Timer Function with Service Bus integration
5. Click **Run workflow** to start the deployment

### Automatic Deployment (Push/PR)

The workflow automatically detects which function type to deploy based on file changes:

- Changes to `functions/basic/**` → Deploys Basic Function
- Changes to `functions/advanced/**` → Deploys Advanced Function
- Changes to both directories → Defaults to Basic Function

## Key Features

### Dynamic Configuration

The workflow automatically configures:

- **Function App Names**:
  - Basic: `func-azpolicy-dev-001`
  - Advanced: `func-azpolicy-advanced-dev-001`
- **Package Paths**: Points to the correct function directory
- **Expected Function Counts**: Validates deployment based on function type

### Intelligent Verification

The deployment verification adapts to the function type:

- **Basic Functions**: Expects 3 HTTP functions (HelloWorld, HealthCheck, Info)
- **Advanced Functions**: Expects 5 functions (1 timer + 4 HTTP endpoints)

### Comprehensive Logging

Enhanced logging provides clear visibility into:

- Selected function type
- Target Function App
- Package path
- Deployment progress
- Verification results

## Workflow Structure

### Jobs

1. **build-and-test**: Builds and tests the selected function type
2. **deploy**: Deploys to the appropriate Azure Function App
3. **test-deployment**: (Disabled) Would test endpoints if VNet allows

### Key Steps

1. **Set Function Configuration**: Determines function type and sets environment variables
2. **Build and Test**: Installs dependencies and runs tests for the selected function
3. **Infrastructure Verification**: Checks Azure resources and connectivity
4. **Access Configuration**: Manages network access rules for deployment
5. **Deployment**: Deploys the function package to Azure
6. **Verification**: Validates successful deployment
7. **Cleanup**: Restores original access settings

## Environment Variables

The workflow dynamically sets these variables based on function selection:

- `FUNCTION_TYPE`: "basic" or "advanced"
- `AZURE_FUNCTIONAPP_NAME`: Target Function App name
- `AZURE_FUNCTIONAPP_PACKAGE_PATH`: Source code path
- `FUNCTION_DISPLAY_NAME`: Human-readable function description

## Triggers

The workflow runs on:

- **Push** to master branch (when function files change)
- **Pull Request** to master branch (for validation)
- **Manual trigger** via workflow_dispatch (with function type selection)

## File Monitoring

The workflow monitors these paths for changes:

- `functions/basic/**`
- `functions/advanced/**`
- `.github/workflows/deploy-function.yml`

## Prerequisites

### Azure Resources

Ensure these Azure resources exist:

- Resource Group: `rg-azpolicy-dev-eastus`
- Function Apps:
  - `func-azpolicy-dev-001` (for Basic functions)
  - `func-azpolicy-advanced-dev-001` (for Advanced functions)
- Storage Account: `stfuncazpolicydev001`

### GitHub Secrets

Required secrets:

- `AZURE_CREDENTIALS`: Azure service principal credentials

### Advanced Function Requirements

For Advanced functions, additional configuration may be needed:

- Service Bus connection string
- Appropriate Azure permissions for Service Bus operations

## Troubleshooting

### Common Issues

1. **Function App Not Found**: Ensure the target Function App exists in Azure
2. **Access Denied**: Check that the service principal has appropriate permissions
3. **VNet Restrictions**: The workflow handles VNet-integrated Function Apps automatically
4. **Function Count Mismatch**: Verify all expected functions are deployed

### Debugging

The workflow provides detailed logging for each step. Check the workflow run logs for:

- Function type detection
- Environment variable settings
- Infrastructure verification results
- Deployment progress
- Verification outcomes

## Benefits

### Flexibility
- Deploy either function type from the same workflow
- Manual selection via GitHub UI
- Automatic detection based on file changes

### Maintainability
- Single workflow file to maintain
- Consistent deployment process
- Comprehensive error handling

### Security
- Temporary access rule management
- Automatic cleanup of deployment artifacts
- VNet integration support

### Visibility
- Clear logging and progress tracking
- Function type identification
- Deployment verification

## Future Enhancements

Potential improvements could include:

- Support for additional function types
- Environment-specific deployments (dev/staging/prod)
- Integration with Azure DevOps for VNet-restricted deployments
- Automated rollback capabilities
- Performance testing integration

## Related Documentation

- [Function Deployment Guide](FUNCTION_DEPLOYMENT_GUIDE.md)
- [GitHub Actions Setup](GITHUB_ACTIONS_PRE_COMMIT.md)
- [Azure Functions Documentation](FUNCTIONS.md)
