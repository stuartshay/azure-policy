# Manual Cleanup and Restart Guide

## Overview
This guide will help you manually destroy all Azure resources and restart with a clean slate.

## ⚠️ Prerequisites
- Azure CLI installed and authenticated
- Terraform CLI installed
- Access to Terraform Cloud organization
- Backup any important data (this will delete everything!)

## 🗑️ Step 1: Manual Azure Resource Cleanup

### Option A: Delete Resource Groups (Fastest)
```bash
# List all resource groups related to the project
az group list --query "[?contains(name, 'azpolicy') || contains(name, 'rg-azurepolicy')].name" -o table

# Delete each resource group (replace with actual names)
az group delete --name "rg-azpolicy-infra-dev-eastus" --yes --no-wait
az group delete --name "rg-azurepolicy-functions-dev-eastus" --yes --no-wait
az group delete --name "rg-azurepolicy-policies-dev-eastus" --yes --no-wait

# For staging environment
az group delete --name "rg-azpolicy-infra-staging-eastus" --yes --no-wait
```

### Option B: Targeted Resource Deletion
```bash
# List all resources with project tags
az resource list --tag Project=azurepolicy --query "[].{Name:name, Type:type, ResourceGroup:resourceGroup}" -o table

# Delete specific resource types if needed
az vm list --query "[?contains(name, 'azpolicy')]" -o table
az storage account list --query "[?contains(name, 'azpolicy')]" -o table
az functionapp list --query "[?contains(name, 'azpolicy')]" -o table
```

## 🏗️ Step 2: Clean Up Terraform Cloud State

### Reset Workspace States
1. Go to [Terraform Cloud](https://app.terraform.io/)
2. Navigate to your organization: `azure-policy-cloud`
3. For each workspace:
   - `azure-policy-core`
   - `azure-policy-policies`
   - `azure-policy-functions`

   **Do the following:**
   - Settings → Destruction and Deletion
   - Click "Queue destroy plan"
   - After destroy completes, go to States tab
   - Delete all state versions or reset to empty state

### Alternative: Delete and Recreate Workspaces
```bash
# Using Terraform Cloud API (requires TF_API_TOKEN)
# Delete workspaces
curl -X DELETE \
  -H "Authorization: Bearer $TF_API_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/azure-policy-cloud/workspaces/azure-policy-core

curl -X DELETE \
  -H "Authorization: Bearer $TF_API_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/azure-policy-cloud/workspaces/azure-policy-policies

curl -X DELETE \
  -H "Authorization: Bearer $TF_API_TOKEN" \
  -H "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/azure-policy-cloud/workspaces/azure-policy-functions
```

## 🔄 Step 3: Recreate Terraform Cloud Workspaces

### Create New Workspaces with Proper Configuration

1. **Infrastructure Workspace:**
   ```bash
   # Create workspace
   curl -X POST \
     -H "Authorization: Bearer $TF_API_TOKEN" \
     -H "Content-Type: application/vnd.api+json" \
     -d '{
       "data": {
         "type": "workspaces",
         "attributes": {
           "name": "azure-policy-core",
           "terraform-version": "1.6.0",
           "working-directory": "infrastructure/infrastructure"
         }
       }
     }' \
     https://app.terraform.io/api/v2/organizations/azure-policy-cloud/workspaces
   ```

2. **Set Workspace Variables:**
   - `TF_VAR_subscription_id` (sensitive)
   - `TF_VAR_location` = "East US"
   - `TF_VAR_environment` = "dev"
   - `TF_VAR_owner` = "platform-team"
   - `TF_VAR_cost_center` = "development"

3. **Repeat for other workspaces** (policies, functions)

## 🚀 Step 4: Test Clean Deployment

### Manual Terraform Run (Local Testing)
```bash
# Test infrastructure module locally first
cd infrastructure/infrastructure

# Initialize with backend=false for testing
terraform init -backend=false

# Validate configuration
terraform validate

# Plan (without remote state)
terraform plan -var="subscription_id=YOUR_SUB_ID" -var="environment=dev"
```

### GitHub Actions Testing
1. Run "Terraform Validate" workflow first
2. Then run "Terraform Apply" for infrastructure module
3. Monitor logs for any issues

## 🔧 Step 5: Alternative Local Terraform Reset

If you want to reset everything locally:

```bash
# Remove all .terraform directories
find infrastructure/ -name ".terraform" -type d -exec rm -rf {} +
find infrastructure/ -name ".terraform.lock.hcl" -delete

# Remove any local state files
find infrastructure/ -name "terraform.tfstate*" -delete

# Reinitialize all modules
for module in infrastructure policies functions; do
  echo "Initializing $module..."
  cd "infrastructure/$module"
  terraform init
  cd ../..
done
```

## 📋 Verification Checklist

After cleanup:
- [ ] No Azure resource groups with 'azpolicy' in name
- [ ] No orphaned resources in Azure Portal
- [ ] Terraform Cloud workspaces are empty or recreated
- [ ] Local .terraform directories are clean
- [ ] GitHub Actions workflows can initialize successfully

## 🆘 Emergency Commands

### Force Delete Stuck Resources
```bash
# If resource group deletion is stuck
az group delete --name "RESOURCE_GROUP_NAME" --force-deletion-types Microsoft.Compute/virtualMachines --yes

# List all resources in subscription (be careful!)
az resource list --query "[].{Name:name, Type:type, ResourceGroup:resourceGroup}" -o table
```

### Reset Everything Nuclear Option
```bash
# ⚠️ DANGER: This will delete ALL resources in the subscription
# Only use if this is a dedicated development subscription
az group list --query "[].name" -o tsv | xargs -I {} az group delete --name {} --yes --no-wait
```

## 📞 Support

If you encounter issues:
1. Check Azure Activity Log for deletion failures
2. Review Terraform Cloud workspace logs
3. Verify Azure service health
4. Check for resource locks or policies preventing deletion

---

**Next Steps After Cleanup:**
1. Run the cleanup commands above
2. Verify all resources are gone
3. Test a fresh deployment with the updated workflows
4. Monitor the GitHub Actions for successful runs
