#!/bin/bash

# Script: List Azure Policies
# Description: Lists built-in and custom Azure Policy definitions
# Usage: ./01-list-policies.sh

echo "=== Azure Policy Learning Script ==="
echo "Script: List Azure Policies"
echo "Date: $(date)"
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
echo "Built-in policies: $BUILTIN_COUNT"
echo "Custom policies: $CUSTOM_COUNT"
echo "Total policies: $((BUILTIN_COUNT + CUSTOM_COUNT))"

echo ""
echo "💡 Next steps:"
echo "- Run ./02-show-policy-details.sh to examine specific policies"
echo "- Run ./03-list-assignments.sh to see policy assignments"
