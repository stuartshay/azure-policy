#!/bin/bash

# Script: List Policy Initiatives
# Description: Lists Azure Policy initiatives (policy sets)
# Usage: ./06-list-initiatives.sh

echo "=== Azure Policy Learning Script ==="
echo "Script: List Policy Initiatives"
echo "Date: $(date)"
echo ""

echo "📦 Azure Policy Initiatives (Policy Sets)"
echo "=========================================="
echo ""
echo "💡 What are initiatives?"
echo "Initiatives group multiple related policies together for easier management."
echo "They're also called 'Policy Sets' and help with compliance frameworks."
echo ""

# List built-in initiatives
echo "🏢 Built-in Initiatives:"
echo "========================"
BUILTIN_INITIATIVES=$(az policy set-definition list --query "[?policyType=='BuiltIn'] | [0:15]" --output json)

if [ "$(echo $BUILTIN_INITIATIVES | jq length)" -eq 0 ]; then
    echo "No built-in initiatives found."
else
    echo $BUILTIN_INITIATIVES | jq -r '.[] | "
Name: \(.displayName)
Category: \(.metadata.category // "N/A")
Description: \(.description[0:100])...
Policy Count: \(.policyDefinitions | length)
ID: \(.id | split("/") | .[-1])
---"'
fi

# List custom initiatives
echo ""
echo "🔧 Custom Initiatives:"
echo "======================"
CUSTOM_INITIATIVES=$(az policy set-definition list --query "[?policyType=='Custom']" --output json)

if [ "$(echo $CUSTOM_INITIATIVES | jq length)" -eq 0 ]; then
    echo "No custom initiatives found."
else
    echo $CUSTOM_INITIATIVES | jq -r '.[] | "
Name: \(.displayName)
Description: \(.description[0:100])...
Policy Count: \(.policyDefinitions | length)
---"'
fi

# Show popular compliance frameworks
echo ""
echo "🏛️  Popular Compliance Framework Initiatives:"
echo "=============================================="
COMPLIANCE_FRAMEWORKS=("Azure Security Benchmark" "NIST SP 800-53" "ISO 27001" "PCI DSS" "HIPAA HITRUST" "SOC TSP")

for framework in "${COMPLIANCE_FRAMEWORKS[@]}"; do
    FOUND=$(echo $BUILTIN_INITIATIVES | jq -r --arg fw "$framework" '.[] | select(.displayName | contains($fw)) | .displayName' | head -1)
    if [ ! -z "$FOUND" ]; then
        echo "✅ $FOUND"
    else
        echo "❌ $framework (not found)"
    fi
done

# Initiative assignments
echo ""
echo "🎯 Initiative Assignments:"
echo "=========================="
INITIATIVE_ASSIGNMENTS=$(az policy assignment list --query "[?policyDefinitionId | contains('policySetDefinitions')]" --output json)

if [ "$(echo $INITIATIVE_ASSIGNMENTS | jq length)" -eq 0 ]; then
    echo "No initiative assignments found."
else
    echo $INITIATIVE_ASSIGNMENTS | jq -r '.[] | "
Assignment: \(.displayName // .name)
Initiative: \(.policyDefinitionId | split("/") | .[-1])
Scope: \(.scope)
Enforcement: \(.enforcementMode // "Default")
---"'
fi

# Summary statistics
echo ""
echo "📊 Initiative Summary:"
echo "====================="
BUILTIN_COUNT=$(echo $BUILTIN_INITIATIVES | jq length)
CUSTOM_COUNT=$(echo $CUSTOM_INITIATIVES | jq length)
ASSIGNMENT_COUNT=$(echo $INITIATIVE_ASSIGNMENTS | jq length)

echo "Built-in initiatives: $BUILTIN_COUNT"
echo "Custom initiatives: $CUSTOM_COUNT"
echo "Initiative assignments: $ASSIGNMENT_COUNT"

echo ""
echo "💡 Working with Initiatives:"
echo "============================"
echo "• Initiatives contain multiple policies that work together"
echo "• They simplify compliance with regulatory frameworks"
echo "• You can assign an entire initiative instead of individual policies"
echo "• Parameters can be set at the initiative level"

echo ""
echo "🔍 Detailed Initiative Information:"
echo "Use: az policy set-definition show --name [initiative-name]"

echo ""
echo "💡 Next steps:"
echo "- Run ./07-create-custom-policy.sh to create a custom policy"
echo "- Run ./08-remediation.sh to learn about policy remediation"
echo "- Use ./02-show-policy-details.sh to examine specific policies within initiatives"
