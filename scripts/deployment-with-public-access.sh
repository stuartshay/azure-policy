#!/bin/bash
# Automated deployment with temporary public access
# This script enables public access, deploys, then re-secures the Function App

set -e

RESOURCE_GROUP="rg-azpolicy-dev-eastus"
FUNCTION_APP="func-azpolicy-dev-001"
DEPLOYMENT_PACKAGE="../functions/basic"

echo "🔓 Temporarily enabling public network access for deployment..."

# Enable public access
az functionapp update \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP \
  --set publicNetworkAccessEnabled=true

echo "⏳ Waiting for configuration to take effect..."
sleep 30

# Verify access is enabled
PUBLIC_ACCESS=$(az functionapp show \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP \
  --query "publicNetworkAccessEnabled" -o tsv)

if [ "$PUBLIC_ACCESS" != "true" ]; then
  echo "❌ Failed to enable public access"
  exit 1
fi

echo "✅ Public access enabled. Testing SCM connectivity..."
SCM_URL="https://$FUNCTION_APP.scm.azurewebsites.net"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SCM_URL" --max-time 10 || echo "000")
echo "SCM Status: $HTTP_STATUS"

if [ "$HTTP_STATUS" != "200" ] && [ "$HTTP_STATUS" != "401" ]; then
  echo "⚠️ SCM still not accessible. Continuing with deployment attempt..."
fi

echo "🚀 Starting deployment..."

# Create deployment package
cd $DEPLOYMENT_PACKAGE
zip -r ../function-deploy.zip . -x "tests/*" "*/__pycache__/*" "*.pyc"

# Deploy using Azure CLI
az functionapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP \
  --src ../function-deploy.zip \
  --build-remote true

echo "✅ Deployment completed successfully!"

echo "🔒 Re-securing Function App by disabling public access..."

# Disable public access to restore security
az functionapp update \
  --resource-group $RESOURCE_GROUP \
  --name $FUNCTION_APP \
  --set publicNetworkAccessEnabled=false

echo "✅ Function App secured. Deployment complete!"

# Clean up
rm -f ../function-deploy.zip

echo "🎯 Summary:"
echo "   ✅ Deployment successful"
echo "   ✅ Security restored"
echo "   ✅ Function App accessible only via VNet"
