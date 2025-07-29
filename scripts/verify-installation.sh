#!/bin/bash

# Quick Installation Verification Script
# Tests if all the tools installed by install.sh are working properly

echo "🔍 Azure Policy & Functions - Installation Verification"
echo "======================================================"
echo ""

# Function to check if a command exists and show version
check_tool() {
    local tool_name="$1"
    local command="$2"
    local version_flag="$3"

    printf "%-25s" "$tool_name:"

    if command -v "$command" >/dev/null 2>&1; then
        if [ -n "$version_flag" ]; then
            version_output=$($command $version_flag 2>/dev/null | head -n1 | cut -c1-50)
            echo "✅ $version_output"
        else
            echo "✅ Installed"
        fi
    else
        echo "❌ Not found"
    fi
}

echo "🔧 Core Development Tools:"
check_tool "Python 3.13" "python3.13" "--version"
check_tool "nvm" "nvm" "--version"
check_tool "Node.js" "node" "--version"
check_tool "npm" "npm" "--version"
check_tool "jq" "jq" "--version"

echo ""
echo "☁️ Azure Tools:"
check_tool "Azure CLI" "az" "--version"
check_tool "Azure Functions Core" "func" "--version"
check_tool "Azurite" "azurite" "--version"

echo ""
echo "🔨 Infrastructure Tools:"
check_tool "Terraform" "terraform" "--version"
check_tool "Terragrunt" "terragrunt" "--version"
check_tool "tflint" "tflint" "--version"
check_tool "terraform-docs" "terraform-docs" "--version"

echo ""
echo "🛡️ Security & Quality:"
check_tool "Checkov" "checkov" "--version"
check_tool "Pre-commit" "pre-commit" "--version"

echo ""
echo "🐙 Version Control:"
check_tool "GitHub CLI" "gh" "--version"
check_tool "PowerShell" "pwsh" "--version"

echo ""
echo "📁 Project Structure:"
if [ -d "azurite-data" ]; then
    echo "✅ azurite-data directory exists"
else
    echo "❌ azurite-data directory missing"
fi

if [ -f ".pre-commit-config.yaml" ]; then
    echo "✅ Pre-commit configuration exists"
else
    echo "❌ Pre-commit configuration missing"
fi

if [ -f "functions/basic/function_app.py" ]; then
    echo "✅ Azure Functions project exists"
else
    echo "❌ Azure Functions project missing"
fi

echo ""
echo "🚀 Quick Tests:"

# Test if Azurite can start (just check if it accepts --help)
printf "%-25s" "Azurite help:"
if azurite --help >/dev/null 2>&1; then
    echo "✅ Can execute"
else
    echo "❌ Execution failed"
fi

# Test if Azure Functions project has dependencies
printf "%-25s" "Python venv in functions:"
if [ -d "functions/basic/.venv" ]; then
    echo "✅ Virtual environment exists"
else
    echo "⚠️  Virtual environment not created yet"
fi

echo ""
echo "📋 Summary:"
echo "If all tools show ✅, your installation is complete!"
echo ""
echo "🎯 To get started:"
echo "1. Start Azurite: azurite --silent --location ./azurite-data --debug ./azurite-data/debug.log"
echo "2. In another terminal: cd functions/basic && source .venv/bin/activate && func start"
echo "3. Test: curl http://localhost:7071/api/hello"
echo ""
