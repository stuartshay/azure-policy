# Azure Policy Project - Jupyter Notebooks

This directory contains Jupyter notebooks for validating and managing the Azure Policy project infrastructure.

## Notebooks

### 1. Environment Validation (`environment_validation.ipynb`)
This notebook validates the Azure environment and checks quotas before deploying resources.

**Features:**
- Azure authentication verification
- Subscription access validation
- Resource quota checking for East US and East US 2
- App Service Plan quota validation (including Elastic Premium)
- Cost estimation for different SKUs
- Resource provider registration status

## Setup

1. Ensure you have the required dependencies installed:
   ```bash
   pip install -r requirements.txt
   ```

2. Start Jupyter Lab or Jupyter Notebook:
   ```bash
   jupyter lab
   # or
   jupyter notebook
   ```

3. Open the desired notebook and run the cells

## Environment Variables

The notebooks use the same environment variables as the main project:
- `ARM_CLIENT_ID` - Azure Service Principal Client ID
- `ARM_CLIENT_SECRET` - Azure Service Principal Client Secret
- `ARM_SUBSCRIPTION_ID` - Azure Subscription ID
- `ARM_TENANT_ID` - Azure Tenant ID

These should be configured in your `.env` file.

## Usage Tips

- Run cells sequentially for best results
- Check the output of authentication cells before proceeding
- Review quota information carefully before deploying resources
- Use the cost estimation to plan your deployments
