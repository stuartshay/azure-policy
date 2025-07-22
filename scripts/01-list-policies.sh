#!/bin/bash

# Script: List Azure Policies
# Description: Lists built-in and custom Azure Policy definitions with focus on AzurePolicy resource group
# Usage: ./01-list-policies.sh [resource-group-name]

# Default resource group for policy operations
DEFAULT_RESOURCE_GROUP="AzurePolicy"
RESOURCE_GROUP="${1:-$DEFAULT_RESOURCE_GROUP}"

echo "=== Azure Policy Script ==="
echo "Script: List Azure Policies"
echo "Target Resource Group: $RESOURCE_GROUP"
echo "Date: $(date)"
echo ""

# Verify resource group exists
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "❌ Error: Resource group '$RESOURCE_GROUP' not found or not accessible"
    echo "Available resource groups:"
    az group list --query "[].name" --output table
    exit 1
fi

echo "✅ Using resource group: $RESOURCE_GROUP"
echo ""

echo "🎯 Policy Assignments for Resource Group: $RESOURCE_GROUP"
echo "========================================================"
ASSIGNMENTS=$(az policy assignment list --resource-group "$RESOURCE_GROUP" --output json)
if [ "$(echo $ASSIGNMENTS | jq length)" -eq 0 ]; then
    echo "No policy assignments found for resource group '$RESOURCE_GROUP'."
else
    echo $ASSIGNMENTS | jq -r '.[] | "Assignment: \(.displayName // .name)\nPolicy: \(.policyDefinitionId | split("/") | .[-1])\nScope: \(.scope)\nEnforcement: \(.enforcementMode // "Default")\n---"'
fi

echo ""
echo "📋 Listing Built-in Policy Definitions..."
echo "========================================"
az policy definition list --query "[?policyType=='BuiltIn'] | [0:10].{Name:displayName, Category:metadata.category, Mode:mode}" --output table

echo ""
echo "📋 Listing Custom Policy Definitions..."
echo "======================================="
CUSTOM_POLICIES=$(az policy definition list --query "[?policyType=='Custom']" --output json)
if [ "$(echo $CUSTOM_POLICIES | jq length)" -eq 0 ]; then
    echo "No custom policies found."
else
    echo $CUSTOM_POLICIES | jq -r '.[] | "Name: \(.displayName)\nCategory: \(.metadata.category // "N/A")\nMode: \(.mode)\n---"'
fi

echo ""
echo "📊 Policy Summary:"
echo "=================="
BUILTIN_COUNT=$(az policy definition list --query "[?policyType=='BuiltIn'] | length(@)" --output tsv)
CUSTOM_COUNT=$(az policy definition list --query "[?policyType=='Custom'] | length(@)" --output tsv)
ASSIGNMENT_COUNT=$(az policy assignment list --resource-group "$RESOURCE_GROUP" --query "length(@)" --output tsv)

echo "Built-in policies: $BUILTIN_COUNT"
echo "Custom policies: $CUSTOM_COUNT"
echo "Total policies: $((BUILTIN_COUNT + CUSTOM_COUNT))"
echo "Assignments in '$RESOURCE_GROUP': $ASSIGNMENT_COUNT"

# Show compliance state for the resource group
echo ""
echo "🏥 Compliance Status for Resource Group: $RESOURCE_GROUP"
echo "======================================================="
COMPLIANCE=$(az policy state list --resource-group "$RESOURCE_GROUP" --query "[].{Policy:policyDefinitionName,Resource:resourceId,State:complianceState}" --output json 2>/dev/null)
if [ $? -eq 0 ] && [ "$(echo $COMPLIANCE | jq length)" -gt 0 ]; then
    echo $COMPLIANCE | jq -r '.[] | "Policy: \(.Policy)\nResource: \(.Resource | split("/") | .[-1])\nState: \(.State)\n---"' | head -20
    
    # Summary of compliance states
    COMPLIANT=$(echo $COMPLIANCE | jq '[.[] | select(.State=="Compliant")] | length')
    NON_COMPLIANT=$(echo $COMPLIANCE | jq '[.[] | select(.State=="NonCompliant")] | length')
    echo ""
    echo "Compliance Summary:"
    echo "- Compliant: $COMPLIANT"
    echo "- Non-compliant: $NON_COMPLIANT"
else
    echo "No compliance data available or insufficient permissions."
fi

echo ""
echo "💡 Next steps:"
echo "- Run ./02-show-policy-details.sh to examine specific policies"
echo "- Run ./03-list-assignments.sh to see detailed policy assignments"
echo "- Check compliance: az policy state list --resource-group $RESOURCE_GROUP"
