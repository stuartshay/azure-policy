# Terraform Version Management

This document describes the Terraform version management capabilities added to the Azure Policy project.

## Overview

The project now includes comprehensive Terraform version management using:
- **tfenv** - Terraform Version Manager for managing multiple Terraform versions
- **Version tracking scripts** - Custom scripts to check and update provider versions
- **Makefile integration** - Easy-to-use commands for version management

## Features

### 1. Terraform Version Management with tfenv

tfenv allows you to:
- Install and switch between multiple Terraform versions
- Pin specific versions per project using `.terraform-version` file
- Automatically use the correct version when entering the project directory

### 2. Provider Version Tracking

Track and manage provider versions across all Terraform modules:
- Display current provider versions across all modules
- Update provider versions consistently across the entire project
- Preview changes before applying them

### 3. Makefile Integration

All functionality is integrated into the Makefile for easy access.

## Installation

tfenv is automatically installed when you run:

```bash
./install.sh
```

Or manually install it:

```bash
# Linux
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# macOS
brew install tfenv
```

## Usage

### Check Current Versions

Display current Terraform and provider versions across all modules:

```bash
make terraform-check-versions
# or
make terraform-version
```

This shows:
- Current Terraform version
- tfenv status and available versions
- Project's pinned Terraform version (from `.terraform-version`)
- Provider versions for each module
- Summary of unique provider versions

### Update Provider Versions

#### Preview Changes (Dry Run)

Before making changes, preview what would be updated:

```bash
make terraform-update-providers-dry-run OLD_VERSION=4.37 NEW_VERSION=4.39
```

#### Apply Updates

Update provider versions across all modules:

```bash
make terraform-update-providers OLD_VERSION=4.37 NEW_VERSION=4.39
```

This will:
- Find all Terraform files with the specified provider
- Update version constraints from old to new version
- Create backups and verify changes
- Provide next steps for testing

### Set Terraform Version

Pin a specific Terraform version for the project:

```bash
make terraform-set-version VERSION=1.10.3
```

This will:
- Install the specified version via tfenv
- Set it as the active version
- Update the `.terraform-version` file

## Files and Scripts

### Configuration Files

- **`.terraform-version`** - Pins the Terraform version for this project
- **`install.sh`** - Installs tfenv and other tools

### Scripts

- **`scripts/terraform-version-check.sh`** - Displays version information
- **`scripts/terraform-update-providers.sh`** - Updates provider versions

### Makefile Targets

| Target | Description |
|--------|-------------|
| `terraform-version` | Show current Terraform version and tfenv status |
| `terraform-check-versions` | Alias for terraform-version |
| `terraform-update-providers` | Update provider versions (requires OLD_VERSION and NEW_VERSION) |
| `terraform-update-providers-dry-run` | Preview provider updates without changes |
| `terraform-set-version` | Set Terraform version using tfenv (requires VERSION) |

## Examples

### Example 1: Check Current Versions

```bash
$ make terraform-check-versions
=== Terraform Version Check ===

Terraform Version:
Terraform v1.12.2
on linux_amd64

Project Terraform Version (from .terraform-version):
1.10.3

Provider Versions by Module:

📁 Core Infrastructure
  azurerm: ~> 4.39
  random: ~> 3.4

📁 App Service
  azurerm: ~> 4.39
...
```

### Example 2: Update azurerm Provider

```bash
# Preview changes
$ make terraform-update-providers-dry-run OLD_VERSION=4.37 NEW_VERSION=4.39

# Apply changes
$ make terraform-update-providers OLD_VERSION=4.37 NEW_VERSION=4.39
```

### Example 3: Set Terraform Version

```bash
$ make terraform-set-version VERSION=1.10.3
Setting Terraform version...
Installing Terraform 1.10.3 via tfenv...
Terraform version set to 1.10.3
```

## Workflow for Dependabot Updates

When Dependabot creates a PR for provider updates:

1. **Check current versions:**
   ```bash
   make terraform-check-versions
   ```

2. **Preview the update:**
   ```bash
   make terraform-update-providers-dry-run OLD_VERSION=4.37 NEW_VERSION=4.39
   ```

3. **Apply the update:**
   ```bash
   make terraform-update-providers OLD_VERSION=4.37 NEW_VERSION=4.39
   ```

4. **Initialize and test:**
   ```bash
   make terraform-all-init
   make terraform-all-plan
   ```

5. **Commit changes:**
   ```bash
   git add .
   git commit -m "Update azurerm provider from 4.37 to 4.39"
   ```

## Advanced Usage

### Custom Provider Updates

The update script supports any HashiCorp provider:

```bash
./scripts/terraform-update-providers.sh \
  --provider azuread \
  --old-version 2.47 \
  --new-version 2.48 \
  --dry-run
```

### Manual tfenv Commands

```bash
# List available Terraform versions
tfenv list-remote

# Install specific version
tfenv install 1.10.3

# Use specific version
tfenv use 1.10.3

# List installed versions
tfenv list
```

## Troubleshooting

### tfenv Not Found

If tfenv is not found after installation:

1. Restart your shell or source your profile:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

2. Verify tfenv is in your PATH:
   ```bash
   echo $PATH | grep tfenv
   ```

3. Manually add to PATH if needed:
   ```bash
   export PATH="$HOME/.tfenv/bin:$PATH"
   ```

### Provider Update Issues

If provider updates fail:

1. Check file permissions
2. Ensure no files are locked by editors
3. Review the backup files created (`.backup` extension)
4. Run with `--dry-run` first to preview changes

### Version Conflicts

If you see version conflicts:

1. Check `.terraform-version` file
2. Verify tfenv is using the correct version:
   ```bash
   tfenv list
   terraform version
   ```

3. Manually set the version:
   ```bash
   tfenv use $(cat .terraform-version)
   ```

## Best Practices

1. **Always use dry-run first** when updating providers
2. **Pin Terraform versions** using `.terraform-version`
3. **Test after updates** with `terraform plan`
4. **Update incrementally** rather than jumping multiple versions
5. **Review provider changelogs** before updating
6. **Coordinate updates** across team members

## Integration with CI/CD

The version management tools work well in CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Check Terraform versions
  run: make terraform-check-versions

- name: Update providers
  run: make terraform-update-providers OLD_VERSION=4.37 NEW_VERSION=4.39
```

## Related Documentation

- [Terraform Documentation](../TERRAFORM_CLOUD_SETUP.md)
- [Infrastructure Documentation](../INFRASTRUCTURE.md)
- [Deployment Guide](../DEPLOYMENT_GUIDE.md)
