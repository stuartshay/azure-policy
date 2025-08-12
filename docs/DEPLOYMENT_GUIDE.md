# Azure Functions EP1 Deployment Guide

This guide explains how to deploy the Azure Functions infrastructure with EP1 (Elastic Premium) App Service Plan and VNet integration.

## Overview

The functions infrastructure has been updated to use:
- **EP1 SKU** instead of the default Y1 (Consumption) plan
- **VNet Integration** for secure network connectivity
- **EP1-specific optimizations** for performance and scaling

## Prerequisites

1. **Core Infrastructure**: The core infrastructure must be deployed first as it provides:
   - Resource Group
   - Virtual Network (VNet)
   - Functions subnet with proper delegation
   - Network Security Groups

2. **Environment Variables**: Ensure your `.env` file contains:
   - `TF_API_TOKEN` - Terraform Cloud API token
   - `ARM_SUBSCRIPTION_ID` - Azure subscription ID
   - Other required Azure credentials

## Deployment Steps

### Step 1: Update Core Infrastructure (if needed)

The core infrastructure has been updated to include a functions subnet. If your core infrastructure is already deployed, you'll need to update it:

```bash
# Navigate to core infrastructure
cd infrastructure/core

# Plan the changes (adds functions subnet)
make plan

# Apply the changes
make apply
```

### Step 2: Deploy Functions Infrastructure

```bash
# Navigate to functions infrastructure
cd infrastructure/functions

# Initialize Terraform
make init

# Plan the deployment
make plan

# Apply the changes
make apply
```

## Key Configuration Changes

### 1. EP1 App Service Plan
- **SKU**: Changed from "Y1" to "EP1"
- **Maximum Elastic Workers**: 3 (configurable)
- **Always Ready Instances**: 1 (configurable)

### 2. VNet Integration
- **Subnet**: Uses dedicated functions subnet with delegation
- **Network Access**: Private when VNet integrated
- **Route All Traffic**: Enabled for VNet routing

### 3. Function App Optimizations
- **Always On**: Enabled for EP1
- **Pre-warmed Instances**: Configured for faster cold starts
- **Elastic Instance Minimum**: Set to always ready instances

## Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Virtual Network (10.0.0.0/16)                              │
│                                                             │
│ ┌─────────────────────┐  ┌─────────────────────────────────┐ │
│ │ Default Subnet      │  │ Functions Subnet                │ │
│ │ 10.0.1.0/24         │  │ 10.0.2.0/24                     │ │
│ │                     │  │ - Delegated to serverFarms      │ │
│ │                     │  │ - Service Endpoints enabled     │ │
│ └─────────────────────┘  │ - Function App integrated       │ │
│                          └─────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Private Endpoints Subnet                                │ │
│ │ 10.0.4.0/24                                             │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Variables Reference

### Core Variables
- `functions_sku_name`: "EP1" (default)
- `enable_vnet_integration`: true (default)
- `enable_application_insights`: true (default)

### EP1 Specific Variables
- `always_ready_instances`: 1 (default, range: 0-20)
- `maximum_elastic_worker_count`: 3 (default, range: 1-20)

### Network Variables
- `vnet_integration_subnet_id`: Auto-detected from core infrastructure
- `location`: "East US" (default)

## Monitoring and Observability

The deployment includes:
- **Application Insights** for telemetry and monitoring
- **Function App logs** accessible through Azure Portal
- **VNet flow logs** for network monitoring (from core infrastructure)

## Security Features

- **HTTPS Only**: All traffic encrypted
- **Private Network Access**: When VNet integrated
- **Storage Account Security**: TLS 1.2 minimum, private access
- **Network Security Groups**: Applied to all subnets

## Cost Considerations

EP1 plan provides:
- **Dedicated compute**: No cold starts after warm-up
- **Predictable performance**: Consistent execution times
- **Higher cost**: More expensive than Consumption plan
- **Elastic scaling**: Pay for what you use within limits

## Troubleshooting

### Common Issues

1. **Subnet Not Found**: Ensure core infrastructure is deployed with functions subnet
2. **VNet Integration Failed**: Check subnet delegation and NSG rules
3. **Function App Not Starting**: Verify storage account connectivity

### Validation Commands

```bash
# Validate Terraform configuration
terraform validate

# Check resource status
az functionapp show --name func-azpolicy-dev-001 --resource-group rg-azpolicy-dev-eastus

# Test VNet connectivity
az functionapp show --name func-azpolicy-dev-001 --resource-group rg-azpolicy-dev-eastus --query "virtualNetworkSubnetId"
```

## Next Steps

After deployment:
1. Deploy your function code using Azure Functions Core Tools or VS Code
2. Configure any additional app settings required by your functions
3. Set up monitoring alerts in Application Insights
4. Configure CI/CD pipelines for automated deployments

## Makefile Commands

The project includes convenient Makefile commands:

```bash
# Functions-specific commands
make terraform-functions-init    # Initialize functions workspace
make terraform-functions-plan    # Plan functions changes
make terraform-functions-apply   # Apply functions changes
make terraform-functions-destroy # Destroy functions resources

# All workspaces
make terraform-all-init         # Initialize all workspaces
make terraform-all-plan         # Plan all workspaces
