#!/usr/bin/env bash
# This script installs Azure CLI and Python 3.13 using the appropriate package manager for
# macOS or Ubuntu/Debian-based Linux. It checks the operating system and
# invokes the official installation commands from Microsoft and Python.
set -e

OS="$(uname)"

# Function to install Python 3.13
install_python313() {
  if [[ "$OS" == "Linux" ]]; then
    if command -v apt >/dev/null 2>&1; then
      echo "Installing Python 3.13 using apt..."
      # Add deadsnakes PPA for Python 3.13
      sudo apt update
      sudo apt install -y software-properties-common
      sudo add-apt-repository -y ppa:deadsnakes/ppa
      sudo apt update
      sudo apt install -y python3.13 python3.13-venv python3.13-dev
      
      # Install pip for Python 3.13
      curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.13
      
      # Install setuptools (replaces distutils in Python 3.12+)
      sudo python3.13 -m pip install setuptools
      
      # Note: Not creating global symlinks to avoid breaking system tools
      echo "Python 3.13 installed successfully. Use 'python3.13' to invoke it."
      
      echo "Python 3.13 installation complete."
    elif command -v yum >/dev/null 2>&1; then
      echo "Installing Python 3.13 using yum..."
      # For RHEL/CentOS, we'll compile from source
      sudo yum groupinstall -y "Development Tools"
      sudo yum install -y openssl-devel libffi-devel bzip2-devel sqlite-devel
      
      cd /tmp
      wget https://www.python.org/ftp/python/3.13.1/Python-3.13.1.tgz
      tar xzf Python-3.13.1.tgz
      cd Python-3.13.1
      ./configure --enable-optimizations
      make altinstall
      
      # Create symlinks
      sudo ln -sf /usr/local/bin/python3.13 /usr/bin/python3.13
      echo "Python 3.13 installed successfully. Use 'python3.13' to invoke it."
      
      echo "Python 3.13 installation complete."
    fi
  elif [[ "$OS" == "Darwin" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew is required but not found. Please install Homebrew first:" >&2
      echo "https://brew.sh/" >&2
      exit 1
    fi
    echo "Installing Python 3.13 using Homebrew..."
    brew update
    brew install python@3.13
    
    # Create symlinks
    brew link --force python@3.13
    echo "Python 3.13 installed successfully. Use 'python3.13' to invoke it."
    
    echo "Python 3.13 installation complete."
  fi
  
  # Verify Python 3.13 installation
  if command -v python3.13 >/dev/null 2>&1; then
    echo "Python 3.13 version: $(python3.13 --version)"
  else
    echo "Warning: Python 3.13 installation may have failed." >&2
  fi
}
# Function to install Azure Functions Core Tools
install_azure_functions_tools() {
  if [[ "$OS" == "Linux" ]]; then
    if command -v apt >/dev/null 2>&1; then
      echo "Installing Azure Functions Core Tools using apt..."
      # Install prerequisites
      sudo apt update
      sudo apt install -y curl gpg lsb-release
      
      # Add Microsoft package repository
      curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
      echo "deb [arch=amd64,armhf,arm64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/dotnetdev.list
      
      sudo apt update
      sudo apt install -y azure-functions-core-tools-4
      
      echo "Azure Functions Core Tools installation complete."
    elif command -v yum >/dev/null 2>&1; then
      echo "Installing Azure Functions Core Tools using npm..."
      # Install Node.js and npm if not present
      curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
      sudo yum install -y nodejs
      sudo npm install -g azure-functions-core-tools@4 --unsafe-perm true
      
      echo "Azure Functions Core Tools installation complete."
    fi
  elif [[ "$OS" == "Darwin" ]]; then
    echo "Installing Azure Functions Core Tools using Homebrew..."
    brew tap azure/functions
    brew install azure-functions-core-tools@4
    
    echo "Azure Functions Core Tools installation complete."
  fi
  
  # Verify installation
  if command -v func >/dev/null 2>&1; then
    echo "Azure Functions Core Tools version: $(func --version)"
  else
    echo "Warning: Azure Functions Core Tools installation may have failed." >&2
  fi
}

# Install Python 3.13 first
echo "=== Installing Python 3.13 ==="
install_python313

echo ""
echo "=== Installing Azure CLI ==="

if [[ "$OS" == "Linux" ]]; then
  if command -v apt >/dev/null 2>&1; then
    echo "Installing Azure CLI using apt..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  elif command -v yum >/dev/null 2>&1; then
    echo "Installing Azure CLI using yum..."
    curl -sL https://aka.ms/InstallAzureCLIRpm | sudo bash
  else
    echo "Unsupported Linux distribution. Please install Azure CLI manually." >&2
    exit 1
  fi
elif [[ "$OS" == "Darwin" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required but not found. Please install Homebrew first:" >&2
    echo "https://brew.sh/" >&2
    exit 1
  fi
  echo "Installing Azure CLI using Homebrew..."
  brew update && brew install azure-cli
else
  echo "Unsupported operating system: $OS" >&2
  exit 1
fi

echo ""
echo "=== Installing Azure Functions Core Tools ==="
install_azure_functions_tools

echo ""
echo "=== Installation Summary ==="
echo "Python version: $(python3.13 --version 2>/dev/null || echo 'Not found')"
echo "Azure CLI version: $(az --version 2>/dev/null | head -n1 || echo 'Not found')"
echo "Azure Functions Core Tools version: $(func --version 2>/dev/null || echo 'Not found')"
echo ""
echo "Installation complete! You can now run 'az login' to authenticate with Azure."

