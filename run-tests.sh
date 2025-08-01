#!/bin/bash

# Test runner script for Azure Policy project
# This script provides different testing modes and configurations

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    printf "${BLUE}[INFO]${NC} %s\n" "$1"
}

print_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

# Function to check if we're in the right directory
check_location() {
    if [[ ! -f "pytest.ini" ]]; then
        print_error "Not in project root directory. Please run from project root."
        exit 1
    fi
    print_status "Running from: $(pwd)"
}

# Function to setup test environment
setup_test_env() {
    print_status "Setting up test environment..."

    # Check if virtual environment exists
    if [[ ! -d ".venv" ]]; then
        print_warning "No virtual environment found. Creating one..."
        python3 -m venv .venv
    fi

    # Activate virtual environment
    source .venv/bin/activate

    # Install test requirements
    print_status "Installing test dependencies..."
    pip install -q -r requirements/test.txt

    print_success "Test environment ready"
}

# Function to run policy validation tests
run_policy_tests() {
    print_status "Running Azure Policy validation tests..."
    python -m pytest tests/policies/ -v --tb=short -m "not live"
}

# Function to run integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    python -m pytest tests/integration/ -v --tb=short -m "not live"
}

# Function to run all tests
run_all_tests() {
    print_status "Running all tests..."
    python -m pytest tests/ -v --tb=short -m "not live"
}

# Function to run tests with coverage
run_tests_with_coverage() {
    print_status "Running tests with coverage..."
    python -m pytest tests/ -v --cov=. --cov-report=term-missing --cov-report=html -m "not live"
    print_success "Coverage report generated in htmlcov/"
}

# Function to run live tests (requires Azure CLI authentication)
run_live_tests() {
    print_warning "Running live tests that require Azure CLI authentication..."
    if ! az account show &>/dev/null; then
        print_error "Azure CLI not authenticated. Please run 'az login' first."
        exit 1
    fi

    export AZURE_LIVE_TESTS=true
    python -m pytest tests/ -v --tb=short -m "live"
}

# Function to validate specific policy file
validate_policy_file() {
    local policy_file="$1"

    if [[ ! -f "$policy_file" ]]; then
        print_error "Policy file not found: $policy_file"
        exit 1
    fi

    print_status "Validating policy file: $policy_file"

    # JSON syntax validation
    if ! jq empty "$policy_file" &>/dev/null; then
        print_error "Invalid JSON syntax in $policy_file"
        exit 1
    fi

    # Run pytest on specific file
    python -m pytest tests/policies/test_existing_policies.py -v -k "test_all_existing_policies_have_consistent_structure"

    print_success "Policy file validation completed"
}

# Function to generate test report
generate_test_report() {
    print_status "Generating comprehensive test report..."

    # Run tests with detailed output
    python -m pytest tests/ \
        --html=test-report.html \
        --self-contained-html \
        --cov=. \
        --cov-report=html:htmlcov \
        --cov-report=term-missing \
        --tb=short \
        -m "not live" \
        -v

    print_success "Test report generated: test-report.html"
    print_success "Coverage report generated: htmlcov/index.html"
}

# Function to run quick smoke tests
run_smoke_tests() {
    print_status "Running quick smoke tests..."

    # Test policy JSON syntax
    if ! find policies/ -name "*.json" -exec jq empty {} \; &>/dev/null; then
        print_error "JSON syntax errors found in policy files"
        exit 1
    fi

    # Run basic policy structure tests
    python -m pytest tests/policies/test_policy_validation.py::TestPolicyJSONValidation::test_all_policy_files_are_valid_json -v

    print_success "Smoke tests passed"
}

# Main script logic
main() {
    check_location

    case "${1:-all}" in
        "setup")
            setup_test_env
            ;;
        "policy"|"policies")
            setup_test_env
            run_policy_tests
            ;;
        "integration")
            setup_test_env
            run_integration_tests
            ;;
        "all")
            setup_test_env
            run_all_tests
            ;;
        "coverage")
            setup_test_env
            run_tests_with_coverage
            ;;
        "live")
            setup_test_env
            run_live_tests
            ;;
        "validate")
            if [[ -z "$2" ]]; then
                print_error "Usage: $0 validate <policy-file>"
                exit 1
            fi
            setup_test_env
            validate_policy_file "$2"
            ;;
        "report")
            setup_test_env
            generate_test_report
            ;;
        "smoke")
            setup_test_env
            run_smoke_tests
            ;;
        "help"|"-h"|"--help")
            echo "Azure Policy Test Runner"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  setup        Setup test environment only"
            echo "  policy       Run policy validation tests"
            echo "  integration  Run integration tests"
            echo "  all          Run all tests (default)"
            echo "  coverage     Run tests with coverage report"
            echo "  live         Run live tests (requires Azure auth)"
            echo "  validate     Validate specific policy file"
            echo "  report       Generate comprehensive test report"
            echo "  smoke        Run quick smoke tests"
            echo "  help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 policy                              # Run policy tests"
            echo "  $0 validate policies/storage-naming.json  # Validate specific file"
            echo "  $0 coverage                            # Run with coverage"
            echo "  $0 live                                # Run live Azure tests"
            ;;
        *)
            print_error "Unknown command: $1"
            print_status "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
