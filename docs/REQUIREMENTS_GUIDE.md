# Azure Functions Requirements and Testing Guide

## Overview

This project uses a centralized requirements structure to manage dependencies across different Azure Functions and testing scenarios. This ensures consistency and makes dependency management more maintainable.

## Requirements Structure

```
requirements/
├── base.txt           # Core Azure SDK and runtime dependencies
├── functions.txt      # Minimal requirements for Azure Functions deployment
├── dev.txt           # Development and code quality tools
└── test.txt          # Comprehensive testing dependencies

functions/
├── basic/
│   ├── requirements.txt       # References ../../requirements/functions.txt
│   └── requirements-test.txt  # Test deps + runtime deps for this function
└── advanced/
    ├── requirements.txt       # References ../../requirements/functions.txt
    └── requirements-test.txt  # Test deps + runtime deps for this function
```

## Requirements Files Explained

### Core Requirements Files

1. **`requirements/base.txt`** - Contains core Azure SDK packages and fundamental dependencies
2. **`requirements/functions.txt`** - Minimal requirements for Azure Functions runtime deployment
3. **`requirements/dev.txt`** - Development tools (black, pylint, flake8, etc.) + testing
4. **`requirements/test.txt`** - Comprehensive testing framework and utilities

### Function-Specific Requirements

1. **`functions/*/requirements.txt`** - References the centralized `functions.txt`
2. **`functions/*/requirements-test.txt`** - Includes runtime requirements + test dependencies

## Testing Rules and Best Practices

### 1. Package Installation Rules

**ALWAYS follow this sequence when updating dependencies:**

```bash
# 1. Update the appropriate centralized requirements file first
vim requirements/functions.txt  # or base.txt, dev.txt, test.txt

# 2. Ensure function-specific requirements reference the centralized file
echo "-r ../../requirements/functions.txt" > functions/basic/requirements.txt

# 3. Update test requirements to include both runtime and test deps
# See example in functions/basic/requirements-test.txt
```

### 2. GitHub Actions Testing Requirements

The GitHub Actions workflow now follows this pattern:

```yaml
- name: 'Resolve Project Dependencies Using Pip'
  run: |
    pushd '${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}'
    python -m pip install --upgrade pip

    # Install runtime dependencies for deployment
    pip install -r requirements.txt --target=".python_packages/lib/site-packages"

    # For testing, also install test dependencies to the current environment
    pip install -r requirements-test.txt
    popd

- name: 'Run Unit Tests'
  run: |
    pushd '${{ env.AZURE_FUNCTIONAPP_PACKAGE_PATH }}'
    python -m pytest tests/ -v --cov=. --cov-report=xml --cov-report=term
    popd
```

### 3. Local Development Testing

For local testing, always use the test requirements:

```bash
# Navigate to the function directory
cd functions/basic

# Install test dependencies (includes runtime deps)
pip install -r requirements-test.txt

# Run tests
python -m pytest tests/ -v --cov=. --cov-report=term
```

### 4. Adding New Dependencies

When adding new dependencies, follow these rules:

#### Runtime Dependencies (needed in production)
1. Add to `requirements/functions.txt` or `requirements/base.txt`
2. Ensure version is pinned for reproducible builds
3. Test locally and in CI/CD

#### Test-Only Dependencies
1. Add to `requirements/test.txt`
2. Update function-specific `requirements-test.txt` if needed
3. Ensure all functions that need it reference the test requirements

#### Development Dependencies
1. Add to `requirements/dev.txt`
2. Include in pre-commit hooks if applicable

### 5. Version Management Rules

- **Pin all versions** for reproducible builds
- **Use exact versions** (==) for critical dependencies
- **Use minimum versions** (>=) only for testing utilities when flexibility is needed
- **Update regularly** but test thoroughly

## Common Testing Dependencies

The test requirements include:

- `pytest` - Main testing framework
- `pytest-cov` - Coverage reporting
- `pytest-asyncio` - Async testing support
- `pytest-mock` - Mocking utilities
- `httpx` - HTTP client for integration tests
- `requests-mock` - Mock HTTP requests
- `freezegun` - Mock datetime objects
- `responses` - Mock HTTP responses

## Troubleshooting

### Test Failures in CI/CD

1. **Missing Dependencies**: Ensure `requirements-test.txt` includes all needed packages
2. **Version Conflicts**: Check for version mismatches between requirements files
3. **Import Errors**: Verify the function-specific requirements.txt references the correct centralized file

### Local vs CI Differences

1. **Python Version**: CI uses Python 3.11, ensure local environment matches
2. **Environment Variables**: Check `local.settings.json` for local testing
3. **Path Issues**: Ensure relative paths in requirements files are correct

### Deprecation Warnings

The codebase has been updated to use modern Python practices:
- `datetime.utcnow()` replaced with `datetime.now(timezone.utc)`
- All datetime objects now use timezone-aware formatting

## Example Requirements Files

### functions/basic/requirements-test.txt
```
# Testing requirements for Azure Functions - Basic
# This file contains test dependencies in addition to the runtime requirements

# Include runtime requirements
-r requirements.txt

# Testing framework
pytest>=8.4.1
pytest-cov>=6.2.1
pytest-asyncio>=0.25.0
pytest-mock>=3.14.0

# HTTP testing utilities
httpx>=0.28.0
requests-mock>=1.12.1

# Test utilities for mocking and responses
responses>=0.25.0
freezegun>=1.5.1

# Better test output
pytest-clarity>=1.0.1
pytest-sugar>=1.0.0
```

## Validation Commands

Before committing changes, run these validation commands:

```bash
# Test basic function
cd functions/basic
python -m pytest tests/ -v --cov=. --cov-report=term

# Test advanced function
cd functions/advanced
python -m pytest tests/ -v --cov=. --cov-report=term

# Run all tests from root
python -m pytest functions/*/tests/ -v

# Check for dependency conflicts
pip check
```

## GitHub Actions Integration

The updated workflow ensures:
1. ✅ Proper dependency installation order
2. ✅ Consistent test environment setup
3. ✅ Coverage reporting
4. ✅ Artifact creation without test files
5. ✅ Function-specific deployment paths

## Summary

This requirements structure ensures:
- **Consistency** across all functions
- **Maintainability** through centralized dependency management
- **Reproducibility** through version pinning
- **Flexibility** for function-specific needs
- **CI/CD reliability** through proper dependency resolution

Always update the centralized requirements files first, then update function-specific files to reference them.
