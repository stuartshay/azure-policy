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

# Function to install Terraform
install_terraform() {
  # Check if Terraform is already installed
  if command -v terraform >/dev/null 2>&1; then
    echo "Terraform is already installed: $(terraform --version | head -n1)"
    return 0
  fi

  if [[ "$OS" == "Linux" ]]; then
    if command -v apt >/dev/null 2>&1; then
      echo "Installing Terraform using apt..."

      # Check if HashiCorp repository is already configured
      if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
        echo "Adding HashiCorp GPG key..."
        # Use timeout to prevent hanging
        timeout 30 wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        if [ $? -ne 0 ]; then
          echo "Failed to download HashiCorp GPG key. Trying alternative method..."
          # Alternative: download directly
          curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        fi
      else
        echo "HashiCorp GPG key already exists, skipping..."
      fi

      # Check if repository is already added
      if [ ! -f /etc/apt/sources.list.d/hashicorp.list ]; then
        echo "Adding HashiCorp repository..."
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
      else
        echo "HashiCorp repository already configured, skipping..."
      fi

      echo "Updating package list..."
      sudo apt update >/dev/null 2>&1 || echo "Warning: Package update had issues, continuing..."

      echo "Installing Terraform package..."
      sudo apt install -y terraform

      echo "Terraform installation complete."
    elif command -v yum >/dev/null 2>&1; then
      echo "Installing Terraform using yum..."
      sudo yum install -y yum-utils
      sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      sudo yum install -y terraform

      echo "Terraform installation complete."
    fi
  elif [[ "$OS" == "Darwin" ]]; then
    echo "Installing Terraform using Homebrew..."
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform

    echo "Terraform installation complete."
  fi

  # Verify installation
  if command -v terraform >/dev/null 2>&1; then
    echo "Terraform version: $(terraform --version | head -n1)"
  else
    echo "Warning: Terraform installation may have failed." >&2
  fi
}

# Function to install Terragrunt
install_terragrunt() {
  if [[ "$OS" == "Linux" ]]; then
    echo "Installing Terragrunt..."
    # Get latest version
    TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '"' -f 4)
    wget -O terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64"
    chmod +x terragrunt
    sudo mv terragrunt /usr/local/bin/

    echo "Terragrunt installation complete."
  elif [[ "$OS" == "Darwin" ]]; then
    echo "Installing Terragrunt using Homebrew..."
    brew install terragrunt

    echo "Terragrunt installation complete."
  fi

  # Verify installation
  if command -v terragrunt >/dev/null 2>&1; then
    echo "Terragrunt version: $(terragrunt --version)"
  else
    echo "Warning: Terragrunt installation may have failed." >&2
  fi
}

# Function to install tflint
install_tflint() {
  # Check if tflint is already installed
  if command -v tflint >/dev/null 2>&1; then
    echo "tflint is already installed: $(tflint --version)"
    return 0
  fi

  if [[ "$OS" == "Linux" ]]; then
    echo "Installing tflint..."

    # Install unzip if not present
    if ! command -v unzip >/dev/null 2>&1; then
      echo "Installing unzip dependency..."
      if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y unzip
      elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y unzip
      fi
    fi

    # Get latest version and install manually
    TFLINT_VERSION=$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | grep tag_name | cut -d '"' -f 4)
    wget -O tflint.zip "https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip"
    unzip tflint.zip
    chmod +x tflint
    sudo mv tflint /usr/local/bin/
    rm tflint.zip

    echo "tflint installation complete."
  elif [[ "$OS" == "Darwin" ]]; then
    echo "Installing tflint using Homebrew..."
    brew install tflint

    echo "tflint installation complete."
  fi

  # Verify installation
  if command -v tflint >/dev/null 2>&1; then
    echo "tflint version: $(tflint --version)"
  else
    echo "Warning: tflint installation may have failed." >&2
  fi
}

