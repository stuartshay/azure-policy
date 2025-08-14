# Terraform Cloud GitHub Token Setup Guide

This guide walks through setting up secure GitHub token management for the self-hosted runner deployment using Terraform Cloud.

## 🎯 **Overview**

Instead of storing the GitHub Personal Access Token in local files, we'll use Terraform Cloud's secure environment variable system to manage secrets.

## 🔐 **Step 1: Create GitHub Personal Access Token**

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click **"Generate new token (classic)"**
3. Configure the token:
   - **Note**: `Azure Policy Self-Hosted Runner`
   - **Expiration**: 90 days (recommended) or Custom
   - **Scopes** (check these):
     - ✅ `repo` (Full control of private repositories)
     - ✅ `workflow` (Update GitHub Action workflows)
     - ✅ `admin:org` (if using organization runners)

4. Click **"Generate token"**
5. **⚠️ IMPORTANT**: Copy the token immediately (you won't see it again)
   - Format: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` # pragma: allowlist secret

## 🌐 **Step 2: Configure Terraform Cloud Workspace**

### **Create Workspace** (if not exists)

1. Go to [app.terraform.io](https://app.terraform.io)
2. Select organization: `NavigateAzure`
3. Click **"New workspace"**
4. Choose **"Version control workflow"**
5. Connect to GitHub repository: `stuartshay/azure-policy`
6. Configure workspace:
   - **Workspace name**: `azure-policy-github-runner` (**Must match terraform.tf exactly**)
   - **Working Directory**: `infrastructure/github-runner`
   - **VCS branch**: `main`

⚠️ **Important**: The workspace name in Terraform Cloud must exactly match the name in `terraform.tf`:

```hcl
# infrastructure/github-runner/terraform.tf
terraform {
  cloud {
    organization = "NavigateAzure"
    workspaces {
      name = "azure-policy-github-runner"
    }
  }
}
```

If your organization or workspace name is different, update `terraform.tf` accordingly.

### **Configure Environment Variables**

In the Terraform Cloud workspace, go to **Variables** tab and add:

#### **Azure Authentication** (Environment Variables):
```bash
# Azure Service Principal (Environment Variables)
ARM_CLIENT_ID = "your-service-principal-app-id"
ARM_CLIENT_SECRET = "your-service-principal-secret"    # ✅ Mark as SENSITIVE # pragma: allowlist secret
ARM_SUBSCRIPTION_ID = "your-azure-subscription-id"
ARM_TENANT_ID = "your-azure-tenant-id"
```

#### **GitHub Token** (Terraform Variables):
```bash
# GitHub Personal Access Token (Terraform Variables)
TF_VAR_github_token = "ghp_your_actual_github_token_here"    # ✅ Mark as SENSITIVE
```

#### **Optional Configuration** (Terraform Variables):
```bash
# Optional: Override defaults
TF_VAR_resource_group_name = "rg-azpolicy-dev-eastus"
TF_VAR_github_repo_url = "https://github.com/stuartshay/azure-policy"
TF_VAR_vm_size = "Standard_B2s"
```

### **Variable Configuration Details**

| Variable | Category | Sensitive | Description |
|----------|----------|-----------|-------------|
| `ARM_CLIENT_ID` | Environment | No | Azure Service Principal ID |
| `ARM_CLIENT_SECRET` | Environment | **Yes** | Azure Service Principal Secret |
| `ARM_SUBSCRIPTION_ID` | Environment | No | Azure Subscription ID |
| `ARM_TENANT_ID` | Environment | No | Azure Tenant ID |
| `TF_VAR_github_token` | Terraform | **Yes** | GitHub Personal Access Token |

## 🚀 **Step 3: Deploy via Terraform Cloud**

### **Option A: Web UI Deployment**

1. Go to your workspace in Terraform Cloud
2. Click **"Actions"** → **"Start new run"**
3. Add a message: `"Deploy GitHub self-hosted runner"`
4. Click **"Start run"**
5. Review the plan and click **"Confirm & Apply"**

### **Option B: CLI Deployment**

```bash
cd infrastructure/github-runner

# Login to Terraform Cloud
terraform login

# Initialize with remote backend
terraform init

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```

## ✅ **Step 4: Verify Deployment**

### **Check Terraform Cloud**
1. View run logs in Terraform Cloud workspace
2. Check outputs in the workspace overview

### **Check GitHub**
1. Go to your repository → Settings → Actions → Runners
2. Look for runner: `azure-vnet-runner-dev` (should show as "Idle")

### **Test Runner**
```bash
# Using local CLI (if authenticated)
cd infrastructure/github-runner
make test-runner
```

## 🔄 **Step 5: Workflow Integration**

Update your GitHub Actions workflow to use the self-hosted runner:

```yaml
name: Deploy Function App (VNet)

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: [self-hosted, azure, vnet]  # Use your runner labels
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Function App
        run: |
          # Your deployment commands here
          # This runs inside the Azure VNet
```

## 🔧 **Troubleshooting**

### **GitHub Token Issues**

1. **Token Expired**:
   ```bash
   # Test token validity
   curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
   ```
   - If expired, generate a new token and update `TF_VAR_github_token`

2. **Insufficient Permissions**:
   - Ensure token has `repo` and `workflow` scopes
   - For organization repos, add `admin:org` scope

3. **Variable Not Found**:
   - Check variable name is exactly: `TF_VAR_github_token`
   - Ensure it's marked as **Sensitive**

### **Azure Authentication Issues**

1. **Service Principal Issues**:
   ```bash
   # Test Azure CLI login
   az login --service-principal \
     --username $ARM_CLIENT_ID \
     --password $ARM_CLIENT_SECRET \
     --tenant $ARM_TENANT_ID
   ```

2. **Permission Issues**:
   - Service Principal needs `Contributor` role on subscription
   - May need `User Access Administrator` for role assignments

### **Terraform Cloud Issues**

1. **Workspace Not Found**:
   ```bash
   # Check workspace configuration
   cat terraform.tf
   ```

2. **Backend Configuration**:
   ```bash
   # Re-initialize if needed
   rm -rf .terraform
   terraform init
   ```

3. **Variable Scoping**:
   - Environment variables: Available to Terraform process
   - Terraform variables: Passed to Terraform configuration

## 🛡️ **Security Best Practices**

1. **Token Rotation**:
   - Set token expiration to 90 days maximum
   - Rotate tokens regularly
   - Use GitHub App tokens for production (more secure)

2. **Variable Management**:
   - Always mark secrets as **Sensitive**
   - Use descriptive variable names
   - Document variable purposes

3. **Access Control**:
   - Limit Terraform Cloud workspace access
   - Use team-based permissions
   - Enable audit logging

## 📚 **Additional Resources**

- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Terraform Cloud Variables](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables)
- [Azure Service Principal Setup](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
- [GitHub Self-Hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
