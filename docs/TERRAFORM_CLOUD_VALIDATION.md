# Terraform Cloud Validation Guide

## Overview
This document describes the Terraform Cloud setup validation and key findings for the Azure Policy project.

## Terraform Cloud Configuration

### Organization and Workspaces
- **Organization**: `azure-policy-cloud`
- **Workspaces**:
  - `azure-policy-infrastructure` - Core infrastructure resources
  - `azure-policy-functions` - Azure Functions resources
  - `azure-policy-policies` - Policy definitions and assignments

### Authentication Setup
- **Terraform Cloud API Token**: Configured in `.env` as `TF_API_TOKEN`
- **CLI Configuration**: Located at `.terraform.d/credentials.tfrc.json`
- **Azure Service Principal**: Configured for remote execution

## Directory Structure

### Infrastructure Layouts
The project has two infrastructure directories:

1. **`infrastructure/infrastructure/`** - ✅ **ACTIVE**
   - Used by Terraform Cloud workspace `azure-policy-infrastructure`
   - Contains core infrastructure resources
   - Properly configured for remote execution

2. **`infrastructure/terraform/`** - ⚠️ **LEGACY**
   - Contains similar configuration but not used by Terraform Cloud
   - More comprehensive module structure
   - Consider consolidating with active directory

## Validation Results

### ✅ Working Components
- [x] Terraform Cloud authentication via API token
- [x] Organization and workspace connectivity
- [x] Configuration file upload and parsing
- [x] Remote execution environment initialization
- [x] Workspace selection and switching

### ❌ Issues Identified

#### 1. Azure Authentication Method
**Issue**: Terraform Cloud agent trying to use Azure CLI authentication
```
Error: could not configure AzureCli Authorizer: exec: "az": executable file not found in $PATH
```

**Solution**: Configure workspace to use Service Principal authentication
- Set environment variables in Terraform Cloud workspace:
  - `ARM_CLIENT_ID`
  - `ARM_CLIENT_SECRET`
  - `ARM_SUBSCRIPTION_ID`
  - `ARM_TENANT_ID`

#### 2. Variable Declarations
**Issue**: terraform.tfvars contains variables not declared in variables.tf
```
Warning: Value for undeclared variable "TF_VAR_cost_center"
Warning: Value for undeclared variable "TF_VAR_location"
```

**Solution**: Ensure all variables in terraform.tfvars are declared in variables.tf

## Next Steps

### Immediate Actions
1. **Configure Azure Service Principal in Terraform Cloud**:
   - Navigate to workspace settings
   - Add environment variables for ARM_* credentials
   - Set as sensitive variables

2. **Align Variable Declarations**:
   - Review variables.tf in `infrastructure/infrastructure/`
   - Add missing variable declarations
   - Ensure consistency with terraform.tfvars

3. **Test Complete Workflow**:
   - Run `terraform plan` after authentication fix
   - Validate resource creation capabilities
   - Test `terraform apply` with minimal resources

### Future Improvements
1. **Consolidate Infrastructure Directories**:
   - Evaluate merging `infrastructure/terraform/` modules into `infrastructure/infrastructure/`
   - Maintain single source of truth for infrastructure

2. **Automate Validation**:
   - Add Terraform Cloud validation to CI/CD pipeline
   - Include workspace connectivity tests

## Commands for Local Validation

```bash
# Navigate to correct directory
cd /home/vagrant/git/azure-policy/infrastructure/infrastructure

# Load environment variables
source ../../.env

# Check workspace
terraform workspace show

# Validate configuration
terraform validate

# Plan (requires workspace environment variables)
terraform plan
```

## Terraform Cloud URLs
- **Organization**: https://app.terraform.io/app/azure-policy-cloud
- **Infrastructure Workspace**: https://app.terraform.io/app/azure-policy-cloud/azure-policy-infrastructure
- **Functions Workspace**: https://app.terraform.io/app/azure-policy-cloud/azure-policy-functions
- **Policies Workspace**: https://app.terraform.io/app/azure-policy-cloud/azure-policy-policies

## Environment Variables Required

### Local Development (.env)
```bash
TF_API_TOKEN=<terraform_cloud_token>
TF_CLI_CONFIG_FILE=/home/vagrant/git/azure-policy/.terraform.d/credentials.tfrc.json
TF_CLOUD_ORGANIZATION=azure-policy-cloud
ARM_CLIENT_ID=<service_principal_client_id>
ARM_CLIENT_SECRET=<service_principal_client_secret>
ARM_SUBSCRIPTION_ID=<azure_subscription_id>
ARM_TENANT_ID=<azure_tenant_id>
```

### Terraform Cloud Workspace
```bash
ARM_CLIENT_ID=<service_principal_client_id>
ARM_CLIENT_SECRET=<service_principal_client_secret> (sensitive)
ARM_SUBSCRIPTION_ID=<azure_subscription_id>
ARM_TENANT_ID=<azure_tenant_id>
```

## Status
- **Authentication**: ✅ Working (API token, CLI config)
- **Workspace Selection**: ✅ Working (azure-policy-infrastructure)
- **Configuration Upload**: ✅ Working
- **Azure Provider**: ❌ Needs Service Principal setup
- **Resource Planning**: ❌ Blocked by authentication

**Last Updated**: August 1, 2025
**Validation Status**: Partial - Authentication setup required
