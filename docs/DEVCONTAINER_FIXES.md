# DevContainer Build Fixes - Summary

This document summarizes the changes made to fix the DevContainer build issues and implement centralized requirements management.

## Issues Fixed

### 1. Duplicate Package Installation
**Problem**: Python packages were being installed in multiple places:
- Globally in Dockerfile
- In Azure Functions requirements.txt
- Again in post-create.sh virtual environment

**Solution**: Removed global pip installations from Dockerfile, centralized all requirements management.

### 2. Version Conflicts
**Problem**: Different versions specified in Dockerfile vs. function requirements.txt
- Dockerfile: `azure-functions>=1.18.0`
- Functions: `azure-functions==1.23.0`

**Solution**: Single source of truth for all package versions in centralized requirements.

### 3. Inefficient Build Process
**Problem**: Installing packages globally then creating virtual environment was redundant and slow.

**Solution**: Simplified Dockerfile to only install system dependencies and Azure Functions Core Tools.

## Changes Made

### New Files Created

1. **`requirements/base.txt`** - Core dependencies (Azure SDK, utilities)
2. **`requirements/dev.txt`** - Development tools (includes base.txt)
3. **`requirements/functions.txt`** - Minimal Azure Functions runtime dependencies
4. **`requirements.txt`** - Main development requirements (includes dev.txt)
5. **`requirements/README.md`** - Documentation for requirements management
6. **`scripts/validate-requirements.sh`** - Script to validate requirements setup

### Modified Files

1. **`.devcontainer/Dockerfile`**
   - Removed global pip package installations
   - Kept only system dependencies and Azure Functions Core Tools
   - Simplified build process

2. **`.devcontainer/post-create.sh`**
   - Added installation of development dependencies in workspace
   - Updated to use centralized requirements for Azure Functions

3. **`functions/basic/requirements.txt`**
   - Simplified to reference centralized functions requirements
   - Now contains: `-r ../../requirements/functions.txt`

4. **`README.md`**
   - Added "Requirements Management" section
   - Documented new dependency management approach

## Benefits Achieved

1. **Faster Builds**: Dockerfile no longer installs Python packages globally
2. **No Version Conflicts**: Single source of truth for all package versions
3. **Clear Separation**: Development vs. production dependencies are clearly separated
4. **Easy Maintenance**: Update package versions in one place
5. **Better Documentation**: Clear instructions for managing dependencies

## Usage

### For Development
```bash
pip install -r requirements.txt
```

### For Azure Functions Deployment
```bash
cd functions/basic
pip install -r requirements.txt  # References ../../requirements/functions.txt
```

### Adding New Dependencies
- **Core dependencies**: Add to `requirements/base.txt`
- **Development tools**: Add to `requirements/dev.txt`
- **Function runtime**: Add to `requirements/functions.txt`

## Validation

Run the validation script to check the setup:
```bash
./scripts/validate-requirements.sh
```

## Next Steps

1. Test the DevContainer rebuild to ensure all issues are resolved
2. Verify Azure Functions can start successfully
3. Consider adding pip-tools for requirements compilation and dependency resolution
4. Monitor for any remaining build issues

## Files Structure

```
azure-policy/
├── requirements/
│   ├── base.txt           # Core dependencies
│   ├── dev.txt            # Development tools
│   ├── functions.txt      # Function runtime deps
│   └── README.md          # Documentation
├── requirements.txt       # Main dev requirements
├── functions/basic/
│   └── requirements.txt   # References ../../requirements/functions.txt
├── scripts/
│   └── validate-requirements.sh  # Validation script
└── .devcontainer/
    ├── Dockerfile         # Simplified (no global pip installs)
    └── post-create.sh     # Updated to use centralized requirements
