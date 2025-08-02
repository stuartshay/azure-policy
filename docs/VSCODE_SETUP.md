# VS Code Configuration for Azure Policy Project

This directory contains VS Code workspace configuration files that provide a consistent development environment for all team members.

## Files Overview

### `settings.json`
- **Python Configuration**: Sets up Python interpreter path and testing framework
- **Testing Configuration**: Enables pytest with proper test discovery and arguments
- **Azure Functions**: Configures Azure Functions development environment
- **Formatting & Linting**: Sets up Black formatter and Pylint
- **Terminal**: Configures default shell and environment variables

### `launch.json`
Debug configurations for:
- **Azure Functions**: Debug Azure Functions locally
- **Python Files**: Debug individual Python files
- **Test Debugging**: Multiple configurations for debugging tests:
  - Debug all tests
  - Debug current test file
  - Debug specific test categories (policy, integration, infrastructure)
  - Debug tests with coverage

### `tasks.json`
Pre-configured tasks for:
- **Test Execution**:
  - Run All Tests
  - Run Tests with Coverage
  - Run Policy Tests
  - Run Integration Tests
  - Run Infrastructure Tests
  - Run Function Tests
- **Development**:
  - Start Azure Functions
  - Install Dependencies
  - Format Code
  - Lint Code

### `extensions.json`
Recommended extensions for:
- Python development and testing
- Azure development tools
- Code formatting and linting
- Git integration

## Test Configuration

### Test Discovery
- Tests are automatically discovered in the `tests/` directory
- Pytest is configured as the primary test framework
- Test files follow the pattern `test_*.py`

### Running Tests

#### Via VS Code Test Explorer
1. Open the Test Explorer panel (Testing icon in sidebar)
2. Tests will be automatically discovered
3. Click the play button to run individual tests or test suites

#### Via Command Palette
1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
2. Type "Python: Run All Tests" or "Python: Run Current Test File"

#### Via Tasks
1. Press `Ctrl+Shift+P` and type "Tasks: Run Task"
2. Select from available test tasks:
   - Run All Tests
   - Run Tests with Coverage
   - Run Policy Tests
   - Run Integration Tests
   - Run Infrastructure Tests

#### Via Terminal
```bash
# Activate virtual environment
source functions/basic/.venv/bin/activate

# Run all tests
python -m pytest tests/ -v

# Run with coverage
python -m pytest tests/ -v --cov=. --cov-report=html

# Run specific test categories
python -m pytest tests/policies/ -v -m policy
python -m pytest tests/integration/ -v -m integration
```

### Debugging Tests

#### Debug Current Test File
1. Open a test file
2. Press `F5` or use "Run and Debug" panel
3. Select "Python: Debug Current Test File"

#### Debug Specific Tests
1. Set breakpoints in your test code
2. Use the debug configurations in the "Run and Debug" panel
3. Select the appropriate debug configuration for your needs

### Test Markers

The project uses pytest markers to categorize tests:
- `@pytest.mark.policy` - Policy validation tests
- `@pytest.mark.integration` - Integration tests requiring Azure CLI
- `@pytest.mark.infrastructure` - Infrastructure/Terraform tests
- `@pytest.mark.functions` - Azure Functions tests
- `@pytest.mark.slow` - Slow-running tests
- `@pytest.mark.live` - Tests requiring live Azure resources

### Coverage Reports

Coverage reports are generated in the `htmlcov/` directory when running tests with coverage. Open `htmlcov/index.html` in a browser to view detailed coverage information.

## Getting Started

1. **Install Recommended Extensions**: VS Code will prompt you to install recommended extensions when you open the workspace
2. **Activate Python Environment**: The Python interpreter should automatically point to `./functions/basic/.venv/bin/python`
3. **Run Tests**: Open the Test Explorer or use `Ctrl+Shift+P` → "Python: Run All Tests"
4. **Debug Tests**: Set breakpoints and use the debug configurations in the "Run and Debug" panel

## Troubleshooting

### Tests Not Discovered
- Ensure the Python interpreter is set to `./functions/basic/.venv/bin/python`
- Check that pytest is installed in the virtual environment
- Reload the VS Code window (`Ctrl+Shift+P` → "Developer: Reload Window")

### Debug Configuration Issues
- Verify the Python interpreter path in settings
- Ensure the virtual environment is activated
- Check that the working directory is correct in launch configurations

### Task Execution Problems
- Verify that the virtual environment exists at `functions/basic/.venv/`
- Ensure all dependencies are installed
- Check terminal output for specific error messages
