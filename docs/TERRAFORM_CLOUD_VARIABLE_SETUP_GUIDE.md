# How to Configure Environment Variables in Terraform Cloud

This guide provides step-by-step instructions with screenshots and detailed explanations for setting up environment variables in your Terraform Cloud workspace.

## 🎯 **Prerequisites**

Before starting, ensure you have:
- [ ] Terraform Cloud account at [app.terraform.io](https://app.terraform.io)
- [ ] GitHub Personal Access Token (created earlier)
- [ ] Azure Service Principal credentials
- [ ] Access to the `NavigateAzure` organization (or create your own)

## 🚀 **Step-by-Step Process**

### **Step 1: Access Terraform Cloud**

1. **Login to Terraform Cloud**:
   - Go to [app.terraform.io](https://app.terraform.io)
   - Sign in with your account

2. **Navigate to Organization**:
   - Select organization: `NavigateAzure`
   - If it doesn't exist, create it by clicking "New Organization"

### **Step 2: Create/Access Workspace**

#### **Option A: Create New Workspace**

1. **Click "New workspace"**
2. **Choose workflow type**:
   - Select **"Version control workflow"**
3. **Connect to GitHub**:
   - Choose **"GitHub.com"**
   - Authorize Terraform Cloud to access your GitHub
   - Select repository: `stuartshay/azure-policy`
4. **Configure workspace**:
   - **Workspace name**: `azure-policy-github-runner` ⚠️ **Must match terraform.tf exactly**
   - **Advanced options**:
     - **Working Directory**: `infrastructure/github-runner`
     - **VCS branch**: `main` (or `develop` if using that branch)

#### **Option B: Access Existing Workspace**

1. **Click on workspace**: `azure-policy-github-runner`
2. **Go to Variables tab**

### **Step 3: Configure Environment Variables**

#### **Navigate to Variables**
1. **Click on "Variables" tab** in your workspace
2. You'll see two sections:
   - **Environment variables** (for runtime environment)
   - **Terraform variables** (passed to Terraform configuration)

#### **Add Azure Authentication Variables** (Environment Variables)

Click **"Add variable"** for each of these:

**1. ARM_CLIENT_ID**
```
Category: Environment variable
Key: ARM_CLIENT_ID
Value: your-service-principal-application-id
Description: Azure Service Principal Application ID
Sensitive: ❌ No
```

**2. ARM_CLIENT_SECRET**
```
Category: Environment variable
Key: ARM_CLIENT_SECRET
Value: your-service-principal-secret
Description: Azure Service Principal Secret
Sensitive: ✅ YES - Mark as sensitive
```

**3. ARM_SUBSCRIPTION_ID**
```
Category: Environment variable
Key: ARM_SUBSCRIPTION_ID
Value: your-azure-subscription-id
Description: Azure Subscription ID
Sensitive: ❌ No
```

**4. ARM_TENANT_ID**
```
Category: Environment variable
Key: ARM_TENANT_ID
Value: your-azure-tenant-id
Description: Azure Tenant ID
Sensitive: ❌ No
```

#### **Add GitHub Token Variable** (Terraform Variable)

**5. TF_VAR_github_token**
```
Category: Terraform variable
Key: TF_VAR_github_token
Value: ghp_your_actual_github_token_here
Description: GitHub Personal Access Token for runner registration
Sensitive: ✅ YES - Mark as sensitive
HCL: ❌ No
```

#### **Optional: Override Default Values** (Terraform Variables)

If you want to override any default values, add these as **Terraform variables**:

```
TF_VAR_resource_group_name = "rg-azpolicy-dev-eastus"
TF_VAR_github_repo_url = "https://github.com/stuartshay/azure-policy"
TF_VAR_vm_size = "Standard_B2s"
```

### **Step 4: Variable Configuration Reference**

#### **How to Find Your Azure Values**

```bash
# Get your Azure subscription and tenant info
az account show

# Example output:
{
  "id": "09e01a7d-07d4-43ee-80c7-8b2c0d7ec41f",        # ← ARM_SUBSCRIPTION_ID
  "tenantId": "87654321-4321-4321-4321-210987654321"    # ← ARM_TENANT_ID
}

# Get service principal info (if you have one)
az ad sp list --display-name "your-service-principal-name"
```

### **Step 5: Save and Verify**

1. **Click "Save variable"** for each variable
2. **Verify all variables are present**:
   - 4 Environment variables (ARM_*)
   - 1+ Terraform variables (TF_VAR_*)
3. **Check sensitive variables** show as `(sensitive value)`

### **Step 6: Test the Configuration**

#### **Method A: Trigger Run via Web UI**

1. **Go to "Actions" tab** in your workspace
2. **Click "Start new run"**
3. **Add run message**: `"Test GitHub runner deployment with environment variables"`
4. **Click "Start run"**
5. **Review the plan** - should show resource creation
6. **If plan looks good**, click **"Confirm & Apply"**

#### **Method B: Trigger Run via CLI**

```bash
# From your local machine
cd infrastructure/github-runner

# Login to Terraform Cloud (one-time setup)
terraform login

# Initialize with remote backend
terraform init

# Plan to see what will be created
terraform plan

# Apply if plan looks good
terraform apply
```

### **Step 7: Monitor Deployment**

1. **Watch the run progress** in Terraform Cloud
2. **Check the logs** for any errors
3. **Wait for completion** (usually 5-10 minutes)
4. **Verify outputs** are displayed

### **Step 8: Verify GitHub Runner Registration**

1. **Go to your GitHub repository**
2. **Navigate to**: Settings → Actions → Runners
3. **Look for runner**: `azure-vnet-runner-dev`
4. **Status should be**: "Idle" (ready to use)

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **1. "Invalid Azure Credentials"**
- **Cause**: Wrong ARM_* values or service principal doesn't exist
- **Solution**: Verify service principal and permissions:
```bash
az login --service-principal \
  --username $ARM_CLIENT_ID \
  --password $ARM_CLIENT_SECRET \
  --tenant $ARM_TENANT_ID
```

#### **2. "GitHub Token Invalid"**
- **Cause**: Token expired or insufficient permissions
- **Solution**: Test token and regenerate if needed:
```bash
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
```

#### **3. "Workspace Not Found"**
- **Cause**: Workspace name mismatch with `terraform.tf`
- **Solution**: Ensure workspace name exactly matches:
```hcl
# In terraform.tf
terraform {
  cloud {
    organization = "NavigateAzure"
    workspaces {
      name = "azure-policy-github-runner"  # Must match exactly
    }
  }
}
```

#### **4. "Variables Not Applied"**
- **Cause**: Variable category wrong or typo in name
- **Solution**: Check variable categories:
  - Azure auth: **Environment variables**
  - GitHub token: **Terraform variable** with `TF_VAR_` prefix

### **Variable Categories Explained**

| Category | When to Use | Example |
|----------|-------------|---------|
| **Environment Variable** | For provider authentication, runtime settings | `ARM_CLIENT_ID`, `PATH` |
| **Terraform Variable** | For values passed to your Terraform config | `TF_VAR_github_token` |

## 🔒 **Security Best Practices**

1. **Always mark secrets as sensitive**:
   - `ARM_CLIENT_SECRET`
   - `TF_VAR_github_token`

2. **Use descriptive variable names**:
   - Include purpose in description
   - Follow naming conventions

3. **Rotate secrets regularly**:
   - Set token expiration dates
   - Update variables when rotating

4. **Limit workspace access**:
   - Use team-based permissions
   - Enable audit logging

## 🎉 **Success Indicators**

You know it's working when:
- ✅ Terraform Cloud run completes successfully
- ✅ GitHub runner appears as "Idle" in repository settings
- ✅ VM is created in Azure portal
- ✅ No error messages in Terraform logs

## 📱 **Quick Reference: Variable Setup**

Copy this checklist for quick setup:

```
Environment Variables:
□ ARM_CLIENT_ID = "your-sp-id"
□ ARM_CLIENT_SECRET = "your-sp-secret" (SENSITIVE) # pragma: allowlist secret
□ ARM_SUBSCRIPTION_ID = "your-sub-id"
□ ARM_TENANT_ID = "your-tenant-id"

Terraform Variables:
□ TF_VAR_github_token = "ghp_your-token" (SENSITIVE)

Optional Terraform Variables:
□ TF_VAR_resource_group_name = "rg-azpolicy-dev-eastus"
□ TF_VAR_vm_size = "Standard_B2s"
```

---

**Next Steps**: Once variables are configured, your GitHub runner will be deployed automatically via Terraform Cloud, providing secure VNet access for your Azure Functions deployment! 🚀
