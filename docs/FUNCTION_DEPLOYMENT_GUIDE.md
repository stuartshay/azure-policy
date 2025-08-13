# Azure Function Deployment Guide

This guide covers the complete process for deploying Azure Functions from the `functions/basic` directory using both local testing and GitHub Actions CI/CD.

## Overview

The deployment process consists of:
1. **Local Testing** - Test the function locally before deployment
2. **GitHub Actions CI/CD** - Automated deployment pipeline
3. **Infrastructure** - Azure resources (already deployed)

## Prerequisites

### Required Tools
- **Azure CLI** - For Azure authentication and resource management
- **Azure Functions Core Tools v4** - For local function development
- **Python 3.11** - Runtime for the functions
- **Git** - Version control

### Azure Resources (Already Deployed)
- ✅ **Function App**: `func-azpolicy-dev-001`
- ✅ **App Service Plan**: `asp-azpolicy-functions-dev-001` (EP1 SKU)
- ✅ **Storage Account**: `stfuncazpolicydev001`
- ✅ **Application Insights**: `appi-azpolicy-functions-dev-001`
- ✅ **Resource Group**: `rg-azpolicy-dev-eastus`

### GitHub Secrets (Required for CI/CD)
- ✅ **AZURE_CREDENTIALS** - Service principal credentials (already configured)

## Part 1: Local Testing

### Step 1: Run the Local Testing Script

The project includes an automated testing script that sets up the environment and tests all endpoints:

```bash
# Make the script executable (if not already done)
chmod +x scripts/test-function-local.sh

# Run the local testing script
./scripts/test-function-local.sh
```

This script will:
- ✅ Check prerequisites (Python, Azure Functions Core Tools)
- ✅ Create Python virtual environment
- ✅ Install dependencies
- ✅ Create `local.settings.json`
- ✅ Run unit tests
- ✅ Start the function locally
- ✅ Test all endpoints (health, info, hello)
- ✅ Test both GET and POST requests
- ✅ Clean up resources

### Step 2: Manual Local Testing (Optional)

If you prefer to test manually:

```bash
# Navigate to function directory
cd functions/basic

# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create local.settings.json (if not exists)
cp local.settings.json.template local.settings.json

# Start the function
func start --port 7071
```

Test the endpoints:
```bash
# Health check
curl http://localhost:7071/api/health

# Info endpoint
curl http://localhost:7071/api/info

# Hello endpoint
curl "http://localhost:7071/api/hello?name=LocalTest"

# POST request
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"name": "LocalTestPOST"}' \
  http://localhost:7071/api/hello
```

## Part 2: GitHub Actions Deployment

### Workflow Configuration

The GitHub Actions workflow (`.github/workflows/deploy-function.yml`) is configured with:

#### Environment Variables
```yaml
env:
  AZURE_FUNCTIONAPP_NAME: func-azpolicy-dev-001
  AZURE_FUNCTIONAPP_PACKAGE_PATH: './functions/basic'
  PYTHON_VERSION: '3.11'
```

#### Workflow Triggers
- **Push to main branch** with changes to `functions/basic/**`
- **Pull requests** to main branch (build and test only)
- **Manual dispatch** (workflow_dispatch)

### Deployment Process

The workflow consists of three jobs:

#### 1. Build and Test Job
- ✅ Checkout code
- ✅ Setup Python 3.11
- ✅ Install dependencies
- ✅ Run unit tests with coverage
- ✅ Package function (remove test files and cache)
- ✅ Upload artifact

#### 2. Deploy Job (main branch only)
- ✅ Download function package
- ✅ Azure login using `AZURE_CREDENTIALS`
- ✅ Deploy to Azure Function App
- ✅ Verify deployment

#### 3. Test Deployment Job
- ✅ Test deployed function endpoints
- ✅ Verify function is responding correctly

### Triggering Deployment

#### Automatic Deployment
Push changes to the main branch:
```bash
git add .
git commit -m "Update function code"
git push origin main
```

#### Manual Deployment
1. Go to GitHub repository
2. Navigate to **Actions** tab
3. Select **Deploy Azure Function** workflow
4. Click **Run workflow**
5. Select branch and click **Run workflow**

