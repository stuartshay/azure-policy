#!/bin/bash

# Script: Policy Remediation
# Description: Demonstrates Azure Policy remediation capabilities
# Usage: ./08-remediation.sh

# Function to create a remediation example
create_remediation_example() {
    echo ""
    echo "🏗️  Creating Remediation Example"
    echo "==============================="

    # Use a simple tag policy for demonstration
    POLICY_NAME="add-environment-tag-to-rg"

    echo "Creating example policy: Add Environment tag to resource groups"

    # Create a simple modify policy
    cat > /tmp/modify-policy.json << 'EOF'
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Resources/resourceGroups"
        },
        {
          "field": "tags['Environment']",
          "exists": false
        }
      ]
    },
    "then": {
      "effect": "modify",
      "details": {
        "roleDefinitionIds": [
          "/subscriptions/{subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        ],
        "operations": [
          {
            "operation": "add",
            "field": "tags['Environment']",
            "value": "[parameters('tagValue')]"
          }
        ]
      }
    }
  },
  "parameters": {
    "tagValue": {
      "type": "String",
      "metadata": {
        "displayName": "Tag Value",
        "description": "Value of the Environment tag to add"
      },
      "allowedValues": [
        "Development",
        "Test",
        "Production"
      ],
      "defaultValue": "Development"
    }
  }
}
EOF

    # Create the policy definition
    echo "Creating policy definition..."
    POLICY_ID=$(az policy definition create \
        --name "$POLICY_NAME" \
        --display-name "Add Environment tag to resource groups" \
        --description "Adds an Environment tag to resource groups if it doesn't exist" \
        --rules /tmp/modify-policy.json \
        --mode All \
        --query "id" --output tsv)

    if [ $? -eq 0 ]; then
        echo "✅ Policy created: $POLICY_ID"

        # Get current subscription ID for role definition
        SUBSCRIPTION_ID=$(az account show --query id --output tsv)

        # Update the policy with correct subscription ID
        sed -i "s/{subscriptionId}/$SUBSCRIPTION_ID/g" /tmp/modify-policy.json

        az policy definition update \
            --name "$POLICY_NAME" \
            --rules /tmp/modify-policy.json

        echo "Creating policy assignment with managed identity..."

        # Create assignment with managed identity
        ASSIGNMENT_ID=$(az policy assignment create \
            --name "add-env-tag-assignment" \
            --display-name "Add Environment Tag to Resource Groups" \
            --policy "$POLICY_ID" \
            --assign-identity \
            --identity-scope "/subscriptions/$SUBSCRIPTION_ID" \
            --location "East US" \
            --params '{"tagValue": {"value": "Development"}}' \
            --query "id" --output tsv)

        if [ $? -eq 0 ]; then
            echo "✅ Assignment created: $ASSIGNMENT_ID"

            # Get the principal ID of the managed identity
            PRINCIPAL_ID=$(az policy assignment show \
                --name "add-env-tag-assignment" \
                --query "identity.principalId" --output tsv)

            echo "📋 Assignment Details:"
            echo "   Assignment ID: $ASSIGNMENT_ID"
            echo "   Principal ID: $PRINCIPAL_ID"
            echo ""

            # Note about permissions
            echo "⚠️  Important: The managed identity needs 'Contributor' role"
            echo "   to modify resource group tags. You may need to assign this manually:"
            echo "   az role assignment create --assignee $PRINCIPAL_ID --role Contributor"
            echo ""

            echo "✅ Ready for remediation!"
        else
            echo "❌ Failed to create assignment"
        fi
    else
        echo "❌ Failed to create policy"
    fi

    # Cleanup temp file
    rm -f /tmp/modify-policy.json
}

# Function to create a remediation task
create_remediation_task() {
    echo ""
    echo "🔄 Creating Remediation Task"
    echo "============================="

    # List assignments that can be remediated
    echo "Available assignments for remediation:"
    az policy assignment list --query "[?identity != null].{Name:name,DisplayName:displayName,Policy:policyDefinitionId}" --output table

    echo ""
    read -p "Enter the assignment name to remediate: " ASSIGNMENT_NAME

    if [ ! -z "$ASSIGNMENT_NAME" ]; then
        echo "Creating remediation task for: $ASSIGNMENT_NAME"

        # Create remediation task
        REMEDIATION_ID=$(az policy remediation create \
            --name "remediation-$(date +%s)" \
            --policy-assignment "$ASSIGNMENT_NAME" \
            --query "id" --output tsv)

        if [ $? -eq 0 ]; then
            echo "✅ Remediation task created: $REMEDIATION_ID"

            echo ""
            echo "📊 Checking remediation status..."
            sleep 5

            az policy remediation show --name "remediation-$(date +%s)" --policy-assignment "$ASSIGNMENT_NAME" --query "{Name:name,Status:provisioningState,ResourcesRemediated:deploymentSummary.totalDeploymentsSucceeded,ResourcesFailed:deploymentSummary.totalDeploymentsFailed}" --output table

            echo ""
            echo "💡 You can monitor remediation progress with:"
            echo "   az policy remediation list --policy-assignment $ASSIGNMENT_NAME --output table"
        else
            echo "❌ Failed to create remediation task"
        fi
    else
        echo "❌ No assignment name provided"
    fi
}

