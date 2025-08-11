#!/bin/bash
# Publish Module to Terraform Cloud Private Module Registry via API
#
# This script uses the Terraform Cloud API to publish the networking module
# since there's no Terraform CLI command for module publishing.

set -e

# Configuration
ORG_NAME="azure-policy-cloud"
MODULE_NAME="networking"
PROVIDER="azurerm"
REPO_IDENTIFIER="stuartshay/azure-policy"
MODULE_DIRECTORY="infrastructure/terraform/modules/networking"
# Note: MODULE_DESCRIPTION would be used in API call if needed

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

# Check if we're in the right directory
if [[ ! -f "Makefile" ]] || [[ ! -d "infrastructure/terraform/modules/networking" ]]; then
    log_error "Please run this script from the project root directory"
    exit 1
fi

log_info "Publishing networking module to Terraform Cloud Private Module Registry..."

# Load environment variables (including TF_API_TOKEN)
if [[ -f .env ]]; then
    log_info "Loading environment variables from .env..."
    source .env
    export TF_TOKEN_app_terraform_io="$TF_API_TOKEN"
else
    log_error ".env file not found. Please ensure you have TF_API_TOKEN configured."
    exit 1
fi

# Check if API token is available
if [[ -z "$TF_API_TOKEN" ]]; then
    log_error "TF_API_TOKEN not found in .env file"
    exit 1
fi

log_info "Using API token: ${TF_API_TOKEN:0:20}..."

# First, we need to get the VCS OAuth token ID
log_info "Getting VCS OAuth token ID..."

VCS_RESPONSE=$(curl -s \
  --header "Authorization: Bearer $TF_API_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  "https://app.terraform.io/api/v2/organizations/$ORG_NAME/oauth-tokens")

# Extract OAuth token ID (this is a simplified extraction - in production you'd use jq)
OAUTH_TOKEN_ID=$(echo "$VCS_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [[ -z "$OAUTH_TOKEN_ID" ]]; then
    log_error "Failed to get VCS OAuth token ID. Please ensure your GitHub is connected to Terraform Cloud."
    log_info "You may need to connect GitHub manually in Terraform Cloud Settings > VCS Providers"
    exit 1
fi

log_info "Using OAuth token ID: $OAUTH_TOKEN_ID"

# Create the module registry entry
log_info "Publishing module to registry..."

PUBLISH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
  --header "Authorization: Bearer $TF_API_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data "{
    \"data\": {
      \"type\": \"registry-modules\",
      \"attributes\": {
        \"vcs-repo\": {
          \"identifier\": \"$REPO_IDENTIFIER\",
          \"oauth-token-id\": \"$OAUTH_TOKEN_ID\",
          \"display_identifier\": \"$REPO_IDENTIFIER\"
        },
        \"module-directory\": \"$MODULE_DIRECTORY\"
      }
    }
  }" \
  "https://app.terraform.io/api/v2/organizations/$ORG_NAME/registry-modules")

# Extract HTTP code
HTTP_CODE=$(echo "$PUBLISH_RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
RESPONSE_BODY=$(echo "$PUBLISH_RESPONSE" | sed '/HTTP_CODE:/d')

if [[ "$HTTP_CODE" == "201" ]] || [[ "$HTTP_CODE" == "200" ]]; then
    log_success "Module published successfully!"
    log_info "Module: $ORG_NAME/$MODULE_NAME/$PROVIDER"
    log_info "Repository: $REPO_IDENTIFIER"
    log_info "Directory: $MODULE_DIRECTORY"
    log_info ""
    log_info "You can now use the module in your Terraform configurations:"
    echo ""
    echo "module \"networking\" {"
    echo "  source  = \"$ORG_NAME/$MODULE_NAME/$PROVIDER\""
    echo "  version = \"~> 0.1.0\""
    echo "  # ... module configuration"
    echo "}"
    echo ""
    log_info "Next steps:"
    echo "  1. Wait a few minutes for Terraform Cloud to process the module"
    echo "  2. Check the registry: https://app.terraform.io/app/$ORG_NAME/registry"
    echo "  3. Run: ./scripts/switch-to-registry-module.sh 0.1.0"

elif [[ "$HTTP_CODE" == "422" ]]; then
    log_warning "Module may already exist or there's a validation error"
    echo "Response: $RESPONSE_BODY"

    # Check if module already exists
    if echo "$RESPONSE_BODY" | grep -q "already exists"; then
        log_info "Module already exists in registry. Checking if it needs update..."
        log_info "You can still use: ./scripts/switch-to-registry-module.sh 0.1.0"
    else
        log_error "Validation error occurred. Please check the response above."
    fi

else
    log_error "Failed to publish module (HTTP $HTTP_CODE)"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi

log_info "Publishing process completed."
