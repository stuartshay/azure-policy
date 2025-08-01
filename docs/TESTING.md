# Azure Policy Testing Framework

This directory contains comprehensive tests for the Azure Policy and Functions project, providing validation for policy definitions, integration testing, and infrastructure verification.

## 📁 Directory Structure

```
tests/
├── __init__.py                 # Package initialization
├── conftest.py                # Shared test fixtures and utilities
├── policies/                  # Azure Policy validation tests
│   ├── test_policy_validation.py    # JSON structure and syntax tests
│   └── test_existing_policies.py    # Tests for specific policy files
├── integration/               # Integration tests
│   └── test_azure_cli_integration.py  # Azure CLI simulation and live tests
├── infrastructure/           # Infrastructure testing (future)
└── utils/                   # Test utilities and helpers
```

## 🚀 Quick Start

### 1. Run All Tests
```bash
# From project root
./run-tests.sh all
```

### 2. Run Policy Validation Tests Only
```bash
./run-tests.sh policy
```

### 3. Run with Coverage Report
```bash
./run-tests.sh coverage
```

### 4. Validate Specific Policy File
```bash
./run-tests.sh validate policies/storage-naming-convention.json
```

## 🧪 Test Categories

### Policy Validation Tests (`tests/policies/`)

**Purpose**: Validate Azure Policy JSON files for syntax, structure, and compliance.

**What it tests**:
- ✅ JSON syntax validation
- ✅ Required fields (displayName, description, policyRule)
- ✅ Policy structure and schema compliance
- ✅ Parameter validation and types
- ✅ Naming convention compliance
- ✅ Effect values and policy rules
- ✅ Resource type targeting

**Example usage**:
```bash
# Run all policy tests
pytest tests/policies/ -v

# Test specific policy validation
pytest tests/policies/test_policy_validation.py::TestPolicyJSONValidation -v
```

### Integration Tests (`tests/integration/`)

**Purpose**: Test Azure CLI integration and policy deployment scenarios.

**What it tests**:
- ✅ Azure CLI command simulation
- ✅ Policy definition creation workflow
- ✅ Policy assignment scenarios
- ✅ Compliance checking simulation
- 🔒 Live Azure tests (optional, requires authentication)

**Example usage**:
```bash
# Run integration tests (simulation mode)
pytest tests/integration/ -v -m "not live"

# Run live tests (requires Azure CLI auth)
export AZURE_LIVE_TESTS=true
pytest tests/integration/ -v -m "live"
```

## 🔧 Configuration

### Test Configuration (`pytest.ini`)

The project uses pytest with the following key configurations:
- **Coverage**: Minimum 80% coverage required
- **Test discovery**: Automatic discovery of `test_*.py` files
- **Markers**: Custom markers for test categorization
- **Output**: Verbose output with HTML coverage reports

### Test Requirements (`requirements/test.txt`)

Testing dependencies include:
- `pytest` - Core testing framework
- `pytest-cov` - Coverage reporting
- `pytest-mock` - Mocking utilities
- `httpx` - HTTP testing for integration tests
- `jsonschema` - JSON validation

### Environment Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `AZURE_LIVE_TESTS` | Enable live Azure tests | `false` |
| `AZURE_SUBSCRIPTION_ID` | Test subscription ID | Mock value |
| `AZURE_TEST_RESOURCE_GROUP` | Test resource group | `rg-policy-test-dev-eastus` |

## 📊 Test Markers

Use pytest markers to run specific test categories:

```bash
# Run only policy validation tests
pytest -m "policy" -v

# Run integration tests excluding live tests
pytest -m "integration and not live" -v

# Run quick smoke tests
pytest -m "not slow" -v

# Skip live tests (default behavior)
pytest -m "not live" -v
```

Available markers:
- `policy` - Azure Policy validation tests
- `integration` - Integration tests with Azure CLI
- `live` - Tests requiring live Azure resources
- `slow` - Long-running tests
- `infrastructure` - Infrastructure/Terraform tests
- `functions` - Azure Functions tests

