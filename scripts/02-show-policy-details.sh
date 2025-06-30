#!/bin/bash

# Script: Show Policy Details
# Description: Shows detailed information about a specific Azure Policy
# Usage: ./02-show-policy-details.sh [policy-name]

echo "=== Azure Policy Learning Script ==="
echo "Script: Show Policy Details"
echo "Date: $(date)"
echo ""

# If no policy name provided, show some popular examples
if [ $# -eq 0 ]; then
    echo "🔍 Usage: $0 [policy-name]"
    echo ""
    echo "📝 Popular Built-in Policies to explore:"
    echo "========================================"
    echo "• Allowed locations"
    echo "• Require a tag on resources"
    echo "• Not allowed resource types"
    echo "• Allowed virtual machine size SKUs"
    echo "• Audit VMs that do not use managed disks"
    echo "• Deploy Log Analytics agent for Linux VMs"
    echo ""
    echo "Example: $0 'Allowed locations'"
    exit 1
fi

POLICY_NAME="$1"
echo "🔍 Searching for policy: '$POLICY_NAME'"
echo ""

# Search for the policy
POLICY_JSON=$(az policy definition list --query "[?contains(displayName, '$POLICY_NAME')]" --output json)

if [ "$(echo $POLICY_JSON | jq length)" -eq 0 ]; then
    echo "❌ No policy found with name containing '$POLICY_NAME'"
    echo ""
    echo "💡 Try searching with partial names or check available policies with:"
    echo "   ./01-list-policies.sh"
    exit 1
fi

# Show policy details
echo $POLICY_JSON | jq -r '.[] | "
📋 Policy Details:
==================
Name: \(.displayName)
Description: \(.description // "N/A")
Category: \(.metadata.category // "N/A")
Mode: \(.mode)
Type: \(.policyType)
ID: \(.id)

📜 Policy Rule:
===============
\(.policyRule | tostring)

⚙️  Parameters:
===============
\(if .parameters then (.parameters | tostring) else "No parameters" end)

🏷️  Metadata:
=============
\(.metadata | tostring)
"'

echo ""
echo "💡 Next steps:"
echo "- Run ./03-list-assignments.sh to see policy assignments"
echo "- Run ./04-create-assignment.sh to create a new assignment"
