#!/bin/bash

# Setup script for Azure Functions Advanced Timer
# This script helps configure the Service Bus connection string

set -e

echo "🚀 Azure Functions Advanced Timer - Setup Script"
echo "================================================"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first:"
    echo "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo "❌ Please log in to Azure CLI first:"
    echo "   az login"
    exit 1
fi

echo "✅ Azure CLI is available and you are logged in"

# Default values
RESOURCE_GROUP="rg-azpolicy-dev-eastus"
NAMESPACE_NAME="sb-azpolicy-dev-eastus-001"
AUTH_RULE_NAME="FunctionAppAccess"

echo ""
echo "📋 Configuration:"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Service Bus Namespace: $NAMESPACE_NAME"
echo "   Authorization Rule: $AUTH_RULE_NAME"
echo ""

# Get Service Bus connection string
echo "🔍 Retrieving Service Bus connection string..."

CONNECTION_STRING=$(az servicebus namespace authorization-rule keys list \
    --namespace-name "$NAMESPACE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AUTH_RULE_NAME" \
    --query "primaryConnectionString" \
    --output tsv 2>/dev/null)

if [ -z "$CONNECTION_STRING" ]; then
    echo "❌ Failed to retrieve connection string. Please check:"
    echo "   - Resource group exists: $RESOURCE_GROUP"
    echo "   - Service Bus namespace exists: $NAMESPACE_NAME"
    echo "   - Authorization rule exists: $AUTH_RULE_NAME"
    echo ""
    echo "💡 You can also get the connection string manually:"
    echo "   az servicebus namespace authorization-rule keys list \\"
    echo "     --namespace-name $NAMESPACE_NAME \\"
    echo "     --resource-group $RESOURCE_GROUP \\"
    echo "     --name $AUTH_RULE_NAME \\"
    echo "     --query primaryConnectionString \\"
    echo "     --output tsv"
    exit 1
fi

echo "✅ Connection string retrieved successfully"

# Update local.settings.json
if [ -f "local.settings.json" ]; then
    echo "🔧 Updating local.settings.json..."

    # Create backup
    cp local.settings.json local.settings.json.backup

    # Update connection string using jq if available
    if command -v jq &> /dev/null; then
        jq --arg conn_str "$CONNECTION_STRING" '.Values.ServiceBusConnectionString = $conn_str' local.settings.json > local.settings.json.tmp
        mv local.settings.json.tmp local.settings.json
        echo "✅ local.settings.json updated successfully"
    else
        echo "⚠️  jq not found. Please manually update local.settings.json with:"
        echo "   ServiceBusConnectionString: $CONNECTION_STRING"
    fi
else
    echo "📄 Creating local.settings.json from template..."
    if [ -f "local.settings.json.template" ]; then
        cp local.settings.json.template local.settings.json
        if command -v jq &> /dev/null; then
            jq --arg conn_str "$CONNECTION_STRING" '.Values.ServiceBusConnectionString = $conn_str' local.settings.json > local.settings.json.tmp
            mv local.settings.json.tmp local.settings.json
            echo "✅ local.settings.json created and configured"
        else
            echo "⚠️  jq not found. Please manually update local.settings.json with:"
            echo "   ServiceBusConnectionString: $CONNECTION_STRING"
        fi
    else
        echo "❌ local.settings.json.template not found"
        exit 1
    fi
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Install dependencies: pip install -r requirements.txt"
echo "   2. Start Azurite: azurite --silent --location azurite-data"
echo "   3. Start the function: func start"
echo ""
echo "🔗 Endpoints will be available at:"
echo "   - Health Check: http://localhost:7072/api/health"
echo "   - Service Bus Health: http://localhost:7072/api/health/servicebus"
echo "   - Function Info: http://localhost:7072/api/info"
echo "   - Send Test Message: http://localhost:7072/api/test/send-message"
echo ""
echo "⏰ The timer function will automatically start sending messages to the"
echo "   'policy-notifications' queue every 10 seconds once running."
