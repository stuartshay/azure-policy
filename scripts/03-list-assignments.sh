#!/bin/bash

# Script: List Policy Assignments
# Description: Lists all Azure Policy assignments in the current subscription
# Usage: ./03-list-assignments.sh

echo "=== Azure Policy Learning Script ==="
echo "Script: List Policy Assignments"
echo "Date: $(date)"
echo ""

echo "🎯 Current Subscription:"
echo "========================"
az account show --query "{Name:name, ID:id, Tenant:tenantId}" --output table

echo ""
echo "📋 Policy Assignments:"
echo "======================"
ASSIGNMENTS=$(az policy assignment list --output json)

if [ "$(echo $ASSIGNMENTS | jq length)" -eq 0 ]; then
    echo "No policy assignments found in the current subscription."
    echo ""
    echo "💡 This could mean:"
    echo "   • No policies have been assigned yet"
    echo "   • You might need to check at different scopes (management group, resource group)"
    echo "   • You might not have sufficient permissions to view assignments"
else
    echo $ASSIGNMENTS | jq -r '.[] | "
Name: \(.displayName // .name)
Policy: \(.policyDefinitionId | split("/") | .[-1])
Scope: \(.scope)
Enforcement: \(.enforcementMode // "Default")
Created: \(.metadata.createdOn // "N/A")
---"'
fi

echo ""
echo "📊 Assignment Summary:"
echo "====================="
ASSIGNMENT_COUNT=$(echo $ASSIGNMENTS | jq length)
echo "Total assignments: $ASSIGNMENT_COUNT"

if [ $ASSIGNMENT_COUNT -gt 0 ]; then
    echo ""
    echo "🔍 Assignments by Enforcement Mode:"
    echo $ASSIGNMENTS | jq -r 'group_by(.enforcementMode // "Default") | .[] | "\(.[0].enforcementMode // "Default"): \(length)"'
fi

echo ""
echo "💡 Next steps:"
echo "- Run ./04-create-assignment.sh to create a new policy assignment"
echo "- Run ./05-compliance-report.sh to check compliance status"
echo "- Run ./06-list-initiatives.sh to see policy initiatives"
