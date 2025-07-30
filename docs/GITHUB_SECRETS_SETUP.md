# GitHub Secrets Setup for CI/CD

This document outlines the required GitHub repository secrets for the Terraform workflows.

## Required Secrets

### Terraform Cloud Integration
- `TF_API_TOKEN`: Your Terraform Cloud API token
  - Get from: https://app.terraform.io/app/settings/tokens
  - Required for both apply and destroy workflows

### Azure Authentication
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
  - Same as `ARM_SUBSCRIPTION_ID` from your .env file
  - Used as `TF_VAR_subscription_id` in workflows

### Optional Secrets
- `AZURE_LOCATION`: Azure region (defaults to 'East US' if not set)
  - Used as `TF_VAR_location` in workflows

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