# Function to install terraform-docs
install_terraform_docs() {
  if [[ "$OS" == "Linux" ]]; then
    echo "Installing terraform-docs..."
    # Get latest version
    TERRAFORM_DOCS_VERSION=$(curl -s https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep tag_name | cut -d '"' -f 4)
    wget -O terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/${TERRAFORM_DOCS_VERSION}/terraform-docs-${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz"
    tar -xzf terraform-docs.tar.gz
    chmod +x terraform-docs
    sudo mv terraform-docs /usr/local/bin/
    rm terraform-docs.tar.gz

    echo "terraform-docs installation complete."
  elif [[ "$OS" == "Darwin" ]]; then
    echo "Installing terraform-docs using Homebrew..."
    brew install terraform-docs

    echo "terraform-docs installation complete."
  fi

  # Verify installation
  if command -v terraform-docs >/dev/null 2>&1; then
    echo "terraform-docs version: $(terraform-docs --version)"
  else
    echo "Warning: terraform-docs installation may have failed." >&2
  fi
}

# Function to install Checkov
install_checkov() {
  echo "Installing Checkov..."
  # Install using pip3.13
  sudo python3.13 -m pip install checkov

  # Verify installation
  if command -v checkov >/dev/null 2>&1; then
    echo "Checkov version: $(checkov --version)"
  else
    echo "Warning: Checkov installation may have failed." >&2
  fi

  echo "Checkov installation complete."
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
    echo "* GitHub CLI is not installed. Installation may have failed."
    return 1
  fi

  echo "* GitHub CLI is installed: $(gh --version | head -n1)"
  echo ""

  # Check authentication status
  if gh auth status &> /dev/null; then
    echo "* Already authenticated with GitHub"
    gh auth status
  else
    echo ">> GitHub authentication setup:"
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

  echo ">> Useful GitHub CLI Commands:"
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

# Function to install Node.js via nvm
install_nodejs() {
  # Check if Node.js is already installed
  if command -v node >/dev/null 2>&1; then
    current_version=$(node --version)
    echo "Node.js is already installed: $current_version"
    echo "npm version: $(npm --version)"

    # Check if it's a recent version (v20+ is acceptable)
    major_version=$(echo $current_version | sed 's/v\([0-9]*\).*/\1/')
    if [ "$major_version" -ge 20 ]; then
      echo "Node.js version is acceptable (v20+), skipping installation."
      return 0
    else
      echo "Node.js version is outdated, will install latest via nvm."
    fi
  fi

  echo "Installing Node.js 24 (LTS) via nvm..."

  # Install nvm if not present
  if ! command -v nvm >/dev/null 2>&1 && [ ! -s "$HOME/.nvm/nvm.sh" ]; then
    echo "Installing nvm (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

    # Source nvm for current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  else
    echo "nvm is already installed, sourcing..."
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  fi

  # Install Node.js 24 (latest LTS)
  echo "Installing Node.js 24 (latest LTS)..."
  nvm install 24
  nvm use 24
  nvm alias default 24

  # Update npm to latest version
  echo "Updating npm to latest version..."
  npm install -g npm@latest

  echo "Node.js installation complete."

  # Verify installation
  if command -v node >/dev/null 2>&1; then
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
    echo "nvm version: $(nvm --version)"
  else
    echo "Warning: Node.js installation may have failed." >&2
    echo "You may need to restart your shell or run: source ~/.bashrc"
  fi

  # Add nvm sourcing to shell profiles if not already present
  echo "Ensuring nvm is available in future shell sessions..."

  # For bash
  if [ -f "$HOME/.bashrc" ] && ! grep -q "NVM_DIR" "$HOME/.bashrc"; then
    echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc"
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.bashrc"
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$HOME/.bashrc"
  fi

  # For zsh
  if [ -f "$HOME/.zshrc" ] && ! grep -q "NVM_DIR" "$HOME/.zshrc"; then
    echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.zshrc"
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "$HOME/.zshrc"
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> "$HOME/.zshrc"
  fi
}

# Function to install Azurite (Azure Storage Emulator)
install_azurite() {
  # Check if Azurite is already installed
  if command -v azurite >/dev/null 2>&1; then
    echo "Azurite is already installed: $(azurite --version)"
    return 0
  fi

  echo "Installing Azurite (Azure Storage Emulator)..."

  # Check if npm is available
  if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required for Azurite installation."

    # Try to source nvm if it exists
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
      echo "Attempting to source nvm..."
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # Try to use the default node version
      nvm use default 2>/dev/null || nvm use node 2>/dev/null || true
    fi

    # Check again if npm is now available
    if ! command -v npm >/dev/null 2>&1; then
      echo "WARNING: npm still not available. Node.js installation might need a shell restart."
      echo "   After restarting your shell, run: npm install -g azurite"
      return 1
    fi
  fi

  # Install Azurite globally via npm
  echo "Installing Azurite via npm..."
  npm install -g azurite

  # Verify installation
  if command -v azurite >/dev/null 2>&1; then
    echo "Azurite installation complete."
    echo "Azurite version: $(azurite --version)"
  else
    echo "WARNING: Azurite installation may have failed or requires a shell restart."
    echo "   After restarting your shell, run: npm install -g azurite"
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
      # Ensure Node.js is installed first
      if ! command -v npm >/dev/null 2>&1; then
        install_nodejs
      fi
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

# Function to setup Azurite data directory
setup_azurite_directory() {
  echo "Setting up Azurite data directory..."

  # Navigate to project root
  cd "$(dirname "$0")"

  # Create azurite-data directory if it doesn't exist
  if [ ! -d "azurite-data" ]; then
    mkdir -p azurite-data
    echo "* Created azurite-data directory"
  else
    echo "* azurite-data directory already exists"
  fi

  # Set appropriate permissions
  chmod 755 azurite-data

  echo "Azurite data directory setup complete."
}

# Function to extract hook information from .pre-commit-config.yaml
extract_precommit_hooks() {
  local config_file=".pre-commit-config.yaml"

  if [ ! -f "$config_file" ]; then
    echo "Unable to read pre-commit configuration"
    return 1
  fi

  # Extract hook categories and tools using grep and awk (excluding commented lines)
  echo "Key hooks configured:"

  # Python tools
  if grep -v "^\s*#" "$config_file" | grep -q "black\|isort\|flake8\|bandit"; then
    local python_tools=""
    grep -v "^\s*#" "$config_file" | grep -q "black" && python_tools="black"
    grep -v "^\s*#" "$config_file" | grep -q "isort" && python_tools="${python_tools:+$python_tools, }isort"
    grep -v "^\s*#" "$config_file" | grep -q "flake8" && python_tools="${python_tools:+$python_tools, }flake8"
    grep -v "^\s*#" "$config_file" | grep -q "bandit" && python_tools="${python_tools:+$python_tools, }bandit"
    [ -n "$python_tools" ] && echo "  - Python: $python_tools"
  fi

  # Terraform tools
  if grep -v "^\s*#" "$config_file" | grep -q "terraform"; then
    local terraform_tools=""
    grep -v "^\s*#" "$config_file" | grep -q "terraform_fmt" && terraform_tools="terraform_fmt"
    grep -v "^\s*#" "$config_file" | grep -q "terraform_validate" && terraform_tools="${terraform_tools:+$terraform_tools, }terraform_validate"
    grep -v "^\s*#" "$config_file" | grep -q "terraform_docs" && terraform_tools="${terraform_tools:+$terraform_tools, }terraform_docs"
    grep -v "^\s*#" "$config_file" | grep -q "terraform_tflint" && terraform_tools="${terraform_tools:+$terraform_tools, }tflint"
    grep -v "^\s*#" "$config_file" | grep -q "terraform_checkov" && terraform_tools="${terraform_tools:+$terraform_tools, }checkov"
    [ -n "$terraform_tools" ] && echo "  - Terraform: $terraform_tools"
  fi

  # PowerShell
  grep -v "^\s*#" "$config_file" | grep -q "powershell\|PSScriptAnalyzer" && echo "  - PowerShell: PSScriptAnalyzer"

  # Shell
  grep -v "^\s*#" "$config_file" | grep -q "shellcheck" && echo "  - Shell: shellcheck"

  # Secrets detection (only if not commented out)
  grep -v "^\s*#" "$config_file" | grep -q "detect-secrets" && echo "  - Secrets: detect-secrets"

  # General file checks
  if grep -v "^\s*#" "$config_file" | grep -q "trailing-whitespace\|end-of-file-fixer\|check-yaml\|check-json"; then
    echo "  - General: trailing whitespace, file endings, JSON/YAML validation"
  fi

  # Azure specific
  if grep -v "^\s*#" "$config_file" | grep -q "azure-policy-validation\|bicep-validation\|docs-folder-enforcement"; then
    local azure_tools=""
    grep -v "^\s*#" "$config_file" | grep -q "azure-policy-validation" && azure_tools="Policy JSON validation"
    grep -v "^\s*#" "$config_file" | grep -q "bicep-validation" && azure_tools="${azure_tools:+$azure_tools, }Bicep validation"
    grep -v "^\s*#" "$config_file" | grep -q "docs-folder-enforcement" && azure_tools="${azure_tools:+$azure_tools, }Documentation structure"
    [ -n "$azure_tools" ] && echo "  - Azure: $azure_tools"
  fi
}

# Function to install pre-commit and setup hooks
install_precommit() {
  echo "Installing pre-commit and setting up hooks..."

  # Check if pre-commit is already installed
  if command -v pre-commit >/dev/null 2>&1; then
    echo "pre-commit is already installed: $(pre-commit --version)"
  else
    echo "Installing pre-commit..."
    if [[ "$OS" == "Linux" ]]; then
      # Install using pip3.13 (more reliable than apt)
      sudo python3.13 -m pip install pre-commit
    elif [[ "$OS" == "Darwin" ]]; then
      brew install pre-commit
    fi

    # Verify installation
    if command -v pre-commit >/dev/null 2>&1; then
      echo "pre-commit installed successfully: $(pre-commit --version)"
    else
      echo "Warning: pre-commit installation may have failed." >&2
      return 1
    fi
  fi

  # Navigate to project root
  cd "$(dirname "$0")"

  # Check if .pre-commit-config.yaml exists
  if [ -f .pre-commit-config.yaml ]; then
    echo "* Using existing .pre-commit-config.yaml configuration"
  else
    echo "Creating basic .pre-commit-config.yaml..."
    cat > .pre-commit-config.yaml << 'EOF'
# Azure Policy & Functions Pre-commit Configuration
# This file configures pre-commit hooks to maintain code quality and consistency

repos:
  # General file formatting and checks
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
        exclude: '\.md$'
      - id: end-of-file-fixer
      - id: check-yaml
        args: ['--allow-multiple-documents']
      - id: check-json
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict

  # Python formatting and linting
  - repo: https://github.com/psf/black
    rev: 25.1.0
    hooks:
      - id: black
        language_version: python3
        args: ['--line-length=88']

  - repo: https://github.com/pycqa/flake8
    rev: 7.1.1
    hooks:
      - id: flake8
        args: ['--max-line-length=88', '--extend-ignore=E203,W503']

  # Shell script linting
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.10.0.1
    hooks:
      - id: shellcheck
        args: ['--severity=warning']

# Configuration for specific hooks
default_language_version:
  python: python3.13
EOF
    echo "* Created basic .pre-commit-config.yaml - consider customizing for your needs"
  fi

  # Create secrets baseline if it doesn't exist (only if detect-secrets is configured and not commented)
  if grep -v "^\s*#" .pre-commit-config.yaml | grep -q "detect-secrets" && [ ! -f .secrets.baseline ]; then
    echo "Creating secrets baseline..."
    pre-commit run detect-secrets --all-files || true
    if [ ! -f .secrets.baseline ]; then
      echo '{}' > .secrets.baseline
    fi
    echo "* Created .secrets.baseline"
  elif grep -q "detect-secrets" .pre-commit-config.yaml; then
    echo "* detect-secrets is configured but commented out - skipping baseline creation"
  fi

  # Install the git hooks
  echo "Installing pre-commit hooks..."
  pre-commit install

  # Install commit-msg hook for conventional commits (optional)
  pre-commit install --hook-type commit-msg || echo "Note: commit-msg hook not configured"

  echo "* Pre-commit hooks installed successfully!"

  # Run hooks on all files to ensure everything is working
  echo "Running pre-commit on all files to verify setup..."
  pre-commit run --all-files || echo "WARNING: Some hooks failed. This is normal for first run - files may have been auto-fixed."

  echo ""
  echo ">> Pre-commit setup complete!"
  echo ""
  echo "Pre-commit will now automatically run on:"
  echo "  - Every git commit (validates staged files)"
  echo "  - Manual execution: pre-commit run --all-files"
  echo ""

  # Extract and display hook information from the config file
  extract_precommit_hooks

  echo ""
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
echo "=== Installing Node.js ==="
install_nodejs

echo ""
echo "=== Installing Azurite (Azure Storage Emulator) ==="
install_azurite

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
echo "=== Installing Terraform ==="
install_terraform

echo ""
echo "=== Installing Terragrunt ==="
install_terragrunt

echo ""
echo "=== Installing tflint ==="
install_tflint

echo ""
echo "=== Installing terraform-docs ==="
install_terraform_docs

echo ""
echo "=== Installing Checkov ==="
install_checkov

echo ""
echo "=== Installing Pre-commit ==="
install_precommit

echo ""
echo "=== Setting up Azurite Data Directory ==="
setup_azurite_directory

echo ""
echo "=== Installation Summary ==="
echo "Python version: $(python3.13 --version 2>/dev/null || echo 'Not found')"
echo "nvm version: $(nvm --version 2>/dev/null || echo 'Not found - restart shell to activate')"
echo "Node.js version: $(node --version 2>/dev/null || echo 'Not found - restart shell to activate')"
echo "npm version: $(npm --version 2>/dev/null || echo 'Not found - restart shell to activate')"
echo "Azurite version: $(azurite --version 2>/dev/null || echo 'Not found - install after Node.js is active')"
echo "Azure CLI version: $(az --version 2>/dev/null | head -n1 || echo 'Not found')"
echo "Azure Functions Core Tools version: $(func --version 2>/dev/null || echo 'Not found')"
echo "GitHub CLI version: $(gh --version 2>/dev/null | head -n1 || echo 'Not found')"
echo "PowerShell version: $(pwsh --version 2>/dev/null || echo 'Not found')"
echo "Terraform version: $(terraform --version 2>/dev/null | head -n1 || echo 'Not found')"
echo "Terragrunt version: $(terragrunt --version 2>/dev/null || echo 'Not found')"
echo "tflint version: $(tflint --version 2>/dev/null || echo 'Not found')"
echo "terraform-docs version: $(terraform-docs --version 2>/dev/null || echo 'Not found')"
echo "Checkov version: $(checkov --version 2>/dev/null || echo 'Not found')"
echo "Pre-commit version: $(pre-commit --version 2>/dev/null || echo 'Not found')"
echo "jq version: $(jq --version 2>/dev/null || echo 'Not found')"
echo ""
echo "Installation complete!"
echo ""
echo "WARNING: Node.js was installed via nvm"
echo "   You need to restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
echo "   Then run: ./scripts/post-install.sh to complete Node.js/Azurite setup"
echo ""
echo ">> Next steps:"
echo "1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
echo "2. Verify Node.js: node --version (should show v24.x.x)"
echo "3. Install Azurite: npm install -g azurite"
echo "4. Authenticate with Azure: az login"
echo "5. Authenticate with GitHub: gh auth login"
echo "6. Start Azurite: azurite --silent --location ./azurite-data --debug ./azurite-data/debug.log"
echo "7. Navigate to functions: cd functions/basic"
echo "8. Setup Python environment: python3.13 -m venv .venv && source .venv/bin/activate"
echo "9. Install Python dependencies: pip install -r requirements.txt"
echo "10. Start Azure Functions: func start"
echo "11. Pre-commit hooks are ready - they'll run automatically on git commits"
echo ""
echo ">> You're ready for Azure Policy & Functions development!"
echo ""
echo ">> Available tools:"
echo "   - Python 3.13 with venv support"
echo "   - nvm (Node Version Manager) with Node.js 24 LTS"
echo "   - npm for JavaScript package management"
echo "   - Azurite for local Azure Storage emulation"
echo "   - Azure CLI for cloud management"
echo "   - Azure Functions Core Tools for local development"
echo "   - GitHub CLI for repository management"
echo "   - PowerShell for Azure automation and scripting"
echo "   - Terraform for Infrastructure as Code"
echo "   - Terragrunt for DRY Terraform configurations"
echo "   - tflint for Terraform linting and validation"
echo "   - terraform-docs for generating documentation"
echo "   - Checkov for security and compliance scanning"
echo "   - Pre-commit for code quality and consistency"
echo "   - jq for JSON processing (perfect for CLI output parsing)"
echo ""
echo ">> Quick reference:"
echo "   - Azure Functions: http://localhost:7071 (when running)"
echo "   - Azurite Storage: http://localhost:10000 (blob), http://localhost:10001 (queue), http://localhost:10002 (table)"
echo "   - Azurite data: ./azurite-data/ directory"
echo "   - Documentation: Check README.md for detailed setup"
echo "   - Troubleshooting: See TROUBLESHOOTING.md"
echo ""
