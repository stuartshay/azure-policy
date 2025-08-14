# Terraform Cloud Environment Variables - Quick Setup

## 🎯 **TL;DR - Quick Steps**

1. **Login**: [app.terraform.io](https://app.terraform.io) → `azure-policy-cloud` org
2. **Workspace**: Create/access `azure-policy-github-runner`
3. **Variables Tab**: Add the variables below
4. **Run**: Start new run to deploy

## 🔧 **Required Variables**

### **Environment Variables** (for Azure authentication):
```
ARM_CLIENT_ID = "your-service-principal-id"
ARM_CLIENT_SECRET = "your-service-principal-secret"  ← Mark SENSITIVE # pragma: allowlist secret
ARM_SUBSCRIPTION_ID = "your-azure-subscription-id"
ARM_TENANT_ID = "your-azure-tenant-id"
```

### **Terraform Variables** (for GitHub token):
```
TF_VAR_github_token = "ghp_your_github_token_here"  ← Mark SENSITIVE
```

## 🔍 **How to Find Your Values**

### **Azure Values**:
```bash
# Get subscription and tenant info
az account show

# Output shows:
"id": "09e01a7d-..."           # ← ARM_SUBSCRIPTION_ID
"tenantId": "87654321-..."     # ← ARM_TENANT_ID

# Service principal info (if you have one)
az ad sp show --id "your-sp-id"
```

### **GitHub Token**:
1. GitHub → Settings → Developer settings → Personal access tokens
2. Generate new token with `repo` and `workflow` scopes
3. Copy token immediately (starts with `ghp_`)

## 📍 **Variable Configuration Screen**

When adding each variable in Terraform Cloud:

**For Azure credentials** (Environment Variables):
```
Category: [Environment variable]
Key: ARM_CLIENT_ID
Value: 12345678-1234-1234-1234-123456789012
Description: Azure Service Principal Application ID
Sensitive: [ ] No
```

**For GitHub token** (Terraform Variable):
```
Category: [Terraform variable]
Key: TF_VAR_github_token
Value: ghp_abcdef1234567890...
Description: GitHub Personal Access Token
Sensitive: [✓] Yes  ← IMPORTANT!
HCL: [ ] No
```

## ✅ **Verification Checklist**

After adding variables:
- [ ] 4 Environment variables (ARM_*)
- [ ] 1+ Terraform variables (TF_VAR_*)
- [ ] Sensitive variables show as `(sensitive value)`
- [ ] No typos in variable names
- [ ] Workspace name matches: `azure-policy-github-runner`

## 🚀 **Deploy**

1. **Actions tab** → **"Start new run"**
2. **Message**: `"Deploy GitHub runner"`
3. **Review plan** → **Confirm & Apply**
4. **Wait 5-10 minutes** for completion
5. **Check GitHub**: Settings → Actions → Runners (should see "Idle" runner)

## 🆘 **Quick Troubleshooting**

| Error | Fix |
|-------|-----|
| "Invalid Azure credentials" | Check ARM_* values, test with `az login --service-principal` |
| "GitHub token invalid" | Test with `curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user` |
| "Workspace not found" | Ensure workspace name exactly matches `terraform.tf` |
| "Variables not applied" | Check category: Azure = Environment, GitHub = Terraform |

---
**🎯 Goal**: Once setup is complete, your GitHub self-hosted runner will be deployed in your Azure VNet, ready to deploy Function Apps that were previously blocked by the 403 SCM error!
