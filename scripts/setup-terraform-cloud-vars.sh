#!/bin/bash

# Setup Terraform Cloud Variables Script
# This script helps configure Azure credentials in Terraform Cloud workspaces

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables from .env
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please copy .env.template to .env and add your credentials"
    exit 1
fi

echo -e "${GREEN}Terraform Cloud Variable Setup${NC}"
echo -e "${YELLOW}================================${NC}"
echo ""
echo "This script will help you configure Azure credentials in Terraform Cloud."
echo ""
echo -e "${BLUE}Your configuration:${NC}"
echo "  Organization: $TF_CLOUD_ORGANIZATION"
echo "  ARM Client ID: ${ARM_CLIENT_ID:0:8}..."
echo "  ARM Tenant ID: ${ARM_TENANT_ID:0:8}..."
echo "  Subscription ID: ${ARM_SUBSCRIPTION_ID:0:8}..."
echo ""
echo -e "${YELLOW}To configure these variables in Terraform Cloud:${NC}"
echo ""
echo "1. Go to: https://app.terraform.io/app/${TF_CLOUD_ORGANIZATION}/workspaces"
echo ""
echo "2. For each workspace (core, functions, policies), add these variables:"
echo ""
echo -e "${GREEN}Environment Variables (mark as 'Environment variable'):${NC}"
echo "   ARM_CLIENT_ID = $ARM_CLIENT_ID"
echo "   ARM_CLIENT_SECRET = [mark as sensitive] = $ARM_CLIENT_SECRET"
echo "   ARM_SUBSCRIPTION_ID = $ARM_SUBSCRIPTION_ID"
echo "   ARM_TENANT_ID = $ARM_TENANT_ID"
echo ""
echo -e "${GREEN}Terraform Variables (mark as 'Terraform variable'):${NC}"
echo "   subscription_id = $ARM_SUBSCRIPTION_ID"
echo ""
echo -e "${YELLOW}Steps for each workspace:${NC}"
echo "1. Click on the workspace name"
echo "2. Go to 'Variables' in the left menu"
echo "3. Click 'Add variable'"
echo "4. Add each variable listed above"
echo "5. For ARM_CLIENT_SECRET, check 'Sensitive' box"
echo ""
echo -e "${BLUE}Workspaces to configure:${NC}"
echo "  - azure-policy-core"
echo "  - azure-policy-functions"
echo "  - azure-policy-policies"
echo ""
echo -e "${GREEN}Once configured, you can run:${NC}"
echo "  make terraform-core-plan"
echo "  make terraform-functions-plan"
echo "  make terraform-policies-plan"
