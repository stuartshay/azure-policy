#!/bin/bash

# Azure Policy DevContainer Path Validation Script
# This script validates that the devcontainer path configuration is correct
# and that the workspace will be mounted at /azure-policy in the container

set -e

echo "=== Azure Policy DevContainer Path Validation ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_header() {
    echo -e "${BLUE}📋 $1${NC}"
}

# Track validation results
validation_errors=0

print_header "Checking project structure..."

# Check if we're in the right directory (project root)
if [ ! -f ".devcontainer/devcontainer.json" ]; then
    echo -e "${RED}❌ This script must be run from the project root directory${NC}"
    echo -e "${RED}   Expected to find .devcontainer/devcontainer.json${NC}"
    exit 1
fi

print_status 0 "Running from project root directory"

# Check current directory name
current_dir=$(basename "$PWD")
if [ "$current_dir" = "azure-policy" ]; then
    print_status 0 "Current directory is named 'azure-policy'"
else
    print_status 1 "Current directory is named '$current_dir' (expected: azure-policy)"
    ((validation_errors++))
fi

print_header "Validating devcontainer configuration..."

# Check devcontainer.json workspaceFolder
workspace_folder=$(grep -o '"workspaceFolder": "[^"]*"' .devcontainer/devcontainer.json | cut -d'"' -f4)
if [ "$workspace_folder" = "/azure-policy" ]; then
    print_status 0 "devcontainer.json workspaceFolder is set to '/azure-policy'"
else
    print_status 1 "devcontainer.json workspaceFolder is '$workspace_folder' (expected: /azure-policy)"
    ((validation_errors++))
fi

# Check docker-compose.yml volume mount
volume_mount=$(grep -o "\.\.\.*:/azure-policy" .devcontainer/docker-compose.yml || echo "not_found")
if [ "$volume_mount" = "..:/azure-policy" ]; then
    print_status 0 "docker-compose.yml volume mount is correct (..:/azure-policy)"
elif [ "$volume_mount" = "../..:/azure-policy" ]; then
    print_status 1 "docker-compose.yml volume mount is '../..:/azure-policy' (should be '..:/azure-policy')"
    echo -e "${YELLOW}   This will mount from 2 levels up instead of project root${NC}"
    ((validation_errors++))
else
    print_status 1 "docker-compose.yml volume mount not found or incorrect (found: '$volume_mount')"
    ((validation_errors++))
fi

# Check postCreateCommand path
post_create_cmd=$(grep -o '"postCreateCommand": "[^"]*"' .devcontainer/devcontainer.json | cut -d'"' -f4)
if [[ "$post_create_cmd" == *"/azure-policy/.devcontainer/post-create.sh"* ]]; then
    print_status 0 "postCreateCommand uses correct path"
else
    print_status 1 "postCreateCommand path may be incorrect: $post_create_cmd"
    ((validation_errors++))
fi

print_header "Checking Docker availability (optional)..."

# Check if Docker is available
if command -v docker &> /dev/null; then
    print_status 0 "Docker is available"

    # Check if Docker Compose is available
    if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
        print_status 0 "Docker Compose is available"
        print_info "Docker environment is ready for devcontainer testing"
    else
        print_status 1 "Docker Compose is not available"
        print_info "Docker is available but Docker Compose is missing - devcontainer may not work"
    fi
else
    print_status 1 "Docker is not available"
    print_info "Docker is not installed - devcontainer functionality will not work"
    print_info "This validation focuses on configuration file correctness"
fi

print_header "Validating Dockerfile..."

# Check if Dockerfile exists and has correct WORKDIR
if [ -f ".devcontainer/Dockerfile" ]; then
    print_status 0 "Dockerfile exists"

    # Check if WORKDIR is set correctly
    if grep -q "WORKDIR /azure-policy" .devcontainer/Dockerfile; then
        print_status 0 "Dockerfile WORKDIR is set to '/azure-policy'"
    else
        print_status 1 "Dockerfile WORKDIR is not set to '/azure-policy'"
        ((validation_errors++))
    fi
else
    print_status 1 "Dockerfile is missing"
    ((validation_errors++))
fi

print_header "Validation Summary"

if [ $validation_errors -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All path validations passed successfully!${NC}"
    echo ""
    echo -e "${GREEN}✅ The devcontainer is correctly configured to mount at '/azure-policy'${NC}"
    echo -e "${GREEN}✅ When you open this project in VS Code with Dev Containers, the workspace will be at the root${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open this project in VS Code"
    echo "2. When prompted, click 'Reopen in Container'"
    echo "3. The terminal should show you're in '/azure-policy' directory"
    echo "4. All scripts and functions should work correctly"
    echo ""
    echo "What was fixed:"
    echo "• Changed docker-compose.yml volume mount from '../..' to '..' (single level up)"
    echo "• This ensures the project root is mounted at '/azure-policy' in the container"
    echo "• The devcontainer.json already had the correct workspaceFolder setting"
    echo "• The Dockerfile already had the correct WORKDIR setting"
else
    echo ""
    echo -e "${RED}❌ Found $validation_errors path configuration issue(s)${NC}"
    echo ""
    echo "Issues to fix:"
    if [[ "$volume_mount" == "../..:/azure-policy" ]]; then
        echo -e "${YELLOW}• Update docker-compose.yml volume mount from '../..' to '..'${NC}"
    fi
    if [ "$workspace_folder" != "/azure-policy" ]; then
        echo -e "${YELLOW}• Update devcontainer.json workspaceFolder to '/azure-policy'${NC}"
    fi
    if [ "$current_dir" != "azure-policy" ]; then
        echo -e "${YELLOW}• Ensure you're running this from the 'azure-policy' project root${NC}"
    fi
    echo ""
    echo "After fixing these issues, run this script again to validate."
fi

echo ""
exit $validation_errors
