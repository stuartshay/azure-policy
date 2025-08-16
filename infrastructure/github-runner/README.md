# GitHub Self-Hosted Runner with Public IP (GitHub-Restricted)

This Terraform configuration deploys a GitHub self-hosted runner with a **public IP address** that is **restricted to GitHub's IP ranges only** using Network Security Group rules.

## 🎯 **Architecture Benefits**

✅ **Public IP Access**: Runner can be reached from internet for management
✅ **GitHub-Only Access**: NSG rules restrict inbound access to GitHub's IP ranges
✅ **VNet Integration**: Runner is inside your VNet for Function App access
✅ **Cost Effective**: ~$30/month for Standard_B2s VM
✅ **Auto-Shutdown**: Optional cost savings with scheduled shutdown

## 🔒 **Security Model**

```
┌─────────────────────────────────────────────┐
│                Internet                     │
│  ┌─────────────────┐  ┌─────────────────┐   │
│  │   GitHub IPs    │  │  Other Sources  │   │
│  │   (Allowed)     │  │   (Blocked)     │   │
│  └─────────┬───────┘  └─────────────────┘   │
└────────────┼─────────────────────────────────┘
             │ SSH (22) ✅
             ▼
┌─────────────────────────────────────────────┐
│              Azure VNet                     │
│  ┌─────────────────┐  ┌─────────────────┐   │
│  │ GitHub Runner   │  │  Function App   │   │
│  │ (Public IP +    │──│  (Private)      │   │
│  │  NSG Rules)     │  └─────────────────┘   │
│  └─────────────────┘                        │
└─────────────────────────────────────────────┘
```

### **Automatically Allowed IPs** (from GitHub API):
- GitHub Actions runner infrastructure IPs
- GitHub webhook delivery IPs
- Updated automatically via GitHub's `/meta` API

### **Optional Additional IPs**:
- Your office/home IP for management access
- Configured via `allowed_management_ips` variable

## 🚀 **Quick Start**

### **1. Prerequisites**
```bash
# Create GitHub Personal Access Token
# Go to: GitHub → Settings → Developer settings → Personal access tokens
# Scopes needed: repo, workflow, admin:org (if using organization)

# Generate SSH key (optional, for management access)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github-runner-key
```

### **2. Terraform Cloud Setup (Recommended)**

For secure secret management and remote state, configure Terraform Cloud:

