# Documentation

This directory contains all project documentation following the Azure Policy project's documentation standards.

## 📋 Available Documentation

### Setup and Configuration
- [Azure Secrets Setup](AZURE_SECRETS_SETUP.md) - How to configure Azure authentication for GitHub Actions
- [DevContainer Setup](DEVCONTAINER_TESTING.md) - Development container configuration and testing
- [Workspace Path Configuration](WORKSPACE_PATH_FIX.md) - Fixing workspace path issues

### Operations and Troubleshooting
- [Azurite Setup](AZURITE.md) - Local Azure Storage emulator configuration
- [DevContainer Fixes](DEVCONTAINER_FIXES.md) - Common DevContainer issues and solutions
- [Troubleshooting Guide](TROUBLESHOOTING.md) - General troubleshooting tips

## 📁 Documentation Structure Rules

All markdown files (except root-level README.md, CHANGELOG.md, CONTRIBUTING.md, LICENSE.md) should be placed in this `docs/` folder to maintain a clean repository structure.

### Enforcement

The documentation structure is enforced through:

1. **Pre-commit hooks** - Validates file placement before commits
2. **GitHub Actions** - Checks documentation structure on pull requests
3. **Helper script** - `scripts/organize-docs.sh` to automatically organize files

### Root-level Exceptions

These markdown files are allowed at the repository root:
- `README.md` - Main project documentation
- `CHANGELOG.md` - Version history and changes
- `CONTRIBUTING.md` - Contribution guidelines
- `LICENSE.md` - Project license
- `CODE_OF_CONDUCT.md` - Community guidelines

## 🛠️ Managing Documentation

### Adding New Documentation

When creating new `.md` files:

1. **Create directly in docs/ folder**:
   ```bash
   touch docs/NEW_FEATURE.md
   ```

2. **Or use the organization script** if you created it elsewhere:
   ```bash
   ./scripts/organize-docs.sh
   ```

### Organization Script

The `scripts/organize-docs.sh` script helps maintain documentation structure:

```bash
# Preview what would be moved (dry run)
./scripts/organize-docs.sh --dry-run

# Actually move misplaced files
./scripts/organize-docs.sh
```

### Pre-commit Validation

Before committing, pre-commit hooks will check:
- ✅ All markdown files are in correct locations
- ✅ JSON files are valid
- ✅ Scripts pass linting
- ✅ No secrets are committed

## 🔗 External Documentation

- [Azure Policy Documentation](https://docs.microsoft.com/en-us/azure/governance/policy/)
- [Azure Functions Documentation](https://docs.microsoft.com/en-us/azure/azure-functions/)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 📝 Writing Standards

When adding documentation:

1. **Use clear, descriptive titles**
2. **Include table of contents for longer documents**
3. **Add code examples where applicable**
4. **Link to related documentation**
5. **Update this README when adding new major documentation**

## 🔄 Maintenance

This documentation index is automatically updated by GitHub Actions when new documentation is added. If you notice missing documentation, please update this README or use the organization script to ensure proper structure.
