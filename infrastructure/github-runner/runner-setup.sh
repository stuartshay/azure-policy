#!/bin/bash
# GitHub Actions Self-Hosted Runner Setup Script
# This script installs and configures a GitHub Actions runner on Ubuntu
# NOTE: This is a Terraform template file - variables are interpolated by Terraform

# shellcheck disable=SC2154  # Variables are provided by Terraform template
set -e

# Variables (passed from Terraform)
GITHUB_TOKEN="${github_token}"
GITHUB_REPO_URL="${github_repo_url}"
RUNNER_NAME="${runner_name}"
RUNNER_LABELS="${runner_labels}"

echo "🚀 Setting up GitHub Actions Self-Hosted Runner"
echo "Repository: $GITHUB_REPO_URL"
echo "Runner Name: $RUNNER_NAME"
echo "Runner Labels: $RUNNER_LABELS"

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    jq \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Docker (for container-based actions)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Create runner user
useradd -m -s /bin/bash actions-runner
usermod -aG docker actions-runner

# Create actions-runner directory
mkdir -p /home/actions-runner/actions-runner
cd /home/actions-runner/actions-runner

# Download latest runner
# shellcheck disable=SC2034  # LATEST_VERSION is used in the lines below
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//')
# shellcheck disable=SC1083  # Terraform template syntax requires double braces
curl -o "actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz" -L "https://github.com/actions/runner/releases/download/v$${LATEST_VERSION}/actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz"

# Extract runner
# shellcheck disable=SC1083  # Terraform template syntax requires double braces
tar xzf "actions-runner-linux-x64-$${LATEST_VERSION}.tar.gz"

# Set ownership
chown -R actions-runner:actions-runner /home/actions-runner

# Get registration token
REPO_NAME=$(echo "$GITHUB_REPO_URL" | sed 's/.*github.com\///')
REGISTRATION_TOKEN=$(curl -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO_NAME/actions/runners/registration-token" | jq -r '.token')

echo "📝 Registering runner with GitHub..."

# Configure runner as actions-runner user
sudo -u actions-runner ./config.sh \
  --url "$GITHUB_REPO_URL" \
  --token "$REGISTRATION_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --work _work \
  --unattended

# Install and start runner service
./svc.sh install actions-runner
./svc.sh start

echo "✅ GitHub Actions runner setup completed!"
echo "Runner '$RUNNER_NAME' is now registered and running"

# Install additional tools for Azure deployments
sudo -u actions-runner bash << 'EOF'
# Install Node.js (for Azure Functions)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Python and pip
sudo apt-get install -y python3 python3-pip

# Install Azure Functions Core Tools
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y azure-functions-core-tools-4

echo "🔧 Additional tools installed successfully"
EOF

echo "🎯 Runner setup complete! The runner is ready to execute GitHub Actions workflows."
