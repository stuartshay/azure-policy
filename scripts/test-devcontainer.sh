#!/bin/bash

# DevContainer Build and Test Script
# This script builds and tests the Azure Policy devcontainer to ensure it's functional

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEVCONTAINER_DIR="$PROJECT_ROOT/.devcontainer"
LOG_FILE="$PROJECT_ROOT/devcontainer-test.log"
CONTAINER_NAME="devcontainer-app-1"
AZURITE_CONTAINER_NAME="devcontainer-azurite-1"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to log commands and output
log_command() {
    echo "$ $*" >> "$LOG_FILE"
    "$@" 2>&1 | tee -a "$LOG_FILE"
    return ${PIPESTATUS[0]}
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for container to be ready
wait_for_container() {
    local container_name="$1"
    local max_wait="$2"
    local wait_time=0

    print_status "Waiting for container $container_name to be ready..."

    while [ $wait_time -lt $max_wait ]; do
        if docker ps --format "table {{.Names}}" | grep -q "^$container_name$"; then
            if [ "$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null)" = "running" ]; then
                print_success "Container $container_name is running"
                return 0
            fi
        fi
        sleep 2
        wait_time=$((wait_time + 2))
        echo -n "."
    done

    echo ""
    print_error "Container $container_name failed to start within $max_wait seconds"
    return 1
}

# Function to test network connectivity
test_network_connectivity() {
    print_status "Testing network connectivity between containers..."

    # Test if app container can reach azurite
    if docker exec "$CONTAINER_NAME" nc -z azurite 10000 2>/dev/null; then
        print_success "App container can reach Azurite blob service"
    else
        print_error "App container cannot reach Azurite blob service"
        return 1
    fi

    if docker exec "$CONTAINER_NAME" nc -z azurite 10001 2>/dev/null; then
        print_success "App container can reach Azurite queue service"
    else
        print_error "App container cannot reach Azurite queue service"
        return 1
    fi

    if docker exec "$CONTAINER_NAME" nc -z azurite 10002 2>/dev/null; then
        print_success "App container can reach Azurite table service"
    else
        print_error "App container cannot reach Azurite table service"
        return 1
    fi
}

# Function to test Python environment
test_python_environment() {
    print_status "Testing Python environment..."

    # Test Python installation
    if docker exec "$CONTAINER_NAME" python3 --version >/dev/null 2>&1; then
        local python_version
        python_version=$(docker exec "$CONTAINER_NAME" python3 --version)
        print_success "Python is installed: $python_version"
    else
        print_error "Python is not properly installed"
        return 1
    fi

    # Test pip installation
    if docker exec "$CONTAINER_NAME" pip --version >/dev/null 2>&1; then
        local pip_version
        pip_version=$(docker exec "$CONTAINER_NAME" pip --version)
        print_success "Pip is installed: $pip_version"
    else
        print_error "Pip is not properly installed"
        return 1
    fi

    # Test virtual environment in functions directory
    print_status "Testing virtual environment setup..."
    if docker exec "$CONTAINER_NAME" test -d "/workspace/functions/basic/.venv"; then
        print_success "Virtual environment exists in functions/basic"

        # Test if virtual environment has required packages
        if docker exec "$CONTAINER_NAME" bash -c "cd /workspace/functions/basic && source .venv/bin/activate && python -c 'import azure.functions; print(\"Azure Functions:\", azure.functions.__version__)'"; then
            print_success "Azure Functions package is installed in virtual environment"
        else
            print_error "Azure Functions package is not properly installed"
            return 1
        fi
    else
        print_error "Virtual environment not found in functions/basic"
        return 1
    fi
}

# Function to test Azure Functions Core Tools
test_azure_functions_tools() {
    print_status "Testing Azure Functions Core Tools..."

    if docker exec "$CONTAINER_NAME" func --version >/dev/null 2>&1; then
        local func_version
        func_version=$(docker exec "$CONTAINER_NAME" func --version)
        print_success "Azure Functions Core Tools installed: $func_version"
    else
        print_error "Azure Functions Core Tools not properly installed"
        return 1
    fi

    # Test if func can initialize (dry run)
    print_status "Testing func init capability..."
    if docker exec "$CONTAINER_NAME" bash -c "cd /tmp && func init test-func --python --worker-runtime python >/dev/null 2>&1"; then
        print_success "Azure Functions Core Tools can initialize projects"
        docker exec "$CONTAINER_NAME" rm -rf /tmp/test-func
    else
        print_error "Azure Functions Core Tools cannot initialize projects"
        return 1
    fi
}

# Function to test Azure CLI
test_azure_cli() {
    print_status "Testing Azure CLI..."

    if docker exec "$CONTAINER_NAME" az --version >/dev/null 2>&1; then
        print_success "Azure CLI is installed"
    else
        print_error "Azure CLI is not properly installed"
        return 1
    fi
}

# Function to test PowerShell
test_powershell() {
    print_status "Testing PowerShell..."

    if docker exec "$CONTAINER_NAME" pwsh -Command "Get-Host" >/dev/null 2>&1; then
        print_success "PowerShell is installed and working"
    else
        print_error "PowerShell is not properly installed"
        return 1
    fi
}

# Function to test a simple Azure Function
test_azure_function() {
    print_status "Testing Azure Function execution..."

    # Start Azure Functions in background
    print_status "Starting Azure Functions host..."
    docker exec -d "$CONTAINER_NAME" bash -c "cd /workspace/functions/basic && source .venv/bin/activate && func start --port 7071 >/tmp/func.log 2>&1"

    # Wait for functions to start
    sleep 10

    # Test if functions are responding
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if docker exec "$CONTAINER_NAME" curl -s http://localhost:7071/api/hello >/dev/null 2>&1; then
            print_success "Azure Functions are responding"

            # Test actual function response
            local response
            response=$(docker exec "$CONTAINER_NAME" curl -s http://localhost:7071/api/hello)
            if [[ "$response" == *"Hello"* ]]; then
                print_success "Hello function returned expected response"
            else
                print_warning "Hello function returned unexpected response: $response"
            fi

            # Stop the functions host
            docker exec "$CONTAINER_NAME" pkill -f "func start" || true
            return 0
        fi

        sleep 2
        attempt=$((attempt + 1))
        echo -n "."
    done

    echo ""
    print_error "Azure Functions failed to start or respond within timeout"

    # Show function logs for debugging
    print_status "Function logs:"
    docker exec "$CONTAINER_NAME" cat /tmp/func.log || true

    # Stop the functions host
    docker exec "$CONTAINER_NAME" pkill -f "func start" || true
    return 1
}

# Function to run all tests
run_tests() {
    print_header "Running DevContainer Tests"

    local failed_tests=0

    # Test network connectivity
    if ! test_network_connectivity; then
        failed_tests=$((failed_tests + 1))
    fi

    # Test Python environment
    if ! test_python_environment; then
        failed_tests=$((failed_tests + 1))
    fi

    # Test Azure Functions Core Tools
    if ! test_azure_functions_tools; then
        failed_tests=$((failed_tests + 1))
    fi

    # Test Azure CLI
    if ! test_azure_cli; then
        failed_tests=$((failed_tests + 1))
    fi

    # Test PowerShell
    if ! test_powershell; then
        failed_tests=$((failed_tests + 1))
    fi

    # Test Azure Function execution
    if ! test_azure_function; then
        failed_tests=$((failed_tests + 1))
    fi

    return $failed_tests
}

# Function to cleanup containers
cleanup() {
    print_header "Cleaning Up"

    print_status "Stopping and removing containers..."
    cd "$DEVCONTAINER_DIR"

    if docker compose ps -q | grep -q .; then
        log_command docker compose down -v
        print_success "Containers stopped and removed"
    else
        print_status "No containers to clean up"
    fi

    # Remove any dangling images
    if docker images -f "dangling=true" -q | grep -q .; then
        print_status "Removing dangling images..."
        docker rmi "$(docker images -f "dangling=true" -q)" || true
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -c, --cleanup-only  Only cleanup existing containers"
    echo "  -k, --keep          Keep containers running after tests"
    echo "  -v, --verbose       Verbose output"
    echo "  --no-build          Skip build, only test existing containers"
    echo "  --build-only        Only build, don't run tests"
    echo ""
    echo "Examples:"
    echo "  $0                  Build and test devcontainer"
    echo "  $0 --cleanup-only   Clean up existing containers"
    echo "  $0 --keep           Build, test, and keep containers running"
    echo "  $0 --no-build       Test existing containers without rebuilding"
}

# Main function
main() {
    local cleanup_only=false
    local keep_containers=false
    local no_build=false
    local build_only=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--cleanup-only)
                cleanup_only=true
                shift
                ;;
            -k|--keep)
                keep_containers=true
                shift
                ;;
            -v|--verbose)
                shift
                ;;
            --no-build)
                no_build=true
                shift
                ;;
            --build-only)
                build_only=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Initialize log file
    echo "DevContainer Test Log - $(date)" > "$LOG_FILE"

    print_header "Azure Policy DevContainer Build and Test"
    print_status "Log file: $LOG_FILE"

    # Change to project root
    cd "$PROJECT_ROOT"

    # Cleanup only mode
    if [ "$cleanup_only" = true ]; then
        cleanup
        exit 0
    fi

    # Pre-flight checks
    print_header "Pre-flight Checks"

    if ! command_exists docker; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    print_success "Docker is available"

    if ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    print_success "Docker Compose is available"

    if [ ! -f "$DEVCONTAINER_DIR/devcontainer.json" ]; then
        print_error "devcontainer.json not found in $DEVCONTAINER_DIR"
        exit 1
    fi
    print_success "DevContainer configuration found"

    # Cleanup existing containers first
    cleanup

    if [ "$no_build" = false ]; then
        # Build phase
        print_header "Building DevContainer"

        cd "$DEVCONTAINER_DIR"

        print_status "Building containers..."
        if log_command docker compose build --no-cache; then
            print_success "Containers built successfully"
        else
            print_error "Container build failed"
            exit 1
        fi

        print_status "Starting containers..."
        if log_command docker compose up -d; then
            print_success "Containers started"
        else
            print_error "Failed to start containers"
            exit 1
        fi

        # Wait for containers to be ready
        if ! wait_for_container "$AZURITE_CONTAINER_NAME" 60; then
            print_error "Azurite container failed to start"
            cleanup
            exit 1
        fi

        if ! wait_for_container "$CONTAINER_NAME" 120; then
            print_error "App container failed to start"
            cleanup
            exit 1
        fi

        # Wait for post-create script to complete
        print_status "Waiting for post-create script to complete..."
        sleep 30
    fi

    if [ "$build_only" = false ]; then
        # Test phase
        if run_tests; then
            print_success "All tests passed!"
            exit_code=0
        else
            print_error "Some tests failed. Check the log file for details: $LOG_FILE"
            exit_code=1
        fi

        # Show container status
        print_header "Container Status"
        cd "$DEVCONTAINER_DIR"
        docker compose ps

        # Cleanup unless keeping containers
        if [ "$keep_containers" = false ]; then
            cleanup
        else
            print_status "Keeping containers running as requested"
            print_status "To connect: docker exec -it $CONTAINER_NAME bash"
            print_status "To cleanup later: $0 --cleanup-only"
        fi

        exit $exit_code
    else
        print_success "Build completed successfully"
        print_status "To run tests: $0 --no-build"
        print_status "To cleanup: $0 --cleanup-only"
    fi
}

# Run main function with all arguments
main "$@"
