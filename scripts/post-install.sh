#!/bin/bash

# Post-Install Script for Node.js and Azurite
# Run this after the main install.sh script and after restarting your shell

echo "🔄 Post-Installation Setup - Node.js & Azurite"
echo "=============================================="
echo ""

# Source nvm if available
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "Sourcing nvm..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi

# Check Node.js installation
echo "🔍 Checking Node.js installation..."
if command -v node >/dev/null 2>&1; then
    node_version=$(node --version)
    echo "✅ Node.js is available: $node_version"

    # Check if it's version 24+
    major_version=$(echo $node_version | sed 's/v\([0-9]*\).*/\1/')
    if [ "$major_version" -ge 24 ]; then
        echo "✅ Node.js version is current (v24+)"
    else
        echo "⚠️  Node.js version is older than expected. Installing v24..."
        nvm install 24
        nvm use 24
        nvm alias default 24
    fi
else
    echo "❌ Node.js not found. Installing via nvm..."

    if command -v nvm >/dev/null 2>&1; then
        nvm install 24
        nvm use 24
        nvm alias default 24
    else
        echo "❌ nvm not found. Please run the main install.sh script first."
        exit 1
    fi
fi

# Check npm
echo ""
echo "🔍 Checking npm..."
if command -v npm >/dev/null 2>&1; then
    echo "✅ npm is available: $(npm --version)"

    # Update npm to latest
    echo "Updating npm to latest version..."
    npm install -g npm@latest
else
    echo "❌ npm not found. This is unexpected with Node.js installed."
    exit 1
fi

# Install Azurite
echo ""
echo "🔍 Installing/Checking Azurite..."
if command -v azurite >/dev/null 2>&1; then
    echo "✅ Azurite is already installed: $(azurite --version)"
else
    echo "Installing Azurite..."
    npm install -g azurite

    if command -v azurite >/dev/null 2>&1; then
        echo "✅ Azurite installed successfully: $(azurite --version)"
    else
        echo "❌ Azurite installation failed"
        exit 1
    fi
fi

# Test Azurite
echo ""
echo "🧪 Testing Azurite..."
if azurite --help >/dev/null 2>&1; then
    echo "✅ Azurite is working correctly"
else
    echo "❌ Azurite test failed"
fi

# Check project structure
echo ""
echo "🔍 Checking project structure..."
cd "$(dirname "$0")/.." || exit 1

if [ -d "azurite-data" ]; then
    echo "✅ azurite-data directory exists"
else
    echo "⚠️  Creating azurite-data directory..."
    mkdir -p azurite-data
    chmod 755 azurite-data
    echo "✅ azurite-data directory created"
fi

echo ""
echo "🎯 Setup Complete!"
echo ""
echo "🚀 You can now:"
echo "1. Start Azurite:"
echo "   azurite --silent --location ./azurite-data --debug ./azurite-data/debug.log"
echo ""
echo "2. Or use the VS Code task:"
echo "   Ctrl+Shift+P → 'Tasks: Run Task' → 'Start Azurite'"
echo ""
echo "3. Test the installation:"
echo "   ./scripts/verify-installation.sh"
echo ""
echo "4. Start developing with Azure Functions:"
echo "   cd functions/basic"
echo "   source .venv/bin/activate"
echo "   func start"
echo ""
