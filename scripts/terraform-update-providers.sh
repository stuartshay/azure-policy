#!/bin/bash

# Script to update Terraform provider versions across all modules
# This ensures consistency across the entire project

set -e

echo "🔄 Updating Terraform provider versions across all modules..."

# Define the new provider versions
AZURERM_VERSION="~> 4.40"
RANDOM_VERSION="~> 3.7"

# List of directories containing Terraform configurations
TERRAFORM_DIRS=(
    "infrastructure/terraform"
    "infrastructure/core"
    "infrastructure/app-service"
    "infrastructure/database"
    "infrastructure/functions-app"
    "infrastructure/policies"
    "infrastructure/github-runner"
)

# Function to update provider version in a file
update_provider_version() {
    local file="$1"
    local provider="$2"
    local new_version="$3"

    if [[ -f "$file" ]]; then
        echo "  📝 Updating $provider version in $file"
        sed -i.bak "s|version = \"~> [0-9]\+\.[0-9]\+\"|version = \"$new_version\"|g" "$file"

        # More specific replacement for azurerm
        if [[ "$provider" == "azurerm" ]]; then
            sed -i.bak2 "/source.*hashicorp\/azurerm/,/}/ s|version = \"~> [0-9]\+\.[0-9]\+\"|version = \"$new_version\"|" "$file"
        fi

        # More specific replacement for random
        if [[ "$provider" == "random" ]]; then
            sed -i.bak3 "/source.*hashicorp\/random/,/}/ s|version = \"~> [0-9]\+\.[0-9]\+\"|version = \"$new_version\"|" "$file"
        fi

        # Clean up backup files
        rm -f "$file.bak" "$file.bak2" "$file.bak3" 2>/dev/null || true
    fi
}

# Function to run terraform init -upgrade in a directory
upgrade_terraform_dir() {
    local dir="$1"

    if [[ -d "$dir" && -f "$dir/main.tf" ]]; then
        echo "  🚀 Running terraform init -upgrade in $dir"

        # Check if directory uses Terraform Cloud
        if grep -q "cloud {" "$dir/main.tf"; then
            echo "    ⚠️  Skipping $dir - uses Terraform Cloud (requires authentication)"
            return 0
        fi

        cd "$dir"

        # Clean up any existing .terraform directory to force re-initialization
        rm -rf .terraform .terraform.lock.hcl 2>/dev/null || true

        # Initialize and upgrade
        if terraform init -upgrade; then
            echo "    ✅ Successfully updated providers in $dir"
        else
            echo "    ❌ Failed to update providers in $dir"
        fi

        cd - > /dev/null
    fi
}

# Update provider versions in all main.tf files
echo "📋 Updating provider version constraints..."
for dir in "${TERRAFORM_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "🔍 Processing $dir..."

        # Update azurerm provider version
        update_provider_version "$dir/main.tf" "azurerm" "$AZURERM_VERSION"

        # Update random provider version (if it exists)
        if grep -q "hashicorp/random" "$dir/main.tf" 2>/dev/null; then
            update_provider_version "$dir/main.tf" "random" "$RANDOM_VERSION"
        fi

        # Also check modules subdirectory
        if [[ -d "$dir/modules" ]]; then
            for module_dir in "$dir"/modules/*/; do
                if [[ -f "$module_dir/main.tf" ]]; then
                    echo "  🔍 Processing module $module_dir..."
                    update_provider_version "$module_dir/main.tf" "azurerm" "$AZURERM_VERSION"

                    if grep -q "hashicorp/random" "$module_dir/main.tf" 2>/dev/null; then
                        update_provider_version "$module_dir/main.tf" "random" "$RANDOM_VERSION"
                    fi
                fi
            done
        fi
    else
        echo "⚠️  Directory $dir not found, skipping..."
    fi
done

echo ""
echo "🔄 Upgrading Terraform providers..."

# Run terraform init -upgrade in directories with local backends
for dir in "${TERRAFORM_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        upgrade_terraform_dir "$dir"
    fi
done

echo ""
echo "✅ Provider update process completed!"
echo ""
echo "📋 Summary:"
echo "  - Updated azurerm provider to: $AZURERM_VERSION"
echo "  - Updated random provider to: $RANDOM_VERSION"
echo "  - Directories using Terraform Cloud were skipped (require manual authentication)"
echo ""
echo "🔍 Next steps:"
echo "  1. Review the changes with: git diff"
echo "  2. Test the configurations in a development environment"
echo "  3. Commit the updated .terraform.lock.hcl files"
echo "  4. For Terraform Cloud workspaces, run 'terraform login' and update manually"
