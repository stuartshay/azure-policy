#!/usr/bin/env bash
# Pre-commit Terraform Test Script
# This script runs Terraform tests only for infrastructure directories with changed files

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
INFRASTRUCTURE_DIR="$PROJECT_ROOT/infrastructure"

# Function to print colored output
print_status() {
    local level="$1"
    local message="$2"
    case "$level" in
        "ERROR")
            echo -e "${RED}❌ ERROR: $message${NC}" >&2
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  WARNING: $message${NC}" >&2
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

# Function to get changed infrastructure directories
get_changed_infrastructure_dirs() {
    local changed_files=("$@")
    local changed_dirs=()

    for file in "${changed_files[@]}"; do
        # Check if file is in infrastructure directory
        if [[ "$file" =~ ^infrastructure/([^/]+)/ ]]; then
            local dir_name="${BASH_REMATCH[1]}"
            local full_dir="$INFRASTRUCTURE_DIR/$dir_name"

            # Add to array if directory exists and not already added
            if [[ -d "$full_dir" ]] && [[ ! " ${changed_dirs[*]} " =~  ${dir_name}  ]]; then
                changed_dirs+=("$dir_name")
            fi
        fi
    done

    printf '%s\n' "${changed_dirs[@]}"
}

# Function to run terraform test for a directory
run_terraform_test() {
    local dir_name="$1"
    local full_dir="$INFRASTRUCTURE_DIR/$dir_name"

    print_status "INFO" "Running Terraform tests for $dir_name"

    if [[ ! -d "$full_dir" ]]; then
        print_status "ERROR" "Directory not found: $full_dir"
        return 1
    fi

    # Change to the infrastructure directory
    cd "$full_dir"

    # Check if there are any .tftest.hcl files
    local test_files
    test_files=$(find . -name "*.tftest.hcl" 2>/dev/null || true)

    if [[ -z "$test_files" ]]; then
        print_status "WARNING" "$dir_name: No Terraform test files (*.tftest.hcl) found"
        return 0
    fi

    # Run terraform test
    print_status "INFO" "$dir_name: Running terraform test..."

    if terraform test; then
        print_status "SUCCESS" "$dir_name: All tests passed"
        return 0
    else
        print_status "ERROR" "$dir_name: Tests failed"
        return 1
    fi
}

# Function to run terraform validate for a directory
run_terraform_validate() {
    local dir_name="$1"
    local full_dir="$INFRASTRUCTURE_DIR/$dir_name"

    print_status "INFO" "Validating Terraform configuration for $dir_name"

    if [[ ! -d "$full_dir" ]]; then
        print_status "ERROR" "Directory not found: $full_dir"
        return 1
    fi

    # Change to the infrastructure directory
    cd "$full_dir"

    # Check if terraform files exist
    local tf_files
    tf_files=$(find . -name "*.tf" 2>/dev/null || true)

    if [[ -z "$tf_files" ]]; then
        print_status "WARNING" "$dir_name: No Terraform files (*.tf) found"
        return 0
    fi

    # Initialize if needed (but don't download providers for validation)
    if [[ ! -d ".terraform" ]]; then
        print_status "INFO" "$dir_name: Initializing Terraform (backend=false)..."
        if ! terraform init -backend=false -upgrade=false; then
            print_status "ERROR" "$dir_name: Terraform init failed"
            return 1
        fi
    fi

    # Run terraform validate
    print_status "INFO" "$dir_name: Running terraform validate..."

    if terraform validate; then
        print_status "SUCCESS" "$dir_name: Configuration is valid"
        return 0
    else
        print_status "ERROR" "$dir_name: Configuration validation failed"
        return 1
    fi
}

# Function to run terraform fmt check for a directory
run_terraform_fmt_check() {
    local dir_name="$1"
    local full_dir="$INFRASTRUCTURE_DIR/$dir_name"

    print_status "INFO" "Checking Terraform formatting for $dir_name"

    if [[ ! -d "$full_dir" ]]; then
        print_status "ERROR" "Directory not found: $full_dir"
        return 1
    fi

    # Change to the infrastructure directory
    cd "$full_dir"

    # Check if terraform files exist
    local tf_files
    tf_files=$(find . -name "*.tf" 2>/dev/null || true)

    if [[ -z "$tf_files" ]]; then
        print_status "WARNING" "$dir_name: No Terraform files (*.tf) found"
        return 0
    fi

    # Run terraform fmt check
    print_status "INFO" "$dir_name: Checking terraform fmt..."

    if terraform fmt -check -diff; then
        print_status "SUCCESS" "$dir_name: Formatting is correct"
        return 0
    else
        print_status "ERROR" "$dir_name: Formatting issues found. Run 'terraform fmt' to fix."
        return 1
    fi
}

# Main function
main() {
    local changed_files=("$@")
    local exit_code=0

    echo -e "${GREEN}=== Pre-commit Terraform Testing ===${NC}"
    echo ""

    if [[ ${#changed_files[@]} -eq 0 ]]; then
        print_status "INFO" "No files provided. Testing all infrastructure directories."

        # Test all infrastructure directories
        if [[ -d "$INFRASTRUCTURE_DIR" ]]; then
            for dir in "$INFRASTRUCTURE_DIR"/*; do
                if [[ -d "$dir" ]]; then
                    local dir_name
                    dir_name=$(basename "$dir")

                    # Run validation and formatting checks
                    if ! run_terraform_fmt_check "$dir_name"; then
                        exit_code=1
                    fi

                    if ! run_terraform_validate "$dir_name"; then
                        exit_code=1
                    fi

                    # Run tests if available
                    if ! run_terraform_test "$dir_name"; then
                        exit_code=1
                    fi

                    echo ""
                fi
            done
        fi
    else
        print_status "INFO" "Analyzing changed files: ${changed_files[*]}"

        # Get unique infrastructure directories that have changes
        local changed_dirs
        mapfile -t changed_dirs < <(get_changed_infrastructure_dirs "${changed_files[@]}")

        if [[ ${#changed_dirs[@]} -eq 0 ]]; then
            print_status "INFO" "No infrastructure directories have changes. Skipping tests."
            exit 0
        fi

        print_status "INFO" "Changed infrastructure directories: ${changed_dirs[*]}"
        echo ""

        # Test each changed directory
        for dir_name in "${changed_dirs[@]}"; do
            # Run validation and formatting checks
            if ! run_terraform_fmt_check "$dir_name"; then
                exit_code=1
            fi

            if ! run_terraform_validate "$dir_name"; then
                exit_code=1
            fi

            # Run tests if available
            if ! run_terraform_test "$dir_name"; then
                exit_code=1
            fi

            echo ""
        done
    fi

    # Summary
    echo -e "${GREEN}=== Test Summary ===${NC}"
    if [[ $exit_code -eq 0 ]]; then
        print_status "SUCCESS" "All Terraform tests passed!"
    else
        print_status "ERROR" "Some Terraform tests failed. Please fix the issues before committing."
    fi

    exit $exit_code
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
