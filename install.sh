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
# Function to install jq (JSON processor)
install_jq() {
  if [[ "$OS" == "Linux" ]]; then
    if command -v apt >/dev/null 2>&1; then
      echo "Installing jq using apt..."
      sudo apt update
      sudo apt install -y jq

      echo "jq installation complete."
    elif command -v yum >/dev/null 2>&1; then
      echo "Installing jq using yum..."
      sudo yum install -y jq

      echo "jq installation complete."
    fi
  elif [[ "$OS" == "Darwin" ]]; then
    echo "Installing jq using Homebrew..."
    brew install jq

    echo "jq installation complete."
  fi

  # Verify installation
  if command -v jq >/dev/null 2>&1; then
    echo "jq version: $(jq --version)"
  else
    echo "Warning: jq installation may have failed." >&2
  fi
}

# Function to install PowerShell
install_powershell() {
  # Check if PowerShell is already installed
  if command -v pwsh >/dev/null 2>&1; then
    echo "PowerShell is already installed: $(pwsh --version)"
    return 0
  fi

  if [[ "$OS" == "Linux" ]]; then
    if command -v apt >/dev/null 2>&1; then
      echo "Installing PowerShell using apt..."

      # Check if GPG key already exists
      if [ ! -f /usr/share/keyrings/microsoft-prod.gpg ]; then
        echo "Adding Microsoft GPG key..."
        curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
      else
        echo "Microsoft GPG key already exists, skipping..."
      fi

      # Check if repository is already added
      if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
        echo "Adding Microsoft repository..."
        echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -rs)-prod $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/microsoft-prod.list > /dev/null
      else
        echo "Microsoft repository already configured, skipping..."
      fi

      # Update the list of packages and install PowerShell
      echo "Updating package list..."
      sudo apt update >/dev/null 2>&1 || echo "Warning: Package update had issues, continuing..."

      echo "Installing PowerShell package..."
      sudo apt install -y powershell

      echo "PowerShell installation complete."
    elif command -v yum >/dev/null 2>&1; then
      echo "Installing PowerShell using yum..."
      # Register the Microsoft RedHat repository
      curl -sSL https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm | sudo rpm -i

      # Update package index and install PowerShell
      sudo dnf update -y
      sudo dnf install -y powershell

      echo "PowerShell installation complete."
    fi
  elif [[ "$OS" == "Darwin" ]]; then
    echo "Installing PowerShell using Homebrew..."
    brew install --cask powershell

    echo "PowerShell installation complete."
  fi

  # Verify installation
  if command -v pwsh >/dev/null 2>&1; then
    echo "PowerShell version: $(pwsh --version)"
  else
    echo "Warning: PowerShell installation may have failed." >&2
  fi
}

# Function to install GitHub CLI
install_github_cli() {
  if [[ "$OS" == "Linux" ]]; then
    if command -v apt >/dev/null 2>&1; then
      echo "Installing GitHub CLI using apt..."
      # Add GitHub CLI repository
      sudo mkdir -p -m 755 /etc/apt/keyrings
      wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
      sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

      sudo apt update
      sudo apt install -y gh

      echo "GitHub CLI installation complete."
    elif command -v yum >/dev/null 2>&1; then
      echo "Installing GitHub CLI using yum..."
      sudo dnf install -y 'dnf-command(config-manager)'
      sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      sudo dnf install -y gh

      echo "GitHub CLI installation complete."
    fi
  elif [[ "$OS" == "Darwin" ]]; then
    echo "Installing GitHub CLI using Homebrew..."
    brew install gh

    echo "GitHub CLI installation complete."
  fi

  # Verify installation
  if command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI version: $(gh --version | head -n1)"
  else
    echo "Warning: GitHub CLI installation may have failed." >&2
  fi
}

