# Azure Policy Infrastructure

This directory contains the Terraform infrastructure code for the Azure Policy project, providing a complete infrastructure-as-code solution for deploying Azure resources with GitHub Actions automation.

## 🏗️ Architecture Overview

The infrastructure creates the following Azure resources:

- **Resource Group**: Single resource group per environment
- **Virtual Network**: VNet with multiple subnets for different purposes
- **Network Security Groups**: Security rules for each subnet
- **App Service Plan**: Hosting platform for Function Apps
- **Function Apps**: Azure Functions for policy processing
- **Storage Account**: Backend storage for Function Apps
- **Application Insights**: Monitoring and telemetry
- **Key Vault**: Secrets management (optional)
- **Azure Policies**: Custom policy definitions and assignments

## 📁 Project Structure

```
infrastructure/
├── terraform/
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── terraform.tfvars.example   # Example variable values
│   └── modules/
│       ├── networking/            # VNet, subnets, NSGs
│       ├── app-service/           # App Service Plan, Function Apps
│       └── policies/              # Azure Policy definitions
├── .github/workflows/
│   ├── terraform-validate.yml     # Validation workflow
│   ├── terraform-apply.yml        # Deployment workflow
│   └── terraform-destroy.yml      # Destruction workflow
└── README.md                      # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Azure Subscription**: Active Azure subscription with appropriate permissions
2. **Azure CLI**: Installed and configured (available via `install.sh`)
3. **PowerShell**: Installed and available (via `install.sh`)
4. **Pre-commit**: Installed for code quality checks (via `install.sh`)
5. **Terraform**: Version 1.5 or later
6. **GitHub Repository**: With Actions enabled

### Initial Setup

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd azure-policy
   ```

2. **Run the installation script** (installs all required tools):

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **Configure Azure credentials**:

   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

4. **Navigate to infrastructure directory**:

   ```bash
   cd infrastructure
   ```

5. **Create Terraform backend storage**:

   ```bash
   # Create resource group for Terraform state
   az group create --name rg-terraform-state-dev-eastus --location "East US"

   # Create storage account
   az storage account create \
     --name stterraformstatedev001 \
     --resource-group rg-terraform-state-dev-eastus \
     --location "East US" \
     --sku Standard_LRS

   # Create container
   az storage container create \
     --name tfstate \
     --account-name stterraformstatedev001
   ```

4. **Configure GitHub Secrets**:
   Add the following secrets to your GitHub repository:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_CREDENTIALS` (JSON format for Azure login action)

### Local Development

1. **Copy example variables**:

   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

2. **Edit variables** to match your environment:

   ```bash
   # Use your preferred editor
   nano terraform/terraform.tfvars
   # or
   code terraform/terraform.tfvars
   ```

3. **Initialize Terraform**:

   ```bash
   cd terraform
   terraform init
   ```

4. **Validate configuration**:

   ```bash
   terraform validate
   terraform fmt -check
   ```

5. **Plan deployment**:

   ```bash
   terraform plan
   ```

6. **Apply changes**:

   ```bash
   terraform apply
   ```

### Code Quality and Pre-commit

The project includes pre-commit hooks for maintaining code quality:

```bash
# Pre-commit hooks run automatically on git commit
git add .
git commit -m "feat: add new infrastructure component"

# Run pre-commit manually on all files
pre-commit run --all-files

# Update pre-commit hooks
pre-commit autoupdate
```

**Available hooks:**
- **Terraform**: Format checking, validation
- **PowerShell**: PSScriptAnalyzer for script quality
- **Python**: black, isort, flake8, bandit
- **Shell**: shellcheck for bash scripts
- **Security**: detect-secrets, bandit
- **General**: trailing whitespace, file endings, JSON/YAML validation
- **Azure**: Policy JSON validation, Bicep validation

## 🔧 Configuration

### Environment Variables

The infrastructure supports multiple environments with different configurations:

| Environment | Location | Cost Center | Purpose |
|-------------|----------|-------------|---------|
| dev | East US | development | Development and testing |
| staging | East US 2 | operations | Pre-production testing |
| prod | East US | production | Live production environment |

### Key Configuration Options

#### Network Configuration

```hcl
# VNet address space
vnet_address_space = ["10.0.0.0/16"]

# Subnet configuration
subnet_config = {
  default = {
    address_prefixes = ["10.0.1.0/24"]
  }
  appservice = {
    address_prefixes = ["10.0.2.0/24"]
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
  }
  functions = {
    address_prefixes = ["10.0.3.0/24"]
  }
  privateendpoints = {
    address_prefixes = ["10.0.4.0/24"]
  }
}
```

#### App Service Configuration

```hcl
# App Service Plan SKU
app_service_plan_sku = "B1"  # Basic tier for development

# Function Apps
function_apps = {
  processor = {
    name_suffix = "processor"
    runtime_stack = "python"
    runtime_version = "3.11"
  }
  validator = {
    name_suffix = "validator"
    runtime_stack = "python"
    runtime_version = "3.11"
  }
}
```

#### Cost Management

```hcl
# Monthly budget in USD
budget_amount = 100

