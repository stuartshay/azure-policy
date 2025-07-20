#!/bin/bash

# Post-create script for Azure Functions development environment

echo "Setting up Azure Functions development environment..."

# Navigate to workspace
cd /workspace

# Make scripts executable
echo "Making scripts executable..."
chmod +x scripts/*.sh

# Set up git safe directory
echo "Configuring git..."
git config --global --add safe.directory /workspace

# Navigate to functions directory
echo "Setting up Azure Functions..."
cd functions/basic

# Create Python virtual environment for Azure Functions
echo "Creating Python virtual environment..."
python3 -m venv .venv
source .venv/bin/activate

# Upgrade pip first
echo "Upgrading pip..."
pip install --upgrade pip

# Install Azure Functions dependencies
echo "Installing Azure Functions dependencies..."
pip install -r requirements.txt

# Create local settings if it doesn't exist
if [ ! -f "local.settings.json" ]; then
    echo "Creating local.settings.json..."
    cp local.settings.json.template local.settings.json
fi

# Update local.settings.json with container-specific Azurite connection
echo "Updating local.settings.json for container environment..."
cat > local.settings.json << 'EOF'
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;QueueEndpoint=http://azurite:10001/devstoreaccount1;TableEndpoint=http://azurite:10002/devstoreaccount1;",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "AzureWebJobsFeatureFlags": "EnableWorkerIndexing",
    "AZURE_STORAGE_CONNECTION_STRING": "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://azurite:10000/devstoreaccount1;QueueEndpoint=http://azurite:10001/devstoreaccount1;TableEndpoint=http://azurite:10002/devstoreaccount1;",
    "WEBSITE_HOSTNAME": "localhost:7071"
  },
  "Host": {
    "LocalHttpPort": 7071,
    "CORS": "*",
    "CORSCredentials": false
  }
}
EOF

# Wait for Azurite to be ready
echo "Waiting for Azurite to be ready..."
timeout=30
while ! nc -z azurite 10000 && [ $timeout -gt 0 ]; do
    echo "Waiting for Azurite... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout - 2))
done

if [ $timeout -le 0 ]; then
    echo "Warning: Azurite may not be ready yet. You may need to restart the functions manually."
else
    echo "Azurite is ready!"
fi

echo ""
echo "Azure Functions development environment setup complete!"
echo ""
echo "To start developing:"
echo "1. cd functions/basic"
echo "2. source .venv/bin/activate"
echo "3. func start"
echo ""
echo "Your functions will be available at:"
echo "- Hello World: http://localhost:7071/api/hello"
echo "- Health Check: http://localhost:7071/api/health"  
echo "- Info: http://localhost:7071/api/info"
