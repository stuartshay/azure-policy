#!/bin/bash
# Alternative Module Publishing Script - Simplified Approach
#
# Since API publishing requires VCS OAuth setup, this script helps you
# verify the module is ready and provides the exact information needed
# for manual publishing via Terraform Cloud UI.

set -e

# Configuration
ORG_NAME="azure-policy-cloud"
MODULE_NAME="networking"
PROVIDER="azurerm"
REPO_IDENTIFIER="stuartshay/azure-policy"
MODULE_DIRECTORY="infrastructure/terraform/modules/networking"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "================================================================="
echo "           Terraform Cloud Module Publishing Helper"
echo "================================================================="
echo ""

# Check if we're in the right directory
if [[ ! -f "Makefile" ]] || [[ ! -d "$MODULE_DIRECTORY" ]]; then
    log_error "Please run this script from the project root directory"
    exit 1
fi

log_info "Verifying module readiness for publishing..."

# Check if module files exist
REQUIRED_FILES=("$MODULE_DIRECTORY/main.tf" "$MODULE_DIRECTORY/variables.tf" "$MODULE_DIRECTORY/outputs.tf" "$MODULE_DIRECTORY/README.md")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        MISSING_FILES+=("$file")
    fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    log_error "Missing required module files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  ❌ $file"
    done
    exit 1
fi

log_success "All required module files exist:"
for file in "${REQUIRED_FILES[@]}"; do
    echo "  ✅ $file"
done

# Check if files are tracked in git
log_info "Checking Git status..."
if git ls-files --error-unmatch "$MODULE_DIRECTORY"/*.tf "$MODULE_DIRECTORY"/README.md >/dev/null 2>&1; then
    log_success "Module files are tracked in Git"
else
    log_error "Some module files may not be tracked in Git"
    exit 1
fi

# Check if tag exists
if git tag -l | grep -q "^v0.1.0$"; then
    log_success "Git tag v0.1.0 exists"
else
    log_warning "Git tag v0.1.0 not found. Creating it now..."
    git tag -a v0.1.0 -m "Release v0.1.0: networking module"
    git push origin v0.1.0
    log_success "Created and pushed Git tag v0.1.0"
fi

# Verify authentication
if [[ -f .env ]]; then
    source .env
    if [[ -n "$TF_API_TOKEN" ]]; then
        log_success "Terraform Cloud API token found in .env"
    else
        log_warning "TF_API_TOKEN not found in .env"
    fi
else
    log_warning ".env file not found"
fi

echo ""
echo "================================================================="
echo "                    MANUAL PUBLISHING REQUIRED"
echo "================================================================="
echo ""
log_info "Due to VCS OAuth requirements, please publish manually:"
echo ""
echo "🌐 Go to: https://app.terraform.io/app/$ORG_NAME/registry"
echo ""
echo "📝 Click 'Publish' > 'Module' and enter:"
echo "   • Repository: $REPO_IDENTIFIER"
echo "   • Module Name: $MODULE_NAME"
echo "   • Provider: $PROVIDER"
echo "   • Module Directory: $MODULE_DIRECTORY"
echo "   • Publishing Type: Tag (recommended)"
echo ""
echo "✅ After publishing, run:"
echo "   ./scripts/switch-to-registry-module.sh 0.1.0"
echo ""
echo "================================================================="

# Test Terraform Cloud authentication
log_info "Testing Terraform Cloud connection..."
if [[ -n "$TF_API_TOKEN" ]]; then
    TEST_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        --header "Authorization: Bearer $TF_API_TOKEN" \
        "https://app.terraform.io/api/v2/organizations/$ORG_NAME")

    if [[ "$TEST_RESPONSE" == "200" ]]; then
        log_success "Terraform Cloud authentication successful"
    else
        log_warning "Terraform Cloud authentication may have issues (HTTP $TEST_RESPONSE)"
    fi
else
    log_warning "Cannot test Terraform Cloud connection - no API token"
fi

echo ""
log_success "Module verification completed. Ready for manual publishing!"