# Function to setup GitHub CLI authentication and configuration
setup_github_cli() {
  echo "Setting up GitHub CLI configuration..."

  # Check if GitHub CLI is installed
  if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI is not installed. Installation may have failed."
    return 1
  fi

  echo "✅ GitHub CLI is installed: $(gh --version | head -n1)"
  echo ""

  # Check authentication status
  if gh auth status &> /dev/null; then
    echo "✅ Already authenticated with GitHub"
    gh auth status
  else
    echo "🔐 GitHub authentication setup:"
    echo ""
    echo "To authenticate with GitHub, run:"
    echo "  gh auth login"
    echo ""
    echo "This will allow you to:"
    echo "- Create and manage pull requests"
    echo "- Create and manage issues"
    echo "- Clone private repositories"
    echo "- Run GitHub Actions workflows"
    echo ""
  fi

  echo "🚀 Useful GitHub CLI Commands:"
  echo ""
  echo "Repository Management:"
  echo "  gh repo view                    # View current repository"
  echo "  gh repo clone <owner/repo>      # Clone a repository"
  echo "  gh repo create                  # Create a new repository"
  echo "  gh api repos/:owner/:repo/branches | jq length  # Count branches"
  echo "  gh api repos/:owner/:repo/branches --jq '.[].name'  # List branch names"
  echo ""
  echo "Pull Requests:"
  echo "  gh pr create                    # Create a pull request"
  echo "  gh pr list                      # List pull requests"
  echo "  gh pr view [number]             # View a specific PR"
  echo "  gh pr checkout [number]         # Checkout a PR branch"
  echo "  gh pr merge [number]            # Merge a pull request"
  echo ""
  echo "Issues:"
  echo "  gh issue create                 # Create an issue"
  echo "  gh issue list                   # List issues"
  echo "  gh issue view [number]          # View a specific issue"
  echo ""
  echo "Workflows (GitHub Actions):"
  echo "  gh workflow list                # List workflows"
  echo "  gh workflow run [workflow]      # Run a workflow"
  echo "  gh run list                     # List workflow runs"
  echo "  gh run view [run-id]            # View workflow run details"
  echo ""
  echo "Aliases available in zsh:"
  echo "  ghpr, ghprs, ghprv, ghprl, ghrepo, ghissue, ghissues, ghclone, ghauth"
  echo ""
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
echo "=== Installing jq (JSON processor) ==="
install_jq

echo ""
echo "=== Installing Azure Functions Core Tools ==="
install_azure_functions_tools

echo ""
echo "=== Installing PowerShell ==="
install_powershell

echo ""
echo "=== Installing GitHub CLI ==="
install_github_cli

echo ""
echo "=== Setting up GitHub CLI ==="
setup_github_cli

echo ""
echo "=== Installation Summary ==="
echo "Python version: $(python3.13 --version 2>/dev/null || echo 'Not found')"
echo "Azure CLI version: $(az --version 2>/dev/null | head -n1 || echo 'Not found')"
echo "Azure Functions Core Tools version: $(func --version 2>/dev/null || echo 'Not found')"
echo "GitHub CLI version: $(gh --version 2>/dev/null | head -n1 || echo 'Not found')"
echo "PowerShell version: $(pwsh --version 2>/dev/null || echo 'Not found')"
echo "jq version: $(jq --version 2>/dev/null || echo 'Not found')"
echo ""
echo "Installation complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Authenticate with Azure: az login"
echo "2. Authenticate with GitHub: gh auth login"
echo "3. Navigate to functions: cd functions/basic"
echo "4. Setup Python environment: python3.13 -m venv .venv && source .venv/bin/activate"
echo "5. Install Python dependencies: pip install -r requirements.txt"
echo ""
echo "🚀 You're ready for Azure Policy & Functions development!"
echo ""
echo "🔧 Available tools:"
echo "   • Python 3.13 with venv support"
echo "   • Azure CLI for cloud management"
echo "   • Azure Functions Core Tools for local development"
echo "   • GitHub CLI for repository management"
echo "   • PowerShell for Azure automation and scripting"
echo "   • jq for JSON processing (perfect for CLI output parsing)"
echo ""
echo "📚 Quick reference:"
echo "   • Azure Functions: http://localhost:7071 (when running)"
echo "   • Documentation: Check README.md for detailed setup"
echo "   • Troubleshooting: See TROUBLESHOOTING.md"
echo ""