echo "=== Azure Policy Learning Script ==="
echo "Script: Policy Remediation"
echo "Date: $(date)"
echo ""

echo "🔧 Azure Policy Remediation"
echo "============================"
echo ""

echo "💡 What is Policy Remediation?"
echo "==============================="
echo "• Remediation fixes non-compliant resources automatically"
echo "• Works with 'modify', 'deployIfNotExists', and 'auditIfNotExists' effects"
echo "• Can be triggered manually or automatically for new resources"
echo "• Requires managed identity with appropriate permissions"
echo ""

# Check for existing assignments that support remediation
echo "🔍 Finding assignments that support remediation..."
REMEDIATION_ASSIGNMENTS=$(az policy assignment list --query "[?identity != null]" --output json)

if [ "$(echo $REMEDIATION_ASSIGNMENTS | jq length)" -eq 0 ]; then
    echo "❌ No assignments with managed identity found."
    echo ""
    echo "💡 To use remediation, you need assignments with:"
    echo "   • Policy effects: modify, deployIfNotExists, or auditIfNotExists"
    echo "   • Managed identity enabled"
    echo "   • Appropriate permissions assigned to the identity"
    echo ""
    echo "🚀 Let's create a remediation-capable assignment..."

    # Show example policies that support remediation
    echo ""
    echo "📋 Built-in policies that support remediation:"
    echo "=============================================="
    echo "1) Deploy Log Analytics agent for Linux VMs"
    echo "2) Configure backup on VMs without a given tag"
    echo "3) Add a tag to resource groups"
    echo "4) Configure Azure Security Center contact email"
    echo ""

    read -p "Would you like to create a remediation example? (y/n): " CREATE_EXAMPLE

    if [[ $CREATE_EXAMPLE =~ ^[Yy]$ ]]; then
        create_remediation_example
    fi
else
    echo "✅ Found $(echo $REMEDIATION_ASSIGNMENTS | jq length) assignment(s) with managed identity"
    echo ""

    # Show remediation-capable assignments
    echo $REMEDIATION_ASSIGNMENTS | jq -r '.[] | "
Assignment: \(.displayName // .name)
Policy: \(.policyDefinitionId | split("/") | .[-1])
Identity: \(.identity.type)
Principal ID: \(.identity.principalId)
Scope: \(.scope)
---"'

    # Check for existing remediation tasks
    echo ""
    echo "📋 Existing Remediation Tasks:"
    echo "=============================="

    # Get assignment names for remediation task lookup
    ASSIGNMENT_NAMES=$(echo $REMEDIATION_ASSIGNMENTS | jq -r '.[].name')

    for assignment in $ASSIGNMENT_NAMES; do
        echo "Assignment: $assignment"
        az policy remediation list --policy-assignment $assignment --query "[].{Name:name,Status:provisioningState,Created:createdOn,Resources:deploymentSummary.totalDeploymentsSucceeded}" --output table 2>/dev/null || echo "  No remediation tasks found"
        echo ""
    done

    # Offer to create new remediation task
    echo ""
    read -p "Would you like to create a new remediation task? (y/n): " CREATE_REMEDIATION

    if [[ $CREATE_REMEDIATION =~ ^[Yy]$ ]]; then
        create_remediation_task
    fi
fi

echo ""
echo "🎯 Best Practices for Remediation"
echo "================================="
echo "• Always test policies in a development environment first"
echo "• Use resource locks to prevent accidental changes"
echo "• Monitor remediation tasks for failures"
echo "• Ensure managed identities have minimal required permissions"
echo "• Use parameterized policies for flexibility"
echo "• Review compliance reports before running remediation"

echo ""
echo "📚 Additional Resources:"
echo "• Azure Policy remediation documentation"
echo "• Managed identity best practices"
echo "• Policy assignment with managed identity"
echo "• Remediation task monitoring"

echo ""
echo "⚠️  Important Notes:"
echo "• Remediation can modify or delete resources"
echo "• Always verify permissions before running"
echo "• Monitor activity logs for remediation actions"
echo "• Review compliance reports after remediation"

echo ""
echo "💡 Next steps:"
echo "- Monitor your remediation tasks"
echo "- Check compliance status: ./05-compliance-report.sh"
echo "- Create more advanced policies with remediation"
echo "- Set up automated remediation for new resources"
