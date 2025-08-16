#!/usr/bin/env bash
# Terraform Provider Update Script
# This script updates provider versions across all Terraform modules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DRY_RUN=false
PROVIDER="azurerm"
OLD_VERSION=""
NEW_VERSION=""

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --provider PROVIDER    Provider to update (default: azurerm)"
    echo "  -o, --old-version VERSION  Old version to replace (e.g., 4.37)"
    echo "  -n, --new-version VERSION  New version to use (e.g., 4.39)"
    echo "  -d, --dry-run             Show what would be changed without making changes"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --old-version 4.37 --new-version 4.39"
    echo "  $0 --provider azurerm --old-version 4.37 --new-version 4.39 --dry-run"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--provider)
            PROVIDER="$2"
            shift 2
            ;;
        -o|--old-version)
            OLD_VERSION="$2"
            shift 2
            ;;
        -n|--new-version)
            NEW_VERSION="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$OLD_VERSION" ] || [ -z "$NEW_VERSION" ]; then
    echo -e "${RED}❌ Error: Both --old-version and --new-version are required${NC}"
    usage
    exit 1
fi

echo -e "${GREEN}=== Terraform Provider Update ===${NC}"
echo -e "${BLUE}Provider:${NC} $PROVIDER"
echo -e "${BLUE}Old Version:${NC} $OLD_VERSION"
echo -e "${BLUE}New Version:${NC} $NEW_VERSION"
echo -e "${BLUE}Dry Run:${NC} $DRY_RUN"
echo ""

# Find all Terraform files with the specified provider
terraform_files=$(find infrastructure -name "*.tf" -exec grep -l "hashicorp/$PROVIDER" {} \;)

if [ -z "$terraform_files" ]; then
    echo -e "${YELLOW}⚠️  No Terraform files found with $PROVIDER provider${NC}"
    exit 0
fi

echo -e "${BLUE}Files to be updated:${NC}"
echo "$terraform_files" | while read -r file; do
    # Check if the file contains the old version
    if grep -q "version.*=.*\"~> $OLD_VERSION\"" "$file"; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${YELLOW}⚠${NC} $file (no matching version found)"
    fi
done
echo ""

# Function to update a single file
update_file() {
    local file="$1"
    local old_pattern="version.*=.*\"~> $OLD_VERSION\""
    local new_value="version = \"~> $NEW_VERSION\""

    if ! grep -q "$old_pattern" "$file"; then
        echo -e "  ${YELLOW}⚠${NC} No matching version pattern found in $file"
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "  ${BLUE}[DRY RUN]${NC} Would update $file:"
        echo -e "    ${RED}-${NC} $(grep "$old_pattern" "$file" | sed 's/^[[:space:]]*//')"
        echo -e "    ${GREEN}+${NC} $(echo "$new_value" | sed 's/^[[:space:]]*/      /')"
    else
        echo -e "  ${GREEN}✓${NC} Updating $file"
        # Create backup
        cp "$file" "$file.backup"

        # Update the file
        sed -i.tmp "s|version.*=.*\"~> $OLD_VERSION\"|$new_value|g" "$file"
        rm "$file.tmp"

        # Verify the change
        sed -i.tmp -E "s|^[[:space:]]*version[[:space:]]*=[[:space:]]*\"~> $OLD_VERSION\"|$new_value|g" "$file"
        rm "$file.tmp"

        # Verify the change
        if grep -Eq "^[[:space:]]*version[[:space:]]*=[[:space:]]*\"~> $NEW_VERSION\"" "$file"; then
            echo -e "    ${GREEN}✓${NC} Successfully updated"
            rm "$file.backup"
        else
            echo -e "    ${RED}❌${NC} Update failed, restoring backup"
            mv "$file.backup" "$file"
        fi
    fi
}

# Update each file
echo -e "${BLUE}Updating files:${NC}"
echo "$terraform_files" | while read -r file; do
    update_file "$file"
done

echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}=== Dry Run Complete ===${NC}"
    echo "No files were modified. Run without --dry-run to apply changes."
else
    echo -e "${GREEN}=== Update Complete ===${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Review the changes: git diff"
    echo "2. Run terraform init in affected modules to download new provider versions"
    echo "3. Run terraform plan to verify compatibility"
    echo "4. Commit the changes: git add . && git commit -m 'Update $PROVIDER provider to $NEW_VERSION'"
    echo ""
    echo -e "${YELLOW}Recommended commands:${NC}"
    echo "  make terraform-all-init    # Initialize all workspaces"
    echo "  make terraform-all-plan    # Plan all workspaces"
    echo "  make terraform-check-versions  # Verify the updates"
fi

echo ""
echo -e "${GREEN}✅ Provider update script complete${NC}"