# Alert thresholds
budget_alert_thresholds = [50, 80, 100]
```

## 🔄 GitHub Actions Workflows

### Terraform Validate

**Trigger**: Pull requests and pushes to main branch
**Purpose**: Validates Terraform code, checks naming conventions, and runs security scans

```bash
# Manual trigger
gh workflow run terraform-validate.yml
```

### Terraform Apply

**Trigger**: Manual workflow dispatch
**Purpose**: Deploys infrastructure to specified environment

```bash
# Deploy to development
gh workflow run terraform-apply.yml -f environment=dev -f confirm=apply
```

### Terraform Destroy

**Trigger**: Manual workflow dispatch
**Purpose**: Destroys infrastructure in specified environment

```bash
# Destroy development environment
gh workflow run terraform-destroy.yml -f environment=dev -f confirm_destroy=destroy -f double_confirm=dev
```

## 🏷️ Naming Conventions

All resources follow Azure naming conventions:

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Resource Group | `rg-{workload}-{env}-{region}` | `rg-azurepolicy-dev-eastus` |
| Virtual Network | `vnet-{workload}-{env}-{region}-{instance}` | `vnet-azurepolicy-dev-eastus-001` |
| Subnet | `snet-{purpose}-{workload}-{env}-{region}-{instance}` | `snet-default-azurepolicy-dev-eastus-001` |
| NSG | `nsg-{workload}-{purpose}-{env}-{region}-{instance}` | `nsg-azurepolicy-default-dev-eastus-001` |
| Function App | `func-{workload}-{purpose}-{env}-{region}-{instance}` | `func-azurepolicy-processor-dev-eastus-001` |
| Storage Account | `st{workload}{env}{instance}` | `stazurepolicydev001` |

## 🏷️ Tagging Strategy

All resources are tagged with:

| Tag | Description | Example |
|-----|-------------|---------|
| Environment | Environment name | `dev`, `staging`, `prod` |
| CostCenter | Cost center for billing | `development`, `operations`, `production` |
| Project | Project name | `azurepolicy` |
| Owner | Resource owner | `platform-team` |
| CreatedBy | Creation method | `terraform` |
| CreatedDate | Creation date | `2025-01-27` |

## 🔒 Security

### Network Security

- Network Security Groups with restrictive rules
- Service endpoints for secure Azure service access
- Private endpoints for sensitive resources (optional)
- VNet integration for Function Apps

### Access Control

- Managed identities for Azure service authentication
- Key Vault for secrets management
- Least privilege access principles
- Environment-based access controls

### Monitoring

- Application Insights for application monitoring
- Diagnostic logs for all resources
- Security scanning with tfsec
- Cost monitoring and alerts

## 💰 Cost Management

### Development Environment

- Basic tier App Service Plan (~$13/month)
- Standard LRS storage (~$5/month)
- Application Insights (~$2/month)
- **Estimated total: ~$20/month**

### Cost Optimization Features

- Auto-shutdown for development resources
- Budget alerts at 50%, 80%, and 100%
- Cost monitoring workflows
- Resource tagging for cost allocation

## 🔧 Troubleshooting

### Common Issues

#### Terraform Backend Issues

```bash
# Reinitialize backend
terraform init -reconfigure

# Force unlock if needed
terraform force-unlock <lock-id>
```

#### Azure Authentication Issues

```bash
# Check current account
az account show

# Login again
az login

# Set correct subscription
az account set --subscription <subscription-id>
```

#### Resource Naming Conflicts

- Storage account names must be globally unique
- Add random suffix if conflicts occur
- Check existing resources in Azure Portal

#### Network Configuration Issues

- Verify subnet CIDR ranges don't overlap
- Check NSG rules for connectivity issues
- Validate service endpoint configurations

#### PowerShell Issues

```bash
# Check PowerShell installation
pwsh --version

# Install PSScriptAnalyzer module (for pre-commit)
pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser"

# Test PowerShell script analysis
pwsh -Command "Invoke-ScriptAnalyzer -Path scripts/ -Recurse"
```

#### Pre-commit Issues

```bash
# Reinstall pre-commit hooks
pre-commit uninstall
pre-commit install

# Skip hooks temporarily (not recommended)
git commit --no-verify -m "emergency commit"

# Update hooks to latest versions
pre-commit autoupdate

# Clear pre-commit cache
pre-commit clean
```

### Getting Help

1. **Check workflow logs** in GitHub Actions
2. **Review Terraform plan** output before applying
3. **Validate Azure permissions** for the service principal
4. **Check Azure service health** for regional issues
5. **Review resource quotas** in your subscription

## 📚 Additional Resources

- [Azure Naming Conventions](https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Policy Documentation](https://docs.microsoft.com/en-us/azure/governance/policy/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Create a feature branch
2. Make changes to Terraform code
3. Run validation locally: `terraform validate`
4. Create pull request
5. Automated validation will run
6. Deploy via GitHub Actions after approval

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
