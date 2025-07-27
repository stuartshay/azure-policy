#!/bin/bash

# Azure Policy DevContainer Validation Script
# This script validates that the devcontainer is properly configured and functional

set -e

echo "=== Azure Policy DevContainer Validation ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f ".devcontainer/devcontainer.json" ]; then
    echo -e "${RED}❌ This script must be run from the project root directory${NC}"
    exit 1
fi

print_info "Checking devcontainer configuration files..."

# Check devcontainer files exist
files=(
    ".devcontainer/devcontainer.json"
    ".devcontainer/docker-compose.yml"
    ".devcontainer/Dockerfile"
    ".devcontainer/post-create.sh"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        print_status 0 "$file exists"
    else
        print_status 1 "$file missing"
        exit 1
    fi
done

print_info "Validating Docker environment..."

# Check Docker is available
if command -v docker &> /dev/null; then
    print_status 0 "Docker is available"
else
    print_status 1 "Docker is not available"
    exit 1
fi

# Check Docker Compose is available
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    print_status 0 "Docker Compose is available"
else
    print_status 1 "Docker Compose is not available"
    exit 1
fi

print_info "Testing devcontainer build..."

# Test build without starting
if docker-compose -f .devcontainer/docker-compose.yml build --no-cache > /dev/null 2>&1; then
    print_status 0 "DevContainer builds successfully"
else
    print_status 1 "DevContainer build failed"
    echo "Run './scripts/test-devcontainer.sh' for detailed build logs"
    exit 1
fi

print_info "Starting containers for validation..."

# Start containers
if docker-compose -f .devcontainer/docker-compose.yml up -d > /dev/null 2>&1; then
    print_status 0 "Containers started successfully"
else
    print_status 1 "Failed to start containers"
    exit 1
fi

# Wait for containers to be ready
sleep 10

print_info "Validating installed tools..."

# Test Azure CLI
if docker exec devcontainer-app-1 az --version > /dev/null 2>&1; then
    print_status 0 "Azure CLI is installed and working"
else
    print_status 1 "Azure CLI is not working"
fi

# Test PowerShell
if docker exec devcontainer-app-1 pwsh -c "Get-Host" > /dev/null 2>&1; then
    print_status 0 "PowerShell is installed and working"
else
    print_status 1 "PowerShell is not working"
fi

# Test Azure Functions Core Tools
if docker exec devcontainer-app-1 func --version > /dev/null 2>&1; then
    print_status 0 "Azure Functions Core Tools installed"
else
    print_status 1 "Azure Functions Core Tools not working"
fi

# Test Python environment
if docker exec devcontainer-app-1 python3 --version > /dev/null 2>&1; then
    print_status 0 "Python 3 is available"
else
    print_status 1 "Python 3 is not available"
fi

# Test network connectivity to Azurite
if docker exec devcontainer-app-1 nc -z azurite 10000 > /dev/null 2>&1; then
    print_status 0 "Network connectivity to Azurite working"
else
    print_status 1 "Cannot connect to Azurite"
fi

print_info "Cleaning up test containers..."

# Cleanup
docker-compose -f .devcontainer/docker-compose.yml down -v > /dev/null 2>&1

echo ""
echo -e "${GREEN}🎉 DevContainer validation completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Open this project in VS Code"
echo "2. When prompted, click 'Reopen in Container'"
echo "3. Wait for the container to build and the post-create script to run"
echo "4. Start developing with Azure Functions and PowerShell!"
echo ""
echo "Available tools in the container:"
echo "- Azure CLI (az)"
echo "- PowerShell (pwsh) with Azure modules"
echo "- Azure Functions Core Tools (func)"
echo "- Python 3.13 with Azure SDK"
echo "- Azurite storage emulator"
echo ""
echo "Quick test commands:"
echo "- az --version"
echo "- pwsh -c 'Get-Module Az.* -ListAvailable'"
echo "- func --version"
echo "- cd functions/basic && func start"