## Part 3: Monitoring and Verification

### Check Deployment Status

#### Via GitHub Actions
1. Go to **Actions** tab in GitHub
2. Click on the latest workflow run
3. Monitor the progress of each job

#### Via Azure CLI
```bash
# Check function app status
az functionapp show \
  --name func-azpolicy-dev-001 \
  --resource-group rg-azpolicy-dev-eastus \
  --query "{name:name, state:state, kind:kind}"

# List function endpoints
az functionapp function list \
  --name func-azpolicy-dev-001 \
  --resource-group rg-azpolicy-dev-eastus \
  --query "[].{name:name, triggerType:config.bindings[0].type}"
```

#### Via Azure Portal
1. Navigate to the Function App: `func-azpolicy-dev-001`
2. Check **Functions** section for deployed functions
3. Monitor **Application Insights** for logs and metrics

### Testing Deployed Function

Since the function app has VNet integration and public access disabled, testing requires Azure CLI:

```bash
# Get function key
FUNCTION_KEY=$(az functionapp keys list \
  --name func-azpolicy-dev-001 \
  --resource-group rg-azpolicy-dev-eastus \
  --query "functionKeys.default" -o tsv)

# Test endpoints (if accessible)
BASE_URL="https://func-azpolicy-dev-001.azurewebsites.net"

# Test health endpoint
curl -f "$BASE_URL/api/health?code=$FUNCTION_KEY"

# Test hello endpoint
curl -f "$BASE_URL/api/hello?code=$FUNCTION_KEY&name=Production"
```

## Function Endpoints

The deployed function includes three endpoints:

### 1. Health Check
- **Path**: `/api/health`
- **Method**: GET
- **Purpose**: Health monitoring and diagnostics
- **Response**: JSON with health status and timestamp

### 2. Hello World
- **Path**: `/api/hello`
- **Methods**: GET, POST
- **Parameters**: `name` (optional)
- **Purpose**: Main function endpoint
- **Response**: JSON greeting with metadata

### 3. Info
- **Path**: `/api/info`
- **Method**: GET
- **Purpose**: Function app information and available endpoints
- **Response**: JSON with function details and endpoint documentation

## Troubleshooting

### Common Issues

#### 1. Local Testing Fails
```bash
# Check Azure Functions Core Tools version
func --version

# Reinstall if needed
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

#### 2. GitHub Actions Deployment Fails
- Verify `AZURE_CREDENTIALS` secret is correctly configured
- Check Azure CLI authentication in workflow logs
- Ensure Function App exists and is accessible

#### 3. Function Not Responding
- Check Application Insights logs
- Verify function app is running
- Check VNet integration settings

### Logs and Monitoring

#### Application Insights
```bash
# Query Application Insights logs
az monitor app-insights query \
  --app appi-azpolicy-functions-dev-001 \
  --analytics-query "requests | limit 10"
```

#### Function App Logs
```bash
# Stream function logs
az webapp log tail \
  --name func-azpolicy-dev-001 \
  --resource-group rg-azpolicy-dev-eastus
```

## Security Considerations

### Network Security
- ✅ **VNet Integration**: Function app is integrated with private subnet
- ✅ **Public Access Disabled**: Direct internet access is blocked
- ✅ **HTTPS Only**: All traffic is encrypted
- ✅ **TLS 1.2**: Minimum TLS version enforced

### Authentication
- ✅ **Function Keys**: Required for endpoint access
- ✅ **Azure AD Integration**: Available for additional security
- ✅ **Managed Identity**: Can be enabled for Azure resource access

## Next Steps

1. **Add More Functions**: Extend the function app with additional endpoints
2. **Environment Variables**: Configure environment-specific settings
3. **Monitoring**: Set up alerts and dashboards in Application Insights
4. **Security**: Implement Azure AD authentication if needed
5. **Performance**: Monitor and optimize function performance

## Resources

- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [GitHub Actions for Azure](https://docs.microsoft.com/en-us/azure/developer/github/github-actions)
- [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
- [Application Insights](https://docs.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
