# Terraform Cloud Setup Checklist

Use this checklist to set up Terraform Cloud for the Azure Policy project alongside your existing setup.

## Pre-Setup Checklist

- [ ] I have an existing Terraform Cloud account
- [ ] I have Azure CLI installed and authenticated (`az login`)
- [ ] I have appropriate Azure permissions (Contributor or Owner)
- [ ] I have a GitHub repository with admin access

## Organization Setup

Choose one option:

### Option A: Use Existing Organization
- [ ] Update organization name in `infrastructure/terraform/main.tf`
- [ ] Ensure your existing organization has sufficient workspace capacity

### Option B: Create New Organization
- [ ] Create new organization `stuartshay-azure-policy` at app.terraform.io
- [ ] Invite team members if needed

## Workspace Creation

Create these three workspaces in Terraform Cloud:

### Development Workspace
- [ ] **Name**: `azure-policy-dev`
- [ ] **Description**: "Azure Policy Development Environment"
- [ ] **Working Directory**: `infrastructure/terraform`
- [ ] **Auto Apply**: ✅ **Enabled** (for rapid development)
- [ ] **Terraform Version**: Latest (or lock to specific version)
- [ ] **Tags**: `azure-policy`, `dev`, `auto-apply`

### Staging Workspace
- [ ] **Name**: `azure-policy-staging`
- [ ] **Description**: "Azure Policy Staging Environment"
- [ ] **Working Directory**: `infrastructure/terraform`
- [ ] **Auto Apply**: ❌ **Disabled** (manual approval required)
- [ ] **Terraform Version**: Same as dev
- [ ] **Tags**: `azure-policy`, `staging`, `manual-apply`

### Production Workspace
- [ ] **Name**: `azure-policy-prod`
- [ ] **Description**: "Azure Policy Production Environment"
- [ ] **Working Directory**: `infrastructure/terraform`
- [ ] **Auto Apply**: ❌ **Disabled** (manual approval required)
- [ ] **Terraform Version**: Same as dev and staging
- [ ] **Tags**: `azure-policy`, `prod`, `manual-apply`

## Environment Variables Configuration

For **each workspace**, configure these environment variables:

### Azure Authentication (Mark all as Sensitive ✅)
- [ ] `ARM_CLIENT_ID` = `<your-service-principal-client-id>`
- [ ] `ARM_CLIENT_SECRET` = `<your-service-principal-secret>` (Sensitive)
- [ ] `ARM_SUBSCRIPTION_ID` = `<your-azure-subscription-id>`
- [ ] `ARM_TENANT_ID` = `<your-azure-tenant-id>`

### Workspace-Specific Terraform Variables

#### Development Workspace Variables
- [ ] `environment` = `"dev"`
- [ ] `location` = `"East US"` (or your preferred region)
- [ ] `cost_center` = `"development"`
- [ ] `owner` = `"platform-team"` (or your team)

#### Staging Workspace Variables
- [ ] `environment` = `"staging"`
- [ ] `location` = `"East US 2"` (different region for isolation)
- [ ] `cost_center` = `"development"`
- [ ] `owner` = `"platform-team"`

#### Production Workspace Variables
- [ ] `environment` = `"prod"`
- [ ] `location` = `"East US"` (primary region)
- [ ] `cost_center` = `"production"`
- [ ] `owner` = `"platform-team"`

## GitHub Repository Configuration

### GitHub Secrets
Go to Repository Settings → Secrets and variables → Actions:

- [ ] `ARM_CLIENT_ID` = `<your-service-principal-client-id>`
- [ ] `ARM_CLIENT_SECRET` = `<your-service-principal-secret>`
- [ ] `ARM_SUBSCRIPTION_ID` = `<your-azure-subscription-id>`
- [ ] `ARM_TENANT_ID` = `<your-azure-tenant-id>`
- [ ] `TF_API_TOKEN` = `<your-terraform-cloud-api-token>`

