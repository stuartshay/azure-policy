#!/bin/bash

# Script: Create Policy Assignment
# Description: Creates a new Azure Policy assignment with interactive prompts
# Usage: ./04-create-assignment.sh

echo "=== Azure Policy Learning Script ==="
echo "Script: Create Policy Assignment"
echo "Date: $(date)"
echo ""

# Function to get resource groups
get_resource_groups() {
    az group list --query "[].name" --output tsv
}

# Function to get built-in policies
get_builtin_policies() {
    az policy definition list --query "[?policyType=='BuiltIn'] | [0:20].{Name:displayName, ID:id}" --output json
}

echo "🎯 Creating a new Policy Assignment"
echo "==================================="

# Show current subscription
echo "Current subscription:"
az account show --query "{Name:name, ID:id}" --output table
echo ""

# Get scope
echo "📍 Choose assignment scope:"
echo "1) Subscription (current)"
echo "2) Resource Group"
echo ""
read -p "Enter choice (1-2): " SCOPE_CHOICE

case $SCOPE_CHOICE in
    1)
        SCOPE="/subscriptions/$(az account show --query id --output tsv)"
        echo "Selected scope: Subscription"
        ;;
    2)
        echo ""
        echo "Available Resource Groups:"
        get_resource_groups | nl
        echo ""
        read -p "Enter Resource Group name: " RG_NAME
        if ! az group show --name "$RG_NAME" &>/dev/null; then
            echo "❌ Resource Group '$RG_NAME' not found!"
            exit 1
        fi
        SCOPE="/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RG_NAME"
        echo "Selected scope: Resource Group '$RG_NAME'"
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "📋 Popular Built-in Policies for learning:"
echo "=========================================="
echo "1) Allowed locations"
echo "2) Require a tag on resources"
echo "3) Not allowed resource types"
echo "4) Audit VMs that do not use managed disks"
echo "5) Enter custom policy name"
echo ""
read -p "Enter choice (1-5): " POLICY_CHOICE

case $POLICY_CHOICE in
    1) POLICY_NAME="Allowed locations" ;;
    2) POLICY_NAME="Require a tag on resources" ;;
    3) POLICY_NAME="Not allowed resource types" ;;
    4) POLICY_NAME="Audit VMs that do not use managed disks" ;;
    5)
        read -p "Enter policy name: " POLICY_NAME
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

# Find the policy
echo ""
echo "🔍 Finding policy: '$POLICY_NAME'"
POLICY_ID=$(az policy definition list --query "[?displayName=='$POLICY_NAME'].id" --output tsv | head -1)

if [ -z "$POLICY_ID" ]; then
    echo "❌ Policy '$POLICY_NAME' not found!"
    echo "💡 Try running ./01-list-policies.sh to see available policies"
    exit 1
fi

echo "Found policy ID: $POLICY_ID"

# Get assignment name
echo ""
read -p "Enter assignment name: " ASSIGNMENT_NAME

# Set enforcement mode
echo ""
echo "⚖️  Enforcement Mode:"
echo "1) Default (enforce policy)"
echo "2) DoNotEnforce (audit only)"
echo ""
read -p "Enter choice (1-2): " ENFORCEMENT_CHOICE

case $ENFORCEMENT_CHOICE in
    1) ENFORCEMENT_MODE="Default" ;;
    2) ENFORCEMENT_MODE="DoNotEnforce" ;;
    *) ENFORCEMENT_MODE="Default" ;;
esac

# Create the assignment
echo ""
echo "🚀 Creating policy assignment..."
echo "Assignment Name: $ASSIGNMENT_NAME"
echo "Policy: $POLICY_NAME"
echo "Scope: $SCOPE"
echo "Enforcement: $ENFORCEMENT_MODE"
echo ""

if az policy assignment create \
    --name "$ASSIGNMENT_NAME" \
    --policy "$POLICY_ID" \
    --scope "$SCOPE" \
    --enforcement-mode "$ENFORCEMENT_MODE" \
    --output table; then

    echo ""
    echo "✅ Policy assignment created successfully!"
    echo ""
    echo "💡 Next steps:"
    echo "- Run ./03-list-assignments.sh to see your new assignment"
    echo "- Run ./05-compliance-report.sh to check compliance (may take a few minutes)"
else
    echo ""
    echo "❌ Failed to create policy assignment!"
    echo "💡 Check your permissions and try again"
fi
