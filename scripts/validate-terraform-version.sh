#!/usr/bin/env bash
# Terraform Version Validation Script
# This script validates .terraform-version consistency with infrastructure requirements,
# example files, and provider versions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_VERSION_FILE="$PROJECT_ROOT/.terraform-version"
INFRASTRUCTURE_DIR="$PROJECT_ROOT/infrastructure"

# Exit codes
EXIT_SUCCESS=0
EXIT_VERSION_MISMATCH=1
EXIT_FILE_NOT_FOUND=2
EXIT_VALIDATION_ERROR=3

# Global variables
ERRORS_FOUND=0
WARNINGS_FOUND=0

# Function to print colored output
print_status() {
    local level="$1"
    local message="$2"
    case "$level" in
        "ERROR")
            echo -e "${RED}❌ ERROR: $message${NC}" >&2
            ((ERRORS_FOUND++))
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  WARNING: $message${NC}" >&2
            ((WARNINGS_FOUND++))
            ;;
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Function to extract version from .terraform-version file
get_project_terraform_version() {
    if [[ ! -f "$TERRAFORM_VERSION_FILE" ]]; then
        print_status "ERROR" ".terraform-version file not found at $TERRAFORM_VERSION_FILE"
        exit $EXIT_FILE_NOT_FOUND
    fi

    local version
    version=$(cat "$TERRAFORM_VERSION_FILE" | tr -d '[:space:]')

    if [[ -z "$version" ]]; then
        print_status "ERROR" ".terraform-version file is empty"
        exit $EXIT_FILE_NOT_FOUND
    fi

    echo "$version"
}

# Function to extract required_version from Terraform files
extract_required_version() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Extract required_version from terraform block
    local version
    version=$(grep -A 10 'terraform[[:space:]]*{' "$file" | \
              grep 'required_version[[:space:]]*=' | \
              sed 's/.*required_version[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/' | \
              head -1)

    if [[ -n "$version" ]]; then
        echo "$version"
        return 0
    fi

    return 1
}

# Function to validate version constraint against actual version
validate_version_constraint() {
    local actual_version="$1"
    local constraint="$2"
    local file_path="$3"

    # Remove 'v' prefix if present
    actual_version="${actual_version#v}"

    # Handle different constraint formats
    case "$constraint" in
        ">= "*|"~> "*|"= "*|"> "*|"< "*|"<= "*)
            # Extract the version number from constraint
            local constraint_version
            constraint_version=$(echo "$constraint" | sed 's/^[><=~][[:space:]]*\([0-9.]*\).*/\1/')

            # For now, we'll do a simple comparison for >= constraints
            if [[ "$constraint" =~ ^">= " ]]; then
                # Simple version comparison (works for most semantic versions)
                if [[ "$actual_version" == "$constraint_version" ]] || \
                   [[ "$(printf '%s\n' "$constraint_version" "$actual_version" | sort -V | head -n1)" == "$constraint_version" ]]; then
                    print_status "SUCCESS" "$file_path: Version $actual_version satisfies constraint '$constraint'"
                    return 0
                else
                    print_status "ERROR" "$file_path: Version $actual_version does not satisfy constraint '$constraint'"
                    return 1
                fi
            elif [[ "$constraint" =~ ^"~> " ]]; then
                # Pessimistic constraint - check if versions are compatible
                local major_minor
                major_minor=$(echo "$constraint_version" | cut -d. -f1-2)
                local actual_major_minor
                actual_major_minor=$(echo "$actual_version" | cut -d. -f1-2)

                if [[ "$major_minor" == "$actual_major_minor" ]]; then
                    print_status "SUCCESS" "$file_path: Version $actual_version satisfies constraint '$constraint'"
                    return 0
                else
                    print_status "ERROR" "$file_path: Version $actual_version does not satisfy constraint '$constraint'"
                    return 1
                fi
            else
                print_status "WARNING" "$file_path: Cannot validate constraint '$constraint' - manual review needed"
                return 0
            fi
            ;;
        *)
            # Exact version match
            if [[ "$actual_version" == "$constraint" ]]; then
                print_status "SUCCESS" "$file_path: Version matches exactly ($actual_version)"
                return 0
            else
                print_status "ERROR" "$file_path: Version mismatch - expected '$constraint', got '$actual_version'"
                return 1
            fi
            ;;
    esac
}

