#!/bin/bash

# Debug script to simulate CI environment issues
echo "=== CI Environment Debug Script ==="
echo "Current working directory: $(pwd)"
echo "User: $(whoami)"
echo "Home directory: $HOME"
echo

echo "=== File Existence Check ==="
echo "Checkov config exists: $(test -f .checkov.yaml && echo 'YES' || echo 'NO')"
echo "Pre-commit config exists: $(test -f .pre-commit-config.yaml && echo 'YES' || echo 'NO')"
echo

echo "=== Python Environment ==="
echo "Python version: $(python --version)"
echo "Python path: $(which python)"
echo "Pip version: $(pip --version)"
echo

echo "=== Tool Availability ==="
echo "PowerShell version: $(pwsh --version 2>/dev/null || echo 'PowerShell not available')"
echo "Azure CLI version: $(az --version 2>/dev/null | head -1 || echo 'Azure CLI not available')"
echo "Terraform version: $(terraform --version 2>/dev/null | head -1 || echo 'Terraform not available')"
echo "TFLint version: $(tflint --version 2>/dev/null || echo 'TFLint not available')"
echo "Checkov version: $(checkov --version 2>/dev/null || echo 'Checkov not available')"
echo "jq version: $(jq --version 2>/dev/null || echo 'jq not available')"
echo "shellcheck version: $(shellcheck --version 2>/dev/null | head -1 || echo 'shellcheck not available')"
echo

echo "=== PowerShell Module Check ==="
if command -v pwsh >/dev/null 2>&1; then
    echo "PSScriptAnalyzer available: $(pwsh -Command 'Get-Module -ListAvailable PSScriptAnalyzer | Select-Object -First 1' 2>/dev/null || echo 'Not available')"
else
    echo "PowerShell not available for module check"
fi
echo

echo "=== Pre-commit Environment ==="
echo "Pre-commit version: $(pre-commit --version 2>/dev/null || echo 'pre-commit not available')"
echo "Pre-commit config validation:"
pre-commit validate-config 2>&1 || echo "Validation failed"
echo

echo "=== Pre-commit Cache ==="
echo "Cache directory: ~/.cache/pre-commit"
echo "Cache exists: $(test -d ~/.cache/pre-commit && echo 'YES' || echo 'NO')"
if [ -d ~/.cache/pre-commit ]; then
    echo "Cache size: $(du -sh ~/.cache/pre-commit 2>/dev/null || echo 'Cannot determine')"
fi
echo

echo "=== Environment Variables ==="
echo "HOME: $HOME"
echo "USER: $USER"
echo "PATH: $PATH"
echo "GITHUB_WORKSPACE: ${GITHUB_WORKSPACE:-'Not set'}"
echo

echo "=== Test Individual Hooks ==="
echo "Testing critical hooks individually..."

echo "1. Testing YAML validation:"
pre-commit run check-yaml --all-files 2>&1 | head -3

echo "2. Testing PowerShell formatter:"
pre-commit run powershell-format --all-files 2>&1 | head -3

echo "3. Testing Checkov:"
pre-commit run terraform_checkov --all-files 2>&1 | head -3

echo "4. Testing actionlint:"
pre-commit run actionlint --all-files 2>&1 | head -3

echo "=== Debug completed ==="
