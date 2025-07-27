#!/bin/bash

# Script: Policy Remediation
# Description: Demonstrates Azure Policy remediation capabilities
# Usage: ./08-remediation.sh

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

    for assignment in $(echo $REMEDIATION_ASSIGNMENTS | jq -r '.[].name'); do
        echo "Checking remediation tasks for assignment: $assignment"
        az policy remediation list --policy-assignment "$assignment" --output table 2>/dev/null || echo "No remediation tasks found for $assignment"
        echo ""
    done

    # Offer to create new remediation task
    echo ""
    read -p "Would you like to create a new remediation task? (y/n): " CREATE_REMEDIATION

    if [[ $CREATE_REMEDIATION =~ ^[Yy]$ ]]; then
        create_remediation_task
    fi
fi

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
      "defaultValue": "Unassigned"
    }
  }
}
EOF

    # Create the policy
    if az policy definition create \
        --name "$POLICY_NAME" \
        --display-name "Add Environment tag to resource groups" \
        --description "Adds Environment tag to resource groups that don't have it" \
        --rules /tmp/modify-policy.json \
        --mode All; then

        echo "✅ Policy created successfully!"

        # Create assignment with managed identity
        export SUBSCRIPTION_ID
        SUBSCRIPTION_ID=$(az account show --query id --output tsv)
        ASSIGNMENT_NAME="add-env-tag-assignment"

        echo ""
        echo "Creating policy assignment with managed identity..."

        if az policy assignment create \
            --name "$ASSIGNMENT_NAME" \
            --policy "$POLICY_NAME" \
            --assign-identity \
            --location "eastus" \
            --params '{"tagValue": {"value": "Development"}}'; then

            echo "✅ Assignment created with managed identity!"
            echo ""
            echo "⚠️  Note: You may need to assign permissions to the managed identity"
            echo "   Role needed: Contributor or Tag Contributor"

        else
            echo "❌ Failed to create assignment"
        fi
    else
        echo "❌ Failed to create policy"
    fi

    # Cleanup
    rm -f /tmp/modify-policy.json
}

# Function to create a remediation task
create_remediation_task() {
    echo ""
    echo "🔧 Creating Remediation Task"
    echo "============================"

    # List available assignments
    echo "Available assignments for remediation:"
    echo $REMEDIATION_ASSIGNMENTS | jq -r '.[] | "\(.name): \(.displayName // .name)"' | nl

    read -p "Enter assignment name: " ASSIGNMENT_NAME
    read -p "Enter remediation task name: " TASK_NAME

    echo ""
    echo "🚀 Creating remediation task..."

    if az policy remediation create \
        --name "$TASK_NAME" \
        --policy-assignment "$ASSIGNMENT_NAME"; then

        echo "✅ Remediation task created successfully!"
        echo ""
        echo "📊 Task details:"
        az policy remediation show --name "$TASK_NAME" --policy-assignment "$ASSIGNMENT_NAME" --output table

    else
        echo "❌ Failed to create remediation task"
        echo "💡 Check that the assignment exists and supports remediation"
    fi
}

echo ""
echo "📚 Remediation Best Practices:"
echo "==============================="
echo "1. Test policies in audit mode first"
echo "2. Use resource groups or limited scopes for initial testing"
echo "3. Monitor remediation tasks for failures"
echo "4. Ensure managed identities have minimal required permissions"
echo "5. Consider using DeployIfNotExists for new resources only"

echo ""
echo "🔍 Monitoring Remediation:"
echo "========================="
echo "• View remediation tasks: az policy remediation list"
echo "• Check task status: az policy remediation show --name [task-name]"
echo "• Monitor activity logs for remediation actions"
echo "• Review compliance reports after remediation"

echo ""
echo "💡 Next steps:"
echo "- Monitor your remediation tasks"
echo "- Check compliance status: ./05-compliance-report.sh"
echo "- Create more advanced policies with remediation"
echo "- Set up automated remediation for new resources"
