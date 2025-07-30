# Terraform Cloud Setup Guide

This guide walks you through setting up Terraform Cloud for the Azure Policy project.

## Prerequisites

- GitHub repository with admin access
- Azure subscription with appropriate permissions

## Step 1: Create Terraform Cloud Account

1. Go to [app.terraform.io](https://app.terraform.io)
2. Sign up with your GitHub account
3. Create a new organization named `stuartshay-azure-policy` (or update the name in `main.tf`)

## Step 2: Create Workspaces

Create three workspaces for different environments:

### Development Workspace
- **Name**: `azure-policy-dev`
- **Working Directory**: `infrastructure/terraform`
- **Auto Apply**: Enable (for dev environment)
- **Tags**: `azure-policy`, `dev`

### Staging Workspace
- **Name**: `azure-policy-staging`
- **Working Directory**: `infrastructure/terraform`
- **Auto Apply**: Disable (manual approval)
- **Tags**: `azure-policy`, `staging`

### Production Workspace
- **Name**: `azure-policy-prod`
- **Working Directory**: `infrastructure/terraform`
- **Auto Apply**: Disable (manual approval)
- **Tags**: `azure-policy`, `prod`

## Step 3: Configure Workspace Variables

For each workspace, add the following environment variables:

### Environment Variables (Marked as Sensitive)
- `ARM_CLIENT_ID`: Your Azure Service Principal Client ID
- `ARM_CLIENT_SECRET`: Your Azure Service Principal Client Secret (Sensitive)
- `ARM_SUBSCRIPTION_ID`: Your Azure Subscription ID
- `ARM_TENANT_ID`: Your Azure Tenant ID

### Terraform Variables
- `environment`: Set to `dev`, `staging`, or `prod` respectively
- `location`: Set based on environment preference
- `cost_center`: Set appropriate cost center

## Step 4: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Add these repository secrets:

### Required Secrets
- `ARM_CLIENT_ID`: Your Azure Service Principal Client ID
- `ARM_CLIENT_SECRET`: Your Azure Service Principal Client Secret
- `ARM_SUBSCRIPTION_ID`: Your Azure Subscription ID
- `ARM_TENANT_ID`: Your Azure Tenant ID
- `TF_API_TOKEN`: Your Terraform Cloud API token

### Getting Terraform Cloud API Token
1. In Terraform Cloud, go to **User Settings** → **Tokens**
2. Create a new API token
3. Copy the token and add it as `TF_API_TOKEN` secret in GitHub

## Step 5: Configure VCS Integration (Optional)

For automatic plan triggers on pull requests:

1. In each workspace, go to **Settings** → **Version Control**
2. Connect to your GitHub repository
3. Set working directory to `infrastructure/terraform`
4. Configure trigger patterns if needed

## Step 6: Test the Setup

1. Make a small change to your Terraform configuration
2. Run the GitHub Actions workflow
3. Verify that the plan is created in Terraform Cloud
4. Check that the state is properly managed

## Benefits of This Setup

✅ **Centralized State Management**: No more state file conflicts  
✅ **Collaboration**: Team members can see plans and state  
✅ **Security**: Sensitive variables are encrypted  
✅ **Audit Trail**: All changes are logged  
✅ **Plan/Apply Separation**: Review changes before applying  
✅ **Free for Small Teams**: Up to 5 users at no cost  

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Verify all ARM_ variables are set correctly
2. **Workspace Not Found**: Check TF_WORKSPACE environment variable
3. **Permission Denied**: Ensure API token has appropriate permissions

### Useful Commands

```bash
# Login to Terraform Cloud locally
terraform login

# List workspaces
terraform workspace list

# Select workspace
terraform workspace select azure-policy-dev
```

## Alternative: Azure Storage Backend

If you prefer to use Azure Storage instead of Terraform Cloud, see the [Azure Backend Setup Guide](AZURE_BACKEND_SETUP.md).

## Security Considerations

- ✅ Never commit sensitive values to git
- ✅ Use environment-specific workspaces
- ✅ Enable auto-apply only for development
- ✅ Require manual approval for production
- ✅ Regular audit of access permissions
- ✅ Rotate API tokens regularly
