#!/usr/bin/env bash
# This script installs Azure CLI using the appropriate package manager for
# macOS or Ubuntu/Debian-based Linux. It checks the operating system and
# invokes the official installation commands from Microsoft.
set -e

OS="$(uname)"

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

echo "Azure CLI installation complete. You can now run 'az login' to authenticate."

