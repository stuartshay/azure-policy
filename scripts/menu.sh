#!/bin/bash

# Script: Policy Learning Menu
# Description: Interactive menu for Azure Policy learning scripts
# Usage: ./menu.sh

echo "=== Azure Policy Learning Scripts ==="
echo "Interactive Learning Menu"
echo "Date: $(date)"
echo ""

# Check if user is logged in to Azure
if ! az account show &>/dev/null; then
    echo "❌ You are not logged in to Azure!"
    echo "Please run 'az login' first."
    exit 1
fi

echo "✅ Logged in to Azure as: $(az account show --query user.name --output tsv)"
echo "📍 Current subscription: $(az account show --query name --output tsv)"
echo ""

# Function to show the menu
show_menu() {
    echo "🎓 Azure Policy Learning Menu"
    echo "============================="
    echo ""
    echo "📋 Basic Operations:"
    echo "1) List all policies"
    echo "2) Show policy details"
    echo "3) List policy assignments"
    echo "4) Create policy assignment"
    echo "5) Check compliance status"
    echo ""
    echo "🏗️  Advanced Topics:"
    echo "6) Explore policy initiatives"
    echo "7) Create custom policy"
    echo "8) Policy remediation"
    echo ""
    echo "🔧 Utilities:"
    echo "9) Switch Azure subscription"
    echo "10) Show current Azure context"
    echo "11) Make all scripts executable"
    echo ""
    echo "0) Exit"
    echo ""
}

# Function to make scripts executable
make_executable() {
    echo "🔧 Making all scripts executable..."
    chmod +x *.sh
    echo "✅ All scripts are now executable!"
    echo ""
}

# Function to switch subscription
switch_subscription() {
    echo "📍 Available subscriptions:"
    az account list --output table
    echo ""
    read -p "Enter subscription ID or name: " SUB_INPUT

    if az account set --subscription "$SUB_INPUT"; then
        echo "✅ Switched to subscription: $(az account show --query name --output tsv)"
    else
        echo "❌ Failed to switch subscription"
    fi
    echo ""
}

# Function to show Azure context
show_context() {
    echo "🔍 Current Azure Context:"
    echo "========================"
    az account show --output table
    echo ""
    echo "📊 Resource counts:"
    echo "Resource groups: $(az group list --query 'length(@)' --output tsv)"
    echo "Policy assignments: $(az policy assignment list --query 'length(@)' --output tsv)"
    echo "Policy definitions (custom): $(az policy definition list --query "[?policyType=='Custom'] | length(@)" --output tsv)"
    echo ""
}

# Function to run a script
run_script() {
    local script_name="$1"
    local script_description="$2"

    echo "🚀 Running: $script_description"
    echo "Script: $script_name"
    echo "========================================"

    if [ -f "$script_name" ]; then
        if [ -x "$script_name" ]; then
            ./"$script_name"
        else
            echo "⚠️  Script not executable. Making it executable..."
            chmod +x "$script_name"
            ./"$script_name"
        fi
    else
        echo "❌ Script '$script_name' not found!"
    fi

    echo ""
    echo "========================================"
    read -p "Press Enter to continue..."
    echo ""
}

# Main menu loop
while true; do
    show_menu
    read -p "Enter your choice (0-11): " choice
    echo ""

    case $choice in
        1)
            run_script "01-list-policies.sh" "List Azure Policies"
            ;;
        2)
            run_script "02-show-policy-details.sh" "Show Policy Details"
            ;;
        3)
            run_script "03-list-assignments.sh" "List Policy Assignments"
            ;;
        4)
            run_script "04-create-assignment.sh" "Create Policy Assignment"
            ;;
        5)
            run_script "05-compliance-report.sh" "Check Compliance Status"
            ;;
        6)
            run_script "06-list-initiatives.sh" "Explore Policy Initiatives"
            ;;
        7)
            run_script "07-create-custom-policy.sh" "Create Custom Policy"
            ;;
        8)
            run_script "08-remediation.sh" "Policy Remediation"
            ;;
        9)
            switch_subscription
            ;;
        10)
            show_context
            ;;
        11)
            make_executable
            ;;
        0)
            echo "👋 Thank you for using Azure Policy Learning Scripts!"
            echo "Happy learning! 🎓"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please enter a number between 0 and 11."
            echo ""
            ;;
    esac
done