# Function to validate minimum constraint version
validate_minimum_constraint() {
    local constraint="$1"
    local file_path="$2"
    local project_version="$3"

    # Extract the version number from constraint
    case "$constraint" in
        ">= "*)
            local constraint_version
            constraint_version=$(echo "$constraint" | sed 's/^>=[[:space:]]*\([0-9.]*\).*/\1/')

            # Check if constraint version is at least the project version
            if [[ "$(printf '%s\n' "$project_version" "$constraint_version" | sort -V | head -n1)" == "$project_version" ]]; then
                print_status "SUCCESS" "$file_path: Constraint '$constraint' meets minimum requirement (>= $project_version)"
                return 0
            else
                print_status "ERROR" "$file_path: Constraint '$constraint' is below minimum requirement (>= $project_version)"
                return 1
            fi
            ;;
        "~> "*)
            local constraint_version
            constraint_version=$(echo "$constraint" | sed 's/^~>[[:space:]]*\([0-9.]*\).*/\1/')

            # For pessimistic constraints, check if the base version meets minimum
            if [[ "$(printf '%s\n' "$project_version" "$constraint_version" | sort -V | head -n1)" == "$project_version" ]]; then
                print_status "SUCCESS" "$file_path: Constraint '$constraint' meets minimum requirement (>= $project_version)"
                return 0
            else
                print_status "ERROR" "$file_path: Constraint '$constraint' is below minimum requirement (>= $project_version)"
                return 1
            fi
            ;;
        "= "*|"> "*|"< "*|"<= "*)
            print_status "WARNING" "$file_path: Constraint '$constraint' should use '>= $project_version' for consistency"
            return 0
            ;;
        *)
            # Exact version - check if it meets minimum
            if [[ "$(printf '%s\n' "$project_version" "$constraint" | sort -V | head -n1)" == "$project_version" ]]; then
                print_status "WARNING" "$file_path: Exact version '$constraint' should use '>= $project_version' for consistency"
                return 0
            else
                print_status "ERROR" "$file_path: Version '$constraint' is below minimum requirement (>= $project_version)"
                return 1
            fi
            ;;
    esac
}

# Function to validate infrastructure directory
validate_infrastructure_directory() {
    local dir="$1"
    local dir_name
    dir_name=$(basename "$dir")

    print_status "INFO" "Validating infrastructure directory: $dir_name"

    local main_tf="$dir/main.tf"
    if [[ ! -f "$main_tf" ]]; then
        print_status "WARNING" "$dir_name: No main.tf file found"
        return 0
    fi

    local required_version
    required_version=$(extract_required_version "$main_tf")

    if [[ -z "$required_version" ]]; then
        print_status "WARNING" "$dir_name: No required_version found in main.tf"
        return 0
    fi

    local project_version
    project_version=$(get_project_terraform_version)

    local validation_failed=0

    # 1. Validate that the project version satisfies the constraint
    if ! validate_version_constraint "$project_version" "$required_version" "$dir_name/main.tf"; then
        validation_failed=1
    fi

    # 2. Validate that the constraint meets the minimum requirement
    if ! validate_minimum_constraint "$required_version" "$dir_name/main.tf" "$project_version"; then
        validation_failed=1
    fi

    return $validation_failed
}

