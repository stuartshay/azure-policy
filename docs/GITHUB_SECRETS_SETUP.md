# GitHub Secrets Setup for CI/CD

This document outlines the required GitHub repository secrets for the Terraform workflows.

## Required Secrets

### For Local Backend (Current Configuration)
- `AZURE_CLIENT_ID`: Azure Service Principal client ID
  - Value from your .env: `ARM_CLIENT_ID`
- `AZURE_CLIENT_SECRET`: Azure Service Principal client secret  
  - Value from your .env: `ARM_CLIENT_SECRET`
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
  - Value from your .env: `ARM_SUBSCRIPTION_ID`
- `AZURE_TENANT_ID`: Your Azure tenant ID
  - Value from your .env: `ARM_TENANT_ID`
- `AZURE_LOCATION`: Azure region (optional, defaults to 'East US')

### For Terraform Cloud Integration (If Enabled Later)
- `TF_API_TOKEN`: Your Terraform Cloud API token
  - Get from: https://app.terraform.io/app/settings/tokens
  - Required only if using Terraform Cloud backend

## Setting Up Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each required secret with the appropriate value

## Workflow Usage

### Apply Workflow
- Uses: `TF_API_TOKEN`, `AZURE_SUBSCRIPTION_ID`, `AZURE_LOCATION`
- Trigger: Manual dispatch with environment selection and confirmation

### Destroy Workflow
- Uses: `TF_API_TOKEN`, `AZURE_SUBSCRIPTION_ID`, `AZURE_LOCATION`
- Trigger: Manual dispatch with environment selection and double confirmation
- **Safety Features**:
  - Requires typing "destroy" to confirm
  - Requires typing environment name to confirm
  - Shows plan before destruction
  - Verifies destruction completion

## Current Infrastructure

Your infrastructure uses the naming pattern: `rg-azpolicy-{environment}-{location}`

Examples:
- Dev environment: `rg-azpolicy-dev-eastus`
- Staging environment: `rg-azpolicy-staging-eastus`
- Prod environment: `rg-azpolicy-prod-eastus`

## Backend Configuration

Currently using **local backend** (Terraform Cloud backend is commented out).
- State files are stored locally in the runner
- Works with current workflow configuration
- Can be switched to Terraform Cloud if needed

## Security Considerations

- Never commit actual secret values to the repository
- Use `.env` file for local development (excluded by .gitignore)
- Rotate secrets periodically
- Monitor secret usage in GitHub Actions logs
- Consider using environment-specific secrets for production workloads
