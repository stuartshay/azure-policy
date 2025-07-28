#!/bin/bash

# Quick DevContainer Rebuild Script
# This script provides a faster way to rebuild and test the devcontainer during development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEVCONTAINER_DIR="$PROJECT_ROOT/.devcontainer"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Quick rebuild options for faster development iteration:"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -f, --fast          Fast rebuild (no cache, but skip some tests)"
    echo "  -t, --test-only     Only run basic connectivity tests"
    echo "  -c, --clean         Clean rebuild (remove all images and volumes)"
    echo ""
    echo "Examples:"
    echo "  $0                  Standard quick rebuild"
    echo "  $0 --fast           Fastest rebuild option"
    echo "  $0 --test-only      Just test existing containers"
    echo "  $0 --clean          Complete clean rebuild"
}

# Function to quick test
quick_test() {
    print_header "Quick Connectivity Test"

    local container_name="devcontainer-app-1"
    local azurite_name="devcontainer-azurite-1"

    # Check if containers are running
    if ! docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
        print_error "App container is not running. Use full test script instead."
        return 1
    fi

    if ! docker ps --format "table {{.Names}}" | grep -q "^$azurite_name$"; then
        print_error "Azurite container is not running. Use full test script instead."
        return 1
    fi

    # Test basic connectivity
    print_status "Testing Azurite connectivity..."
    if docker exec "$container_name" nc -z azurite 10000 2>/dev/null; then
        print_success "Azurite blob service is reachable"
    else
        print_error "Cannot reach Azurite blob service"
        return 1
    fi

    # Test Python
    print_status "Testing Python environment..."
    if docker exec "$container_name" python3 --version >/dev/null 2>&1; then
        print_success "Python is working"
    else
        print_error "Python is not working"
        return 1
    fi

    # Test Azure Functions Core Tools
    print_status "Testing Azure Functions Core Tools..."
    if docker exec "$container_name" func --version >/dev/null 2>&1; then
        print_success "Azure Functions Core Tools are working"
    else
        print_error "Azure Functions Core Tools are not working"
        return 1
    fi

    print_success "Quick test passed!"
}

# Main function
main() {
    local fast_mode=false
    local test_only=false
    local clean_mode=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--fast)
                fast_mode=true
                shift
                ;;
            -t|--test-only)
                test_only=true
                shift
                ;;
            -c|--clean)
                clean_mode=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    print_header "Quick DevContainer Rebuild"

    cd "$PROJECT_ROOT"

    if [ "$test_only" = true ]; then
        quick_test
        exit $?
    fi

    # Stop existing containers
    print_status "Stopping existing containers..."
    cd "$DEVCONTAINER_DIR"
    docker compose down || true

    if [ "$clean_mode" = true ]; then
        print_status "Cleaning up images and volumes..."
        docker compose down -v --rmi all || true
        docker system prune -f || true
    fi

    # Build containers
    if [ "$fast_mode" = true ]; then
        print_status "Fast rebuild (using cache where possible)..."
        docker compose build
    else
        print_status "Standard rebuild..."
        docker compose build --no-cache
    fi

    # Start containers
    print_status "Starting containers..."
    docker compose up -d

    # Wait a bit for startup
    print_status "Waiting for containers to initialize..."
    sleep 15

    # Run quick test
    if quick_test; then
        print_success "Quick rebuild completed successfully!"
        print_status "To run full tests: ./scripts/test-devcontainer.sh --no-build"
        print_status "To connect: docker exec -it devcontainer-app-1 bash"
    else
        print_error "Quick test failed. Run full test script for detailed diagnostics."
        exit 1
    fi
}

# Run main function with all arguments
main "$@"
