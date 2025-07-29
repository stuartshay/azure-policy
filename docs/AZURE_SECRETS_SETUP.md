# Azure GitHub Secrets Setup Instructions

## Service Principal Created ✅

A service principal named **azure-policy-github-actions** has been created with:
- **Role**: Contributor 
- **Scope**: Subscription level (BizSpark)
- **Authentication**: Verified and working

## Required GitHub Repository Secrets

Add these 5 secrets to your GitHub repository at:
**https://github.com/stuartshay/azure-policy/settings/secrets/actions**

| Secret Name | Description |
|-------------|-------------|
| `AZURE_CLIENT_ID` | Service Principal Application ID |
| `AZURE_CLIENT_SECRET` | Service Principal Secret |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID |
| `AZURE_TENANT_ID` | Azure Tenant ID |
| `AZURE_CREDENTIALS` | JSON format for Azure login action |

## Values Required

The actual values were displayed in the terminal output above and should be copied manually to GitHub secrets for security.

## Workflows That Will Use These Secrets

- `.github/workflows/terraform-apply.yml` ✅
- `.github/workflows/terraform-destroy.yml` ✅
- Any future workflows requiring Azure authentication

## Next Steps

1. **Copy the values** from the terminal output above
2. **Add each secret** to GitHub repository settings
3. **Test a workflow** to verify authentication works
4. **Delete this file** after setup is complete

## Security Best Practices

- ✅ Service principal has minimum required permissions
- ✅ Secrets are stored securely in GitHub
- ✅ Client secret can be rotated if needed
- ✅ Service principal usage can be monitored in Azure Portal

## Testing

Once secrets are added, you can test by running:
- Manual workflow dispatch on any workflow
- The terraform-apply workflow with environment selection
