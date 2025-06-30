#!/bin/bash

# Script: Compliance Report
# Description: Shows compliance status for Azure Policy assignments
# Usage: ./05-compliance-report.sh

echo "=== Azure Policy Learning Script ==="
echo "Script: Compliance Report"
echo "Date: $(date)"
echo ""

echo "📊 Policy Compliance Report"
echo "============================"

# Get compliance states
echo "🔍 Gathering compliance data..."
COMPLIANCE_DATA=$(az policy state list --output json 2>/dev/null)

if [ $? -ne 0 ] || [ "$(echo $COMPLIANCE_DATA | jq length)" -eq 0 ]; then
    echo "⚠️  No compliance data available yet."
    echo ""
    echo "💡 This could mean:"
    echo "   • No policy assignments exist"
    echo "   • Policy evaluation hasn't completed yet (can take up to 30 minutes)"
    echo "   • No resources exist in the assigned scope"
    echo ""
    echo "🕐 Policy evaluation timeline:"
    echo "   • New assignments: ~30 minutes for first evaluation"
    echo "   • Existing assignments: Every 24 hours"
    echo "   • On-demand: Can be triggered manually"
    echo ""
    echo "💡 Next steps:"
    echo "- Wait for policy evaluation to complete"
    echo "- Create some test resources to evaluate"
    echo "- Run ./03-list-assignments.sh to verify assignments exist"
    exit 0
fi

# Overall compliance summary
echo ""
echo "📈 Overall Compliance Summary:"
echo "=============================="
echo $COMPLIANCE_DATA | jq -r '
group_by(.complianceState) | 
map({state: .[0].complianceState, count: length}) | 
.[] | "\(.state): \(.count)"'

# Compliance by policy
echo ""
echo "📋 Compliance by Policy Assignment:"
echo "===================================="
echo $COMPLIANCE_DATA | jq -r '
group_by(.policyAssignmentName) |
map({
    assignment: .[0].policyAssignmentName,
    compliant: map(select(.complianceState == "Compliant")) | length,
    nonCompliant: map(select(.complianceState == "NonCompliant")) | length,
    total: length
}) |
.[] | "
Assignment: \(.assignment)
  Compliant: \(.compliant)
  Non-Compliant: \(.nonCompliant)
  Total Resources: \(.total)
  Compliance Rate: \((.compliant / .total * 100) | floor)%
"'

# Non-compliant resources details
echo ""
echo "❌ Non-Compliant Resources:"
echo "==========================="
NON_COMPLIANT=$(echo $COMPLIANCE_DATA | jq -r '.[] | select(.complianceState == "NonCompliant")')

if [ -z "$NON_COMPLIANT" ]; then
    echo "🎉 All resources are compliant!"
else
    echo $COMPLIANCE_DATA | jq -r '.[] | select(.complianceState == "NonCompliant") | "
Resource: \(.resourceId | split("/") | .[-1])
Type: \(.resourceType)
Policy: \(.policyAssignmentName)
Reason: \(.complianceReasonCode // "N/A")
Location: \(.resourceLocation)
"'
fi

# Policy effects summary
echo ""
echo "⚖️  Policy Effects in Use:"
echo "========================="
ASSIGNMENTS=$(az policy assignment list --output json)
echo $ASSIGNMENTS | jq -r '.[] | "
Assignment: \(.displayName // .name)
Effect: \(.policyDefinitionId as $id | 
    if ($id | contains("policyDefinitions")) then
        ($id | split("/") | .[-1])
    else
        "Custom/Initiative"
    end)
"'

echo ""
echo "💡 Understanding Compliance States:"
echo "===================================="
echo "✅ Compliant: Resource follows the policy rule"
echo "❌ NonCompliant: Resource violates the policy rule"
echo "⚠️  Conflict: Multiple policies with conflicting requirements"
echo "❓ Unknown: Policy evaluation hasn't completed or failed"

echo ""
echo "💡 Next steps:"
echo "- Run ./06-list-initiatives.sh to explore policy initiatives"
echo "- Run ./07-create-custom-policy.sh to create your own policy"
echo "- Use ./08-remediation.sh to fix non-compliant resources"
