#!/bin/bash
# Switch Core Infrastructure to Use Terraform Cloud Registry Module
#
# This script updates the core infrastructure configuration to use the
# published module from Terraform Cloud Private Module Registry instead of GitHub.
#
# Usage: ./scripts/switch-to-registry-module.sh [VERSION]
# Example: ./scripts/switch-to-registry-module.sh 0.1.0

set -e

# Configuration
CORE_DIR="infrastructure/core"
MAIN_TF="$CORE_DIR/main.tf"
DEFAULT_VERSION="0.1.0"

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

# Get version from command line or use default
VERSION="${1:-$DEFAULT_VERSION}"

log_info "Switching networking module to Terraform Cloud registry (version: $VERSION)"

# Check if main.tf exists
if [[ ! -f "$MAIN_TF" ]]; then
    log_error "File $MAIN_TF not found!"
    exit 1
fi

# Create backup
BACKUP_FILE="${MAIN_TF}.backup-$(date +%Y%m%d-%H%M%S)"
cp "$MAIN_TF" "$BACKUP_FILE"
log_info "Created backup: $BACKUP_FILE"

# Check if module is currently using GitHub source
if ! grep -q "github.com/stuartshay/azure-policy" "$MAIN_TF"; then
    log_warning "GitHub source not found in $MAIN_TF. Module might already be using registry source."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled."
        rm "$BACKUP_FILE"
        exit 0
    fi
fi

# Update main.tf to use registry source
log_info "Updating module source to registry..."

cat > /tmp/networking_module_block.txt << EOF
# Networking Module
module "networking" {
  # Terraform Cloud Private Module Registry source
  source  = "azure-policy-cloud/networking/azurerm"
  version = "$VERSION"

  resource_group_name = azurerm_resource_group.main.name
EOF

# Use sed to replace the module block
sed -i '/# Networking Module/,/resource_group_name = azurerm_resource_group.main.name/ {
    /# Networking Module/r /tmp/networking_module_block.txt
    d
}' "$MAIN_TF"

# Clean up temp file
rm -f /tmp/networking_module_block.txt

log_success "Updated module source to registry (version: $VERSION)"

# Validate the change
if grep -q "azure-policy-cloud/networking/azurerm" "$MAIN_TF"; then
    log_success "Module source successfully updated to registry"
else
    log_error "Failed to update module source. Restoring backup..."
    cp "$BACKUP_FILE" "$MAIN_TF"
    exit 1
fi

# Clean up old Terraform state
log_info "Cleaning up Terraform state for reinitialization..."
cd "$CORE_DIR"
rm -rf .terraform .terraform.lock.hcl
log_success "Cleaned up Terraform state"

# Initialize with new module source
log_info "Initializing Terraform with registry module..."
if make init; then
    log_success "Terraform initialization successful"
else
    log_error "Terraform initialization failed. Check the module is published correctly."
    log_info "Restoring backup configuration..."
    cd "../.."
    cp "$BACKUP_FILE" "$MAIN_TF"
    exit 1
fi

cd "../.."

# Test with plan
log_info "Testing configuration with terraform plan..."
if make terraform-core-plan; then
    log_success "Terraform plan successful! Registry module is working correctly."
else
    log_warning "Terraform plan failed. Please check the configuration manually."
fi

# Clean up backup if successful
read -p "Remove backup file? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    rm "$BACKUP_FILE"
    log_success "Backup file removed"
else
    log_info "Backup file preserved: $BACKUP_FILE"
fi

log_success "Module switch completed successfully!"
echo
log_info "Next steps:"
echo "  1. Run 'make terraform-core-apply' to apply any changes"
echo "  2. Update other workspaces to use the registry module"
echo "  3. Consider removing the GitHub source reference entirely"
