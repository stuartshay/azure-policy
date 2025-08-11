# Publishing Networking Module to Terraform Cloud Private Module Registry

This guide walks through publishing the `networking` module to Terraform Cloud Private Module Registry.

## Prerequisites

✅ Module is ready:
- Located at: `infrastructure/terraform/modules/networking/`
- Comprehensive documentation in README.md
- Git repository with tags (v0.1.0 created)
- All files committed and pushed to GitHub

✅ Terraform Cloud setup:
- Organization: `azure-policy-cloud`
- Authentication configured via `.env` file
- Workspace permissions for module management

## Step 1: Access Terraform Cloud Registry

1. **Login to Terraform Cloud**: https://app.terraform.io
2. **Navigate to your organization**: `azure-policy-cloud`
3. **Go to Registry**: Click "Registry" in the left navigation menu

## Step 2: Publish the Module

### Option A: Via Terraform Cloud UI (Recommended)

1. **Click "Publish" > "Module"**

2. **Connect Repository**:
   - Choose "GitHub" (or your VCS provider)
   - If not connected, authorize Terraform Cloud to access your GitHub repositories
   - Select repository: `stuartshay/azure-policy`

3. **Configure Module**:
   - **Module Name**: `networking`
   - **Provider**: `azurerm`
   - **Module Source**: Select the repository: `stuartshay/azure-policy`
   - **Module Directory**: `infrastructure/terraform/modules/networking`
   - **Tag-based**: Select "Yes" to use Git tags for versioning

4. **Publish Settings**:
   - **Initial Version**: `0.1.0` (matches our Git tag)
   - **Description**: "Azure networking module with VNet, subnets, NSGs, and optional Network Watcher"

5. **Review and Publish**:
   - Review the configuration
   - Click "Publish module"

### Option B: Via Terraform API (Advanced)

If you need to automate the process, you can use the Terraform Cloud API:

```bash
# Set your API token
export TF_TOKEN="your-token-here"

# Create module via API
curl \
  --header "Authorization: Bearer $TF_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{
    "data": {
      "type": "registry-modules",
      "attributes": {
        "vcs-repo": {
          "identifier": "stuartshay/azure-policy",
          "oauth-token-id": "your-oauth-token-id",
          "display_identifier": "stuartshay/azure-policy"
        },
        "module-directory": "infrastructure/terraform/modules/networking"
      }
    }
  }' \
  https://app.terraform.io/api/v2/organizations/azure-policy-cloud/registry-modules
```

## Step 3: Verify Publication

1. **Check Registry**: Navigate to Registry > Modules in your Terraform Cloud organization
2. **Verify Module**: You should see `azure-policy-cloud/networking/azurerm`
3. **Check Version**: Confirm version `0.1.0` is available
4. **Test Documentation**: Verify that README.md content appears correctly

## Step 4: Update Core Configuration

Once the module is published, update the core infrastructure to use the registry:

1. **Edit `infrastructure/core/main.tf`**:

```hcl
# Networking Module
module "networking" {
  # Terraform Cloud Private Module Registry source
  source  = "azure-policy-cloud/networking/azurerm"
  version = "0.1.0"

  # Remove the GitHub source:
  # source = "github.com/stuartshay/azure-policy//infrastructure/terraform/modules/networking?ref=40bee534c1b346bf93af0deff784aa069af4e3d3"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # ... rest of configuration
}
```

2. **Test the changes**:

```bash
# Clean and reinitialize
cd infrastructure/core
rm -rf .terraform .terraform.lock.hcl
make init

# Test plan
make plan
```

## Step 5: Future Updates

To publish new versions:

1. **Make changes** to the module in `infrastructure/terraform/modules/networking/`
2. **Commit changes** to Git
3. **Create new tag**: `git tag -a v0.1.1 -m "Description of changes"`
4. **Push tag**: `git push origin v0.1.1`
5. **Terraform Cloud auto-detects** the new tag and publishes the new version

## Module Usage

After publishing, other teams can use your module:

```hcl
module "networking" {
  source  = "azure-policy-cloud/networking/azurerm"
  version = "~> 0.1.0"

  resource_group_name = "rg-example"
  location           = "East US"
  environment        = "dev"
  workload           = "myapp"
  location_short     = "eastus"

  vnet_address_space = ["10.0.0.0/16"]
  subnet_config = {
    default = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = []
    }
    functions = {
      address_prefixes  = ["10.0.3.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
  }

  enable_network_watcher = true
  enable_flow_logs       = true

  tags = {
    Environment = "dev"
    Project     = "myproject"
  }
}
```

## Benefits of Using Private Module Registry

- **Version Control**: Semantic versioning with Git tags
- **Documentation**: Automatic documentation generation from README.md
- **Collaboration**: Easy sharing across teams and workspaces
- **Dependency Management**: Terraform handles module downloads and caching
- **Security**: Private modules only accessible to your organization
- **Governance**: Centralized control over infrastructure patterns

## Troubleshooting

### Module Not Found
- Verify repository connection in Terraform Cloud
- Check module directory path is correct
- Ensure Git tag exists and is pushed to GitHub

### Version Issues
- Confirm Git tag format matches semantic versioning (v0.1.0)
- Check that the tag exists in GitHub: `git tag -l`
- Wait a few minutes for Terraform Cloud to process new tags

### Permission Issues
- Verify you have module management permissions in the organization
- Check VCS connection is working in Terraform Cloud settings

## Next Steps

1. **Publish the module** following Step 2 above
2. **Update core configuration** as shown in Step 4
3. **Test the registry source** with `make terraform-core-plan`
4. **Create more modules** for functions and policies using the same pattern

---

**Note**: The actual publishing must be done through the Terraform Cloud UI or API. This guide provides the steps, but the action requires manual intervention in the web interface.