### Get Terraform Cloud API Token
- [ ] Go to Terraform Cloud → User Settings → Tokens
- [ ] Create a new token named "GitHub Actions - Azure Policy"
- [ ] Copy token value
- [ ] Add as `TF_API_TOKEN` secret in GitHub

### GitHub Environments (Optional but Recommended)
Create GitHub environments with protection rules:

- [ ] **Environment**: `dev` (no protection rules)
- [ ] **Environment**: `staging` (require 1 reviewer)
- [ ] **Environment**: `prod` (require 2 reviewers + branch protection)

## VCS Integration (Optional)

For automatic plan triggers on pull requests:

### Development Workspace
- [ ] Settings → Version Control → Connect to VCS
- [ ] Select your GitHub repository
- [ ] Set working directory: `infrastructure/terraform`
- [ ] Configure triggers: `*.tf`, `*.tfvars` files in `infrastructure/terraform/`

### Staging Workspace
- [ ] Same as dev, but consider limiting to specific branches

### Production Workspace
- [ ] Same as staging, but limit to `main` branch only

## Testing and Validation

### Initial Setup Test
- [ ] Run the setup script: `./scripts/setup-terraform-cloud.sh`
- [ ] Generate `terraform.tfvars` file
- [ ] Test Terraform initialization locally

### GitHub Actions Testing
- [ ] **Terraform Validate**: Test on a small change
- [ ] **Terraform Plan**: Verify plan generation works
- [ ] **Terraform Apply**: Deploy to dev environment first

### Workspace Verification
- [ ] **Dev**: Verify auto-apply works
- [ ] **Staging**: Verify manual approval is required
- [ ] **Prod**: Verify manual approval and additional protections

## Security and Best Practices

### Security Configuration
- [ ] All sensitive variables marked as sensitive
- [ ] API tokens have appropriate permissions (not admin unless needed)
- [ ] Service principal has minimum required Azure permissions
- [ ] GitHub secrets are properly scoped to repository

### Team Access
- [ ] Configure appropriate Terraform Cloud team permissions
- [ ] Set up notification preferences
- [ ] Configure approval workflows for production

### Monitoring and Maintenance
- [ ] Set up cost monitoring alerts in Azure
- [ ] Configure workspace notifications
- [ ] Plan for regular token rotation (90 days recommended)

## Documentation Updates

- [ ] Update README.md with Terraform Cloud setup info
- [ ] Update deployment documentation
- [ ] Add troubleshooting guide for common issues
- [ ] Document rollback procedures

## Post-Setup Validation

### Smoke Tests
- [ ] Deploy a simple resource to dev environment
- [ ] Verify state is stored in Terraform Cloud
- [ ] Test plan/apply workflow through GitHub Actions
- [ ] Verify resource cleanup works

### Team Training
- [ ] Team members can access Terraform Cloud workspaces
- [ ] Team knows how to trigger deployments
- [ ] Team understands approval workflows
- [ ] Emergency procedures are documented

## Success Criteria

✅ **Setup is complete when:**
- All three workspaces are created and configured
- GitHub Actions can successfully plan and apply
- State is properly managed in Terraform Cloud
- Team members can deploy to dev environment
- Production requires proper approvals
- Documentation is updated and team is trained

## Rollback Plan

If something goes wrong:
- [ ] Keep existing state backup
- [ ] Document any issues encountered
- [ ] Have plan to revert to previous setup if needed
- [ ] Test rollback procedure in dev environment first

---

## Quick Start Commands

```bash
# Run the setup script
./scripts/setup-terraform-cloud.sh

# Test locally
cd infrastructure/terraform
terraform init
terraform plan

# Deploy via GitHub Actions
# Go to Actions → Terraform Apply → Run workflow
```

## Support Resources

- 📖 [Terraform Cloud Documentation](https://www.terraform.io/cloud-docs)
- 🛠️ [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- 🤝 [GitHub Actions Integration](https://learn.hashicorp.com/tutorials/terraform/github-actions)
- 🎯 [Your existing TERRAFORM_CLOUD_SETUP.md](docs/TERRAFORM_CLOUD_SETUP.md)
