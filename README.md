# Azure Policy Setup

This repository contains tools to help you get started with Azure Policy.
The `install.sh` script installs the Azure CLI on macOS or Ubuntu/Debian-based
Linux systems. After installing the CLI you can authenticate with your Azure
account and begin working with policies.

## Prerequisites

- macOS with [Homebrew](https://brew.sh/) installed or
- Ubuntu/Debian Linux with `apt` or a compatible package manager
- A user account with permission to install software

## Installation

Run the `install.sh` script to install the Azure CLI:

```bash
./install.sh
```

After installation, authenticate with your Azure account:

```bash
az login
```

## Next steps

Once authenticated, you can start creating and assigning policies. See the
[Azure Policy documentation](https://learn.microsoft.com/azure/governance/policy/)
for guidance on authoring custom policies and managing policy assignments.
