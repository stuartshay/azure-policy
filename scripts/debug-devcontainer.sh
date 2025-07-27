#!/bin/bash

# DevContainer Debug Script
# This script helps diagnose issues with the devcontainer setup

set -e

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Debug options for troubleshooting devcontainer issues:"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -l, --logs          Show container logs"
    echo "  -s, --status        Show detailed container status"
    echo "  -n, --network       Debug network connectivity"
    echo "  -e, --exec          Execute interactive shell in container"
    echo "  -f, --files         Check file permissions and mounts"
    echo "  -a, --all           Run all diagnostic checks"
    echo ""
    echo "Examples:"
    echo "  $0 --logs           Show container logs"
    echo "  $0 --status         Show container status"
    echo "  $0 --all            Run all diagnostics"
}

# Function to show container status
show_container_status() {
    print_header "Container Status"

    cd "$DEVCONTAINER_DIR"

    print_status "Docker Compose services:"
    docker compose ps || print_error "Failed to get docker-compose status"

    echo ""
    print_status "Running containers:"
    docker ps --filter "name=devcontainer" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    print_status "All containers (including stopped):"
    docker ps -a --filter "name=devcontainer" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"

    echo ""
    print_status "Container resource usage:"
    docker stats --no-stream --filter "name=devcontainer" || print_warning "No running containers found"
}

# Function to show container logs
show_container_logs() {
    print_header "Container Logs"

    cd "$DEVCONTAINER_DIR"

    print_status "App container logs (last 50 lines):"
    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        docker logs --tail 50 "$CONTAINER_NAME" || print_error "Failed to get app container logs"
    else
        print_warning "App container is not running"
    fi

    echo ""
    print_status "Azurite container logs (last 50 lines):"
    if docker ps -q --filter "name=$AZURITE_CONTAINER_NAME" | grep -q .; then
        docker logs --tail 50 "$AZURITE_CONTAINER_NAME" || print_error "Failed to get Azurite container logs"
    else
        print_warning "Azurite container is not running"
    fi

    echo ""
    print_status "Docker Compose logs (last 50 lines):"
    docker compose logs --tail 50 || print_error "Failed to get docker-compose logs"
}

# Function to debug network connectivity
debug_network() {
    print_header "Network Diagnostics"

    if ! docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        print_error "App container is not running"
        return 1
    fi

    print_status "Container network information:"
    docker exec "$CONTAINER_NAME" ip addr show || print_error "Failed to get network info"

    echo ""
    print_status "DNS resolution test:"
    docker exec "$CONTAINER_NAME" nslookup azurite || print_warning "DNS resolution failed"

    echo ""
    print_status "Network connectivity tests:"

    # Test Azurite ports
    for port in 10000 10001 10002; do
        if docker exec "$CONTAINER_NAME" nc -z azurite $port 2>/dev/null; then
            print_success "Port $port is reachable"
        else
            print_error "Port $port is NOT reachable"
        fi
    done

    echo ""
    print_status "Docker network information:"
    docker network ls | grep azure-policy || print_warning "No azure-policy networks found"

    echo ""
    print_status "Container network details:"
    docker inspect "$CONTAINER_NAME" | grep -A 20 "NetworkSettings" || print_error "Failed to inspect container network"
}