# Function to validate GitHub workflow files
validate_github_workflows() {
    local workflows_dir="$PROJECT_ROOT/.github/workflows"

    if [[ ! -d "$workflows_dir" ]]; then
        print_status "INFO" "No GitHub workflows directory found"
        return 0
    fi

    print_status "INFO" "Validating GitHub workflow files"

    local project_version
    project_version=$(get_project_terraform_version)

    # Find workflow files that might contain Terraform version specifications
    while IFS= read -r -d '' workflow_file; do
        local workflow_name
        workflow_name=$(basename "$workflow_file")

        # Check for terraform-version specifications
        if grep -q "terraform-version\|terraform_version" "$workflow_file"; then
            local workflow_versions
            workflow_versions=$(grep -E "terraform-version|terraform_version" "$workflow_file" | \
                              sed -E 's/.*terraform[-_]version[[:space:]]*:[[:space:]]*["\047]?([0-9.]+)["\047]?.*/\1/' | \
                              sort -u)

            while IFS= read -r version; do
                if [[ -n "$version" && "$version" != "$project_version" ]]; then
                    print_status "ERROR" "GitHub workflow $workflow_name: Terraform version $version doesn't match project version $project_version"
                else
                    print_status "SUCCESS" "GitHub workflow $workflow_name: Terraform version matches ($version)"
                fi
            done <<< "$workflow_versions"
        fi
    done < <(find "$workflows_dir" -name "*.yml" -o -name "*.yaml" -print0)

    return 0
}

# Function to check provider version consistency
validate_provider_consistency() {
    print_status "INFO" "Checking provider version consistency across infrastructure"

    local temp_file
    temp_file=$(mktemp)

    # Extract all azurerm provider versions ONLY from required_providers blocks in main.tf files
    find "$INFRASTRUCTURE_DIR" -name "main.tf" | while read -r tf_file; do
        # Extract the required_providers block
        block=$(awk '/required_providers[[:space:]]*{/,/}/ {print}' "$tf_file")
        # Extract the azurerm version line from the block
        version=$(echo "$block" | awk '/azurerm[[:space:]]*=/,/{/ {if ($0 ~ /version[[:space:]]*=/) {gsub(/.*version[[:space:]]*=[[:space:]]*\"/, "", $0); gsub(/\".*/, "", $0); print $0}}')
        if [[ -n "$version" ]]; then
            echo "$version|$tf_file" >> "$temp_file"
        fi
    done

    # Check for version consistency
    if [[ -f "$temp_file" && -s "$temp_file" ]]; then
        local unique_versions
        unique_versions=$(cut -d'|' -f1 "$temp_file" | sort -u | wc -l)

        if [[ "$unique_versions" -gt 1 ]]; then
            print_status "WARNING" "Multiple azurerm provider versions found:"
            while IFS='|' read -r version file; do
                echo "  $version in $(basename "$(dirname "$file")")/$(basename "$file")"
            done < "$temp_file"
        else
            local common_version
            common_version=$(cut -d'|' -f1 "$temp_file" | head -1)
            print_status "SUCCESS" "All infrastructure uses consistent azurerm provider version: $common_version"
        fi
    fi

    rm -f "$temp_file"
}

# Main validation function
main() {
    echo -e "${GREEN}=== Terraform Version Validation ===${NC}"
    echo ""

    # Get project Terraform version
    local project_version
    project_version=$(get_project_terraform_version)
    print_status "INFO" "Project Terraform version (from .terraform-version): $project_version"
    echo ""

    # Validate each infrastructure directory
    if [[ -d "$INFRASTRUCTURE_DIR" ]]; then
        for dir in "$INFRASTRUCTURE_DIR"/*; do
            if [[ -d "$dir" ]]; then
                validate_infrastructure_directory "$dir"
            fi
        done
    else
        print_status "ERROR" "Infrastructure directory not found: $INFRASTRUCTURE_DIR"
        exit $EXIT_FILE_NOT_FOUND
    fi

    echo ""

    # Validate GitHub workflows
    validate_github_workflows

    echo ""

    # Check provider consistency
    validate_provider_consistency

    echo ""

    # Summary
    echo -e "${GREEN}=== Validation Summary ===${NC}"
    if [[ $ERRORS_FOUND -eq 0 ]]; then
        print_status "SUCCESS" "All Terraform version validations passed!"
        if [[ $WARNINGS_FOUND -gt 0 ]]; then
            print_status "INFO" "Found $WARNINGS_FOUND warnings (review recommended)"
        fi
        exit $EXIT_SUCCESS
    else
        print_status "ERROR" "Found $ERRORS_FOUND errors and $WARNINGS_FOUND warnings"
        print_status "ERROR" "Please fix version mismatches before proceeding"
        exit $EXIT_VERSION_MISMATCH
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
