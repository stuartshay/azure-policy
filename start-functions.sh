#!/bin/bash

# Azure Functions Development Environment Verification Script

echo "🚀 Azure Functions Development Environment Verification"
echo "======================================================="
echo ""

# Check if we're in the right directory
if [ ! -f "functions/basic/function_app.py" ]; then
    echo "❌ Please run this script from the repository root directory"
    exit 1
fi

echo "📍 Current directory: $(pwd)"
echo ""

# Check Python version
echo "🐍 Python version:"
python3 --version
echo ""

# Check Azure Functions Core Tools
echo "⚙️  Azure Functions Core Tools:"
func --version
echo ""

# Check if Azurite is running
echo "🗄️  Checking Azurite connectivity..."
if nc -z azurite 10000 2>/dev/null; then
    echo "✅ Azurite is running and accessible"
else
    echo "⚠️  Azurite is not accessible. It might still be starting up."
    echo "   You can check with: docker ps"
fi
echo ""

# Navigate to the functions directory
cd functions/basic || exit

# Check if virtual environment exists
echo "🔧 Python virtual environment:"
if [ -d ".venv" ]; then
    echo "✅ Virtual environment exists"

    # Activate virtual environment and check packages
    source .venv/bin/activate
    echo "📦 Key packages installed:"
    pip list | grep -E "(azure-functions|azure-storage)" || echo "⚠️  Azure packages not found"
    deactivate
else
    echo "❌ Virtual environment not found"
    echo "   Creating virtual environment..."
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    echo "✅ Virtual environment created and dependencies installed"
    deactivate
fi
echo ""

# Check local.settings.json
echo "⚙️  Local settings:"
if [ -f "local.settings.json" ]; then
    echo "✅ local.settings.json exists"
else
    echo "❌ local.settings.json not found"
    if [ -f "local.settings.json.template" ]; then
        echo "   Creating from template..."
        cp local.settings.json.template local.settings.json
        echo "✅ local.settings.json created"
    fi
fi
echo ""

echo "🎯 Quick Start Commands:"
echo "======================="
echo "1. Start Azure Functions:"
echo "   cd functions/basic"
echo "   source .venv/bin/activate"
echo "   func start"
echo ""
echo "2. Test endpoints:"
echo "   curl http://localhost:7071/api/hello"
echo "   curl http://localhost:7071/api/health"
echo "   curl http://localhost:7071/api/info"
echo ""
echo "3. Run tests:"
echo "   cd functions/basic"
echo "   source .venv/bin/activate"
echo "   python -m pytest tests/ -v"
echo ""

echo "✅ Environment verification complete!"
