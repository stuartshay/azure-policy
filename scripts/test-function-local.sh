#!/bin/bash

# Azure Functions Local Testing Script
# This script sets up and tests the Azure Function locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if we're in the right directory
if [ ! -d "functions/basic" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Navigate to function directory
cd functions/basic

print_status "Setting up local Azure Functions environment..."

# Check if Azure Functions Core Tools is installed
if ! command -v func &> /dev/null; then
    print_error "Azure Functions Core Tools not found. Please install it first:"
    echo "  Ubuntu/Debian: sudo apt-get install azure-functions-core-tools-4"
    echo "  macOS: brew tap azure/functions && brew install azure-functions-core-tools@4"
    echo "  Windows: npm install -g azure-functions-core-tools@4 --unsafe-perm true"
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)

if [[ $PYTHON_MAJOR -lt 3 ]] || [[ $PYTHON_MAJOR -eq 3 && $PYTHON_MINOR -lt 8 ]]; then
    print_error "Python 3.8 or higher is required. Current version: $PYTHON_VERSION"
    exit 1
fi

print_success "Python version: $PYTHON_VERSION"

# Create virtual environment if it doesn't exist
if [ ! -d ".venv" ]; then
    print_status "Creating Python virtual environment..."
    python3 -m venv .venv
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source .venv/bin/activate

# Install dependencies
print_status "Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Install testing dependencies
pip install pytest pytest-cov requests

# Create local.settings.json if it doesn't exist
if [ ! -f "local.settings.json" ]; then
    print_status "Creating local.settings.json..."
    cat > local.settings.json << EOF
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "FUNCTIONS_EXTENSION_VERSION": "~4",
    "ENVIRONMENT": "local",
    "LOG_LEVEL": "INFO"
  },
  "Host": {
    "LocalHttpPort": 7071,
    "CORS": "*",
    "CORSCredentials": false
  }
}
EOF
    print_success "Created local.settings.json"
else
    print_status "local.settings.json already exists"
fi

# Run unit tests
print_status "Running unit tests..."
if python -m pytest tests/ -v --cov=. --cov-report=term-missing; then
    print_success "All unit tests passed!"
else
    print_warning "Some unit tests failed, but continuing with local testing..."
fi

# Start the function in background
print_status "Starting Azure Functions runtime..."
func start --port 7071 &
FUNC_PID=$!

# Wait for function to start
print_status "Waiting for function to start..."
sleep 10

# Function to test endpoint
test_endpoint() {
    local endpoint=$1
    local expected_status=$2
    local description=$3

    print_status "Testing $description..."

    response=$(curl -s -w "%{http_code}" -o /tmp/response.json "http://localhost:7071$endpoint")
    status_code="${response: -3}"

    if [ "$status_code" = "$expected_status" ]; then
        print_success "$description - Status: $status_code"
        if [ -f /tmp/response.json ]; then
            echo "Response:"
            cat /tmp/response.json | python3 -m json.tool 2>/dev/null || cat /tmp/response.json
            echo ""
        fi
    else
        print_error "$description - Expected: $expected_status, Got: $status_code"
        if [ -f /tmp/response.json ]; then
            echo "Response:"
            cat /tmp/response.json
            echo ""
        fi
    fi
}

# Test endpoints
print_status "Testing function endpoints..."

test_endpoint "/api/health" "200" "Health Check Endpoint"
test_endpoint "/api/info" "200" "Info Endpoint"
test_endpoint "/api/hello" "200" "Hello World Endpoint (no name)"
test_endpoint "/api/hello?name=LocalTest" "200" "Hello World Endpoint (with name)"

# Test POST request
print_status "Testing POST request to Hello World endpoint..."
post_response=$(curl -s -w "%{http_code}" -o /tmp/post_response.json \
    -X POST \
    -H "Content-Type: application/json" \
    -d '{"name": "LocalTestPOST"}' \
    "http://localhost:7071/api/hello")

post_status="${post_response: -3}"
if [ "$post_status" = "200" ]; then
    print_success "POST request test - Status: $post_status"
    echo "Response:"
    cat /tmp/post_response.json | python3 -m json.tool 2>/dev/null || cat /tmp/post_response.json
    echo ""
else
    print_error "POST request test - Expected: 200, Got: $post_status"
fi

# Cleanup
print_status "Stopping Azure Functions runtime..."
kill $FUNC_PID 2>/dev/null || true
wait $FUNC_PID 2>/dev/null || true

# Clean up temp files
rm -f /tmp/response.json /tmp/post_response.json

print_success "Local testing completed!"
print_status "To run the function manually, use: func start --port 7071"
print_status "Function endpoints will be available at:"
echo "  - Health: http://localhost:7071/api/health"
echo "  - Info: http://localhost:7071/api/info"
echo "  - Hello: http://localhost:7071/api/hello?name=YourName"

# Return to original directory
cd ../..