# Function to check file permissions and mounts
check_files() {
    print_header "File System Diagnostics"

    if ! docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        print_error "App container is not running"
        return 1
    fi

    print_status "Workspace mount check:"
    docker exec "$CONTAINER_NAME" ls -la /workspace || print_error "Workspace not mounted"

    echo ""
    print_status "DevContainer files:"
    docker exec "$CONTAINER_NAME" ls -la /workspace/.devcontainer || print_error "DevContainer files not found"

    echo ""
    print_status "Functions directory:"
    docker exec "$CONTAINER_NAME" ls -la /workspace/functions/basic || print_error "Functions directory not found"

    echo ""
    print_status "Virtual environment:"
    docker exec "$CONTAINER_NAME" ls -la /workspace/functions/basic/.venv || print_warning "Virtual environment not found"

    echo ""
    print_status "Python packages in venv:"
    docker exec "$CONTAINER_NAME" bash -c "cd /workspace/functions/basic && source .venv/bin/activate && pip list | head -20" || print_warning "Cannot list packages"

    echo ""
    print_status "File permissions check:"
    docker exec "$CONTAINER_NAME" stat -c "%a %n" /workspace/scripts/*.sh || print_warning "Cannot check script permissions"

    echo ""
    print_status "Disk usage:"
    docker exec "$CONTAINER_NAME" df -h || print_warning "Cannot check disk usage"
}

# Function to show system information
show_system_info() {
    print_header "System Information"

    print_status "Docker version:"
    docker --version || print_error "Docker not available"

    echo ""
    print_status "Docker Compose version:"
    docker compose version || print_error "Docker Compose not available"

    echo ""
    print_status "Available Docker images:"
    docker images | grep -E "(azure-policy|devcontainer|python|azurite)" || print_warning "No relevant images found"

    echo ""
    print_status "Docker system info:"
    docker system df || print_warning "Cannot get system info"

    if docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        echo ""
        print_status "Container environment variables:"
        docker exec "$CONTAINER_NAME" env | grep -E "(AZURE|PYTHON|PATH)" | head -10 || print_warning "Cannot get environment"

        echo ""
        print_status "Container processes:"
        docker exec "$CONTAINER_NAME" ps aux | head -10 || print_warning "Cannot get processes"
    fi
}

# Function to run all diagnostics
run_all_diagnostics() {
    show_system_info
    show_container_status
    show_container_logs
    debug_network
    check_files

    print_header "Summary"
    print_status "All diagnostic checks completed."
    print_status "Review the output above for any errors or warnings."
    print_status ""
    print_status "Common solutions:"
    print_status "- If containers are not running: ./scripts/test-devcontainer.sh"
    print_status "- If network issues: docker compose down && docker compose up -d"
    print_status "- If file issues: Check file permissions and mounts"
    print_status "- If build issues: ./scripts/quick-rebuild-devcontainer.sh --clean"
}

# Function to execute interactive shell
exec_shell() {
    print_header "Interactive Shell"

    if ! docker ps -q --filter "name=$CONTAINER_NAME" | grep -q .; then
        print_error "App container is not running"
        print_status "Start the container first with: ./scripts/test-devcontainer.sh"
        return 1
    fi

    print_status "Connecting to container shell..."
    print_status "Type 'exit' to return to host shell"
    echo ""

    docker exec -it "$CONTAINER_NAME" bash
}

# Main function
main() {
    local show_logs=false
    local show_status=false
    local debug_net=false
    local exec_shell_flag=false
    local check_files_flag=false
    local run_all=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--logs)
                show_logs=true
                shift
                ;;
            -s|--status)
                show_status=true
                shift
                ;;
            -n|--network)
                debug_net=true
                shift
                ;;
            -e|--exec)
                exec_shell_flag=true
                shift
                ;;
            -f|--files)
                check_files_flag=true
                shift
                ;;
            -a|--all)
                run_all=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # If no options specified, show usage
    if [ "$show_logs" = false ] && [ "$show_status" = false ] && [ "$debug_net" = false ] && \
       [ "$exec_shell_flag" = false ] && [ "$check_files_flag" = false ] && [ "$run_all" = false ]; then
        show_usage
        exit 0
    fi

    print_header "DevContainer Debug Tool"

    cd "$PROJECT_ROOT"

    # Execute requested operations
    if [ "$run_all" = true ]; then
        run_all_diagnostics
    else
        if [ "$show_status" = true ]; then
            show_container_status
        fi

        if [ "$show_logs" = true ]; then
            show_container_logs
        fi

        if [ "$debug_net" = true ]; then
            debug_network
        fi

        if [ "$check_files_flag" = true ]; then
            check_files
        fi

        if [ "$exec_shell_flag" = true ]; then
            exec_shell
        fi
    fi
}

# Run main function with all arguments
main "$@"
