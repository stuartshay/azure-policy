#!/bin/bash

# Post-create script for Azure Functions development environment

echo "Setting up Azure Functions development environment..."

# Configure zsh as default shell for user
echo "Configuring zsh as default shell..."
sudo chsh -s "$(which zsh)" vscode
echo 'export SHELL=$(which zsh)' >> ~/.bashrc

# Navigate to project directory
cd /azure-policy || exit

# Make scripts executable
echo "Making scripts executable..."
chmod +x scripts/*.sh 2>/dev/null || echo "No shell scripts found"
chmod +x scripts/*.ps1 2>/dev/null || echo "No PowerShell scripts found"

# Set up git safe directory
echo "Configuring git..."
git config --global --add safe.directory /azure-policy

# Setup PowerShell modules and profile
echo "Setting up PowerShell environment..."
pwsh -Command "& /azure-policy/scripts/Install-PowerShellModules.ps1 -Force -SkipPublisherCheck" || echo "PowerShell module installation completed with warnings"
pwsh -Command "& /azure-policy/scripts/Setup-PowerShellProfile.ps1 -Force" || echo "PowerShell profile setup completed"

# Install additional IaC tools not covered by DevContainer features
echo "Installing terraform-docs..."
TERRAFORM_DOCS_VERSION=$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep tag_name | cut -d '"' -f 4)
wget -O terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz"
tar -xzf terraform-docs.tar.gz
chmod +x terraform-docs
sudo mv terraform-docs /usr/local/bin/
rm terraform-docs.tar.gz
echo "terraform-docs installed: $(terraform-docs --version)"

echo "Installing Checkov..."
pip install --user checkov
echo "Checkov installed: $(checkov --version)"

# Install development dependencies in the main workspace
echo "Installing Python development dependencies..."
cd /azure-policy || exit
pip install --user -r requirements.txt

# Navigate to functions directory
echo "Setting up Azure Functions..."
cd /azure-policy/functions/basic || exit

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
echo "Azure Functions & Infrastructure development environment setup complete!"
echo ""
echo "🔧 Available tools:"
echo "   • Python 3.13 with venv support"
echo "   • Azure CLI for cloud management"
echo "   • Azure Functions Core Tools for local development"
echo "   • GitHub CLI for repository management"
echo "   • PowerShell for Azure automation and scripting"
echo "   • Terraform for Infrastructure as Code"
echo "   • Terragrunt for DRY Terraform configurations"
echo "   • tflint for Terraform linting and validation"
echo "   • terraform-docs for generating documentation"
echo "   • Checkov for security and compliance scanning"
echo ""
echo "🚀 To start developing:"
echo ""
echo "Azure Functions:"
echo "1. cd functions/basic"
echo "2. source .venv/bin/activate"
echo "3. func start"
echo ""
echo "Terraform Infrastructure:"
echo "1. cd infrastructure/terraform"
echo "2. terraform init"
echo "3. terraform plan"
echo ""
echo "📚 Your services will be available at:"
echo "- Azure Functions: http://localhost:7071"
echo "  • Hello World: http://localhost:7071/api/hello"
echo "  • Health Check: http://localhost:7071/api/health"
echo "  • Info: http://localhost:7071/api/info"
echo "- Azurite Storage Emulator: http://localhost:10000"
echo ""
echo "🎯 Quick commands:"
echo "- terraform --version"
echo "- terragrunt --version"
echo "- tflint --version"
echo "- terraform-docs --version"
echo "- checkov --version"