1. **Create Terraform Cloud Workspace**:
   - Go to [app.terraform.io](https://app.terraform.io)
   - Create organization: `NavigateAzure` (or update in `variables.tf`)
   - Create workspace: `azure-policy-github-runner`
   - Choose "Version Control Workflow" and connect to your GitHub repo

2. **Configure Environment Variables** (in Terraform Cloud workspace):
   - `ARM_CLIENT_ID` = "your-service-principal-id"
   - `ARM_CLIENT_SECRET` = "your-service-principal-secret" (sensitive)
   - `ARM_SUBSCRIPTION_ID` = "your-subscription-id"
   - `ARM_TENANT_ID` = "your-tenant-id"
   - `TF_VAR_github_token` = "ghp_your_github_token" (sensitive)

3. **Local Setup**:
   ```bash
   # Login to Terraform Cloud
   terraform login

   # Initialize with remote backend
   terraform init
   ```

### **2. Alternative: Local Setup**
```bash
cd infrastructure/github-runner
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
vim terraform.tfvars
```

### **3. Deploy Infrastructure**
```bash
terraform init
terraform plan
terraform apply
```

### **4. Verify Deployment**
```bash
# Check outputs
terraform output

# Verify runner registration in GitHub
# Go to: Repository → Settings → Actions → Runners
# You should see your runner listed as "Idle"

# Test SSH access (if SSH key configured)
ssh -i ~/.ssh/github-runner-key azureuser@$(terraform output -raw vm_public_ip)
```

## 🔧 **Configuration Options**

### **VM Sizing**
| Size | vCPUs | RAM | Cost/Month | Use Case |
|------|-------|-----|------------|----------|
| `Standard_B1s` | 1 | 1GB | ~$8 | Light workloads |
| `Standard_B2s` | 2 | 4GB | ~$30 | **Recommended** |
| `Standard_D2s_v3` | 2 | 8GB | ~$70 | Heavy builds |

### **Runner Labels**
Customize labels to control which workflows run on your runner:
```hcl
runner_labels = [
  "azure",           # Identifies Azure-hosted runner
  "vnet",           # Has VNet access
  "ubuntu",         # Ubuntu OS
  "self-hosted",    # Self-hosted runner
  "functions",      # Can deploy Functions
  "secure"          # Security-compliant
]
```

Use in workflows:
```yaml
runs-on: [self-hosted, azure, vnet, functions]
```

### **Auto-Shutdown**
Save money by automatically shutting down the VM:
```hcl
auto_shutdown_time = "23:00"  # Shutdown at 11 PM UTC daily
```

**Cost Savings**: ~70% reduction if running 8 hours/day vs 24/7

## 📊 **GitHub IP Ranges**

The configuration automatically fetches and applies GitHub's current IP ranges:

```json
{
  "actions": [
    "13.64.0.0/16",
    "13.65.0.0/16",
    // ... more IPs
  ],
  "hooks": [
    "192.30.252.0/22",
    "185.199.108.0/22",
    // ... more IPs
  ]
}
```

**Auto-Updates**: IP ranges are fetched during `terraform plan/apply`, so they stay current.

## 🌐 **Terraform Cloud Troubleshooting**

### **Common Issues**

1. **Authentication Errors**:
   ```bash
   # Ensure you're logged in
   terraform login

   # Check workspace exists
   terraform workspace list
   ```

2. **Environment Variable Issues**:
   - Verify `TF_VAR_github_token` is set as **sensitive** in Terraform Cloud
   - Check Azure environment variables are set correctly
   - Variable names must match exactly (case-sensitive)

3. **Backend Configuration**:
   ```bash
   # Re-initialize if backend changes
   rm -rf .terraform
   terraform init
   ```

4. **GitHub Token Validation**:
   ```bash
   # Test token locally (never commit this!)
   curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/user
   ```

## 🔍 **Monitoring & Troubleshooting**

### **Check Runner Status**
```bash
# SSH to runner
ssh azureuser@<public-ip>

# Check runner service
sudo systemctl status actions.runner.*

# View runner logs
sudo journalctl -u actions.runner.* -f
```

### **Test GitHub Connectivity**
```bash
# From runner VM
curl -I https://api.github.com
curl -I https://github.com

# Test runner registration
cd /home/actions-runner/actions-runner
sudo -u actions-runner ./run.sh --check
```

### **Network Connectivity Test**
```bash
# Test Function App access from runner
curl -I https://func-azpolicy-dev-001.azurewebsites.net
curl -I https://func-azpolicy-dev-001.scm.azurewebsites.net  # Should work from VNet
```

## 🎯 **Workflow Integration**

Update your GitHub Actions workflows to use the new runner:

```yaml
name: Deploy Function App

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest  # Use GitHub-hosted for build
    steps:
      - uses: actions/checkout@v4
      - name: Build and test
        run: |
          # Build/test steps that don't need VNet access

  deploy:
    needs: build
    runs-on: [self-hosted, azure, vnet]  # Use your runner for deploy
    steps:
      - name: Deploy to Function App
        run: |
          # Deployment steps that need VNet access
          az functionapp deployment source config-zip \
            --name func-azpolicy-dev-001 \
            --src function.zip
```

## 🔒 **Security Best Practices**

### **SSH Key Management**
```bash
# Use strong SSH keys
ssh-keygen -t ed25519 -C "github-runner@yourcompany.com"

# Restrict SSH key usage
echo 'command="echo Access restricted",no-port-forwarding,no-agent-forwarding,no-X11-forwarding' >> ~/.ssh/authorized_keys
```

### **GitHub Token Security**
- Use fine-grained personal access tokens
- Set minimal required scopes
- Rotate tokens regularly
- Store in Terraform variables (marked sensitive)

### **Network Security**
- NSG rules automatically restrict access to GitHub IPs only
- No inbound ports open except SSH (22) from allowed IPs
- VM is in private subnet but has public IP for GitHub access

## 💰 **Cost Analysis**

### **Monthly Costs** (East US pricing):
| Component | Cost |
|-----------|------|
| Standard_B2s VM | ~$30 |
| Public IP (Standard) | ~$4 |
| Storage (Premium SSD) | ~$2 |
| **Total** | **~$36/month** |

### **Cost Optimization**:
- **Auto-shutdown**: Save ~70% if only needed during work hours
- **Spot instances**: Save up to 90% (with interruption risk)
- **Smaller VM**: Use B1s for light workloads (~$8/month)

## 🚨 **Common Issues**

### **Runner Not Appearing in GitHub**
1. Check GitHub token permissions
2. Verify token hasn't expired
3. Check VM startup logs: `sudo cloud-init logs`

### **SSH Access Denied**
1. Verify your IP is in GitHub's ranges or `allowed_management_ips`
2. Check NSG rules: `az network nsg rule list`
3. Verify SSH key is correct

### **Function Deployment Fails**
1. Test SCM connectivity from runner
2. Verify VNet integration is working
3. Check Function App access policies

## 🎯 **Next Steps**

1. **Deploy**: Follow the Quick Start guide
2. **Test**: Run a workflow to verify VNet access works
3. **Monitor**: Set up monitoring for the VM and runner
4. **Scale**: Add more runners to different regions if needed
5. **Secure**: Review and customize NSG rules for your environment

This configuration provides the perfect balance of **security**, **accessibility**, and **cost-effectiveness** for your GitHub Actions workflows with Azure Function deployment! 🎉

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.39 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.39.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_dev_test_global_vm_shutdown_schedule.github_runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dev_test_global_vm_shutdown_schedule) | resource |
| [azurerm_linux_virtual_machine.github_runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | resource |
| [azurerm_network_interface.github_runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.github_runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subnet.runner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/virtual_network) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_ssh_public_key"></a> [admin\_ssh\_public\_key](#input\_admin\_ssh\_public\_key) | SSH public key for VM access (leave empty to disable SSH key auth) | `string` | `""` | no |
| <a name="input_allowed_management_ips"></a> [allowed\_management\_ips](#input\_allowed\_management\_ips) | Additional IP addresses allowed for SSH management (besides GitHub IPs) | `list(string)` | `[]` | no |
| <a name="input_auto_shutdown_time"></a> [auto\_shutdown\_time](#input\_auto\_shutdown\_time) | Time to auto-shutdown VM (HH:MM format, e.g., '23:00' for 11 PM) | `string` | `""` | no |
| <a name="input_enable_accelerated_networking"></a> [enable\_accelerated\_networking](#input\_enable\_accelerated\_networking) | Enable accelerated networking for the VM | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_github_repo_url"></a> [github\_repo\_url](#input\_github\_repo\_url) | GitHub repository URL | `string` | `"https://github.com/stuartshay/azure-policy"` | no |
| <a name="input_github_token"></a> [github\_token](#input\_github\_token) | GitHub Personal Access Token for runner registration | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group | `string` | `"rg-azpolicy-dev-eastus"` | no |
| <a name="input_runner_labels"></a> [runner\_labels](#input\_runner\_labels) | Labels to assign to the GitHub runner | `list(string)` | <pre>[<br/>  "azure",<br/>  "vnet",<br/>  "ubuntu",<br/>  "self-hosted"<br/>]</pre> | no |
| <a name="input_subscription_id"></a> [subscription\_id](#input\_subscription\_id) | Azure subscription ID | `string` | n/a | yes |
| <a name="input_vm_size"></a> [vm\_size](#input\_vm\_size) | Size of the GitHub runner VM | `string` | `"Standard_B2s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_nsg_id"></a> [nsg\_id](#output\_nsg\_id) | ID of the Network Security Group |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group containing the GitHub runner |
| <a name="output_vm_id"></a> [vm\_id](#output\_vm\_id) | ID of the GitHub runner VM |
| <a name="output_vm_name"></a> [vm\_name](#output\_vm\_name) | Name of the GitHub runner VM |
| <a name="output_vm_private_ip"></a> [vm\_private\_ip](#output\_vm\_private\_ip) | Private IP address of the GitHub runner VM |
| <a name="output_vm_public_ip"></a> [vm\_public\_ip](#output\_vm\_public\_ip) | Public IP address of the GitHub runner VM |
<!-- END_TF_DOCS -->