## 🔍 Testing Workflows

### 1. Policy Development Workflow

```bash
# 1. Create/modify policy file
vim policies/new-policy.json

# 2. Validate syntax and structure
./run-tests.sh validate policies/new-policy.json

# 3. Run full policy test suite
./run-tests.sh policy

# 4. Generate coverage report
./run-tests.sh coverage
```

### 2. Integration Testing Workflow

```bash
# 1. Test Azure CLI integration (simulation)
pytest tests/integration/ -v -m "not live"

# 2. Test with live Azure (optional)
az login
export AZURE_LIVE_TESTS=true
pytest tests/integration/ -v -m "live"
```

### 3. Continuous Integration Workflow

```bash
# Pre-commit testing
./run-tests.sh smoke

# Full test suite
./run-tests.sh all

# Generate reports for CI
./run-tests.sh report
```

## 📈 Coverage Reports

Coverage reports are generated in multiple formats:

1. **Terminal output**: Real-time coverage during test runs
2. **HTML report**: Detailed coverage at `htmlcov/index.html`
3. **Test report**: Comprehensive test results at `test-report.html`

```bash
# Generate coverage report
./run-tests.sh coverage

# Open HTML coverage report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

## 🛠️ Extending Tests

### Adding New Policy Tests

1. **Create test file**: `tests/policies/test_my_feature.py`
2. **Use fixtures**: Import shared fixtures from `conftest.py`
3. **Follow patterns**: Use existing test classes as templates
4. **Add markers**: Use appropriate pytest markers

Example:
```python
import pytest
from tests.conftest import PolicyTestHelper

class TestMyPolicyFeature:
    def test_my_policy_validation(self, policies_dir, policy_helper):
        # Your test implementation
        pass
```

### Adding Integration Tests

1. **Create test file**: `tests/integration/test_my_integration.py`
2. **Use simulation mode**: Default to Azure CLI simulation
3. **Add live tests**: Mark with `@pytest.mark.live` for optional live testing
4. **Mock external calls**: Use `responses` or `requests-mock` for HTTP mocking

### Custom Fixtures

Add shared fixtures to `conftest.py`:
```python
@pytest.fixture
def my_custom_fixture():
    # Setup
    yield fixture_value
    # Teardown
```

## 🚨 Troubleshooting

### Common Issues

**Import errors**:
```bash
# Install test dependencies
pip install -r requirements/test.txt
```

**Azure CLI not found**:
```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

**Permission denied on run-tests.sh**:
```bash
chmod +x run-tests.sh
```

**Coverage below threshold**:
```bash
# Check which lines need coverage
./run-tests.sh coverage
open htmlcov/index.html
```

### Debug Mode

Run tests with debug output:
```bash
pytest tests/ -v --tb=long --capture=no -s
```

### Parallel Execution

Speed up tests with parallel execution:
```bash
pytest tests/ -n auto  # Uses all available cores
pytest tests/ -n 4     # Uses 4 cores
```

## 📝 Best Practices

1. **Test isolation**: Each test should be independent
2. **Use fixtures**: Leverage shared fixtures for common setup
3. **Mock external dependencies**: Don't make real Azure calls in unit tests
4. **Descriptive names**: Test names should clearly indicate what they test
5. **Documentation**: Add docstrings to test classes and methods
6. **Markers**: Use appropriate markers for test categorization
7. **Coverage**: Aim for 80%+ coverage, focus on critical paths
8. **Performance**: Keep tests fast, use `slow` marker for long-running tests

## 🔗 Related Documentation

- [Main Project README](../README.md)
- [Azure Policy Documentation](../docs/POLICIES.md)
- [Contributing Guidelines](../docs/CONTRIBUTING.md)
- [GitHub Workflows](../.github/workflows/)

---

**💡 Tip**: Start with `./run-tests.sh help` to see all available testing commands and options.
