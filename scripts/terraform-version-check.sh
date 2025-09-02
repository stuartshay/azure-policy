#!/usr/bin/env bash
# Terraform Version Check Script
# This script displays current Terraform and provider versions across all modules

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Terraform Version Check ===${NC}"
echo ""

# Check if Terraform is installed
if ! command -v terraform >/dev/null 2>&1; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    echo "Install with: tfenv install latest && tfenv use latest"
    exit 1
fi

# Display Terraform version
echo -e "${BLUE}Terraform Version:${NC}"
terraform version
echo ""

# Check if tfenv is available
if command -v tfenv >/dev/null 2>&1; then
    echo -e "${BLUE}tfenv Status:${NC}"
    echo "Available versions:"
    tfenv list 2>/dev/null || echo "No versions installed via tfenv"
    echo ""
fi

# Check for .terraform-version file
if [ -f .terraform-version ]; then
    echo -e "${BLUE}Project Terraform Version (from .terraform-version):${NC}"
    cat .terraform-version
    echo ""
else
    echo -e "${YELLOW}⚠️  No .terraform-version file found${NC}"
    echo "Consider creating one to pin the Terraform version for this project"
    echo ""
fi

# Function to extract provider versions from a Terraform file
extract_provider_versions() {
    local file="$1"
    local module_name="$2"

    if [ ! -f "$file" ]; then
        return
    fi

    echo -e "${BLUE}📁 $module_name${NC}"

    # Extract azurerm provider version
    azurerm_version=$(grep -A 3 'source.*=.*"hashicorp/azurerm"' "$file" | grep 'version.*=' | sed 's/.*version.*=.*"\([^"]*\)".*/\1/' | head -1)
    if [ -n "$azurerm_version" ]; then
        echo "  azurerm: $azurerm_version"
    fi

    # Extract random provider version
    random_version=$(grep -A 3 'source.*=.*"hashicorp/random"' "$file" | grep 'version.*=' | sed 's/.*version.*=.*"\([^"]*\)".*/\1/' | head -1)
    if [ -n "$random_version" ]; then
        echo "  random: $random_version"
    fi

    # Extract other common providers
    for provider in "azuread" "azapi" "null" "local" "external" "time"; do
        provider_version=$(grep -A 3 "source.*=.*\"hashicorp/$provider\"" "$file" | grep 'version.*=' | sed 's/.*version.*=.*"\([^"]*\)".*/\1/' | head -1)
        if [ -n "$provider_version" ]; then
            echo "  $provider: $provider_version"
        fi
    done
    # Get the directory of the file
    local dir
    dir=$(dirname "$file")

    echo -e "${BLUE}📁 $module_name${NC}"

    # Run terraform providers in the module directory and parse output
    if [ -d "$dir" ]; then
        (
            cd "$dir" || exit
            if terraform providers 2>/dev/null | grep -q "Providers required by configuration:"; then
                terraform providers 2>/dev/null | awk '
                    BEGIN { in_block=0 }
                    /Providers required by configuration:/ { in_block=1; next }
                    /^$/ { in_block=0 }
                    in_block && /^[[:space:]]+\*/ {
                        gsub(/^[[:space:]]+\* /, "", $0);
                        split($0, arr, " ");
                        provider=arr[1];
                        version=arr[2];
                        gsub(/[\(\)]/, "", version);
                        printf "  %s: %s\n", provider, version;
                    }
                '
            else
                echo "  (No providers found or terraform init not run)"
            fi
        )
    else
        echo "  (Module directory not found)"
    fi
    echo ""
}

echo -e "${BLUE}Provider Versions by Module:${NC}"
echo ""

# Check main infrastructure modules
extract_provider_versions "infrastructure/core/main.tf" "Core Infrastructure"
extract_provider_versions "infrastructure/app-service/main.tf" "App Service"
extract_provider_versions "infrastructure/database/main.tf" "Database"
extract_provider_versions "infrastructure/functions-app/main.tf" "Functions App"
extract_provider_versions "infrastructure/service-bus/main.tf" "Service Bus"
extract_provider_versions "infrastructure/policies/main.tf" "Policies"
extract_provider_versions "infrastructure/github-runner/main.tf" "GitHub Runner"

# Check terraform directory
extract_provider_versions "infrastructure/terraform/main.tf" "Main Terraform"

# Check terraform modules
extract_provider_versions "infrastructure/terraform/modules/networking/main.tf" "Networking Module"
extract_provider_versions "infrastructure/terraform/modules/policies/main.tf" "Policies Module"

# Summary
echo -e "${GREEN}=== Summary ===${NC}"

# Count unique azurerm versions
azurerm_versions=$(find infrastructure -name "*.tf" -print0 | xargs -0 grep -l "hashicorp/azurerm" | xargs grep 'version.*=' | grep -v '//' | sed 's/.*version.*=.*"\([^"]*\)".*/\1/' | sort | uniq)

if [ -n "$azurerm_versions" ]; then
    echo -e "${BLUE}Unique azurerm provider versions found:${NC}"
    echo "$azurerm_versions" | while read -r version; do
        count=$(find infrastructure -name "*.tf" -print0 | xargs -0 grep -l "hashicorp/azurerm" | xargs grep "version.*=.*\"$version\"" | wc -l)
        echo "  $version (used in $count files)"
    done
else
    echo -e "${YELLOW}⚠️  No azurerm provider versions found${NC}"
fi

echo ""
echo -e "${GREEN}✅ Version check complete${NC}"
