# Azure Policy & Functions Development Environment

[![Pre-commit](https://github.com/stuartshay/azure-policy/workflows/Pre-commit/badge.svg)](https://github.com/stuartshay/azure-policy/actions/workflows/pre-commit.yml)

This repository contains tools and examples for Azure Policy management and Azure Functions development, with a complete DevContainer setup for streamlined development.

## Repository Structure

### Core Directories
- **`policies/`** - Azure Policy definitions and examples
- **`scripts/`** - Azure CLI scripts for policy management
- **`functions/basic/`** - Azure Functions with HTTP triggers (Python 3.13)
- **`infrastructure/`** - Terraform infrastructure as code
- **`tests/`** - Comprehensive testing framework (81% coverage)
  - `policies/` - Policy validation and fragment testing
  - `integration/` - Azure CLI integration tests
  - `infrastructure/` - Infrastructure testing
  - `utils/` - Testing utilities and helpers

### Configuration & Documentation
- **`docs/`** - Complete project documentation
  - `TESTING.md` - Testing framework guide
  - `TROUBLESHOOTING.md` - Common issues and solutions
  - `REQUIREMENTS.md` - Dependency management guide
  - And 15+ other specialized guides
- **`requirements/`** - Centralized dependency management
  - `base.txt` - Core dependencies
  - `dev.txt` - Development tools
  - `functions.txt` - Azure Functions runtime
  - `test.txt` - Testing framework dependencies
- **`.devcontainer/`** - Complete development environment setup
- **`.vscode/`** - VS Code configuration and recommended extensions
- **`.github/`** - GitHub workflows and project guidelines

### Configuration Files
- **`pytest.ini`** - Testing configuration with coverage settings
- **`run-tests.sh`** - Test runner with multiple execution modes
- **`.pre-commit-config.yaml`** - Code quality and validation hooks

## Features

### Azure Policy Tools

- Policy definitions and examples with validation testing
- Azure CLI scripts for policy management
- Compliance reporting tools
- Policy fragment testing and validation

### Azure Functions

- Python 3.13 with Azure Functions v4
- HTTP triggers with "Hello World" example
- Health check and info endpoints
- Comprehensive testing with pytest (81% coverage)
- Local development with Azurite storage emulator

### Testing Framework

- **Comprehensive Coverage**: 81% code coverage across all components
- **Policy Testing**: Validation for complete policies and fragments
- **Integration Testing**: Azure CLI and cloud service integration
- **Infrastructure Testing**: Terraform and resource validation
- **Multiple Test Modes**: Smoke tests, full tests, coverage reports
- **Test Runner**: Simple `./run-tests.sh` script with category options

### Development Environment

- **DevContainer**: Complete containerized development environment
- **Python 3.13**: Latest Python runtime
- **Azure CLI**: For Azure resource management
- **Azure Functions Core Tools**: For local function development
- **GitHub CLI**: For repository and pull request management
- **Azurite**: Local Azure Storage emulator
- **VS Code Extensions**: Recommended extensions for optimal development experience
- **Pre-commit Hooks**: Automated code quality and validation

## Quick Start

### Using DevContainer (Recommended)

1. **Prerequisites**: Docker and VS Code with Dev Containers extension
2. Open this repository in VS Code
3. When prompted, click "Reopen in Container" or use Command Palette: `Dev Containers: Reopen in Container`
4. Wait for the container to build and setup to complete (this may take 5-10 minutes on first run)
5. **Verify setup**: Run `./start-functions.sh` to verify everything is working

### Azure Policy Management

After the DevContainer is running:

```bash
# Authenticate with Azure
az login

# Run policy management scripts
cd scripts
./menu.sh
```

### Azure Functions Development

```bash
# Navigate to the functions directory
cd functions/basic

# Activate the Python virtual environment
source .venv/bin/activate

# Start the Azure Functions (Azurite runs automatically in DevContainer)
func start
```

The functions will be available at:

- Hello World: `http://localhost:7071/api/hello`
- Health Check: `http://localhost:7071/api/health`
- Info: `http://localhost:7071/api/info`

### Environment Validation with Jupyter Notebooks

This repository includes Jupyter Notebooks for interactive Azure environment validation and analysis:

```bash
# Start Jupyter Lab
./scripts/start-jupyter.sh

# Or manually start Jupyter Lab
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser
```

**Key Notebooks:**
- **`notebooks/environment_validation.ipynb`** - Comprehensive Azure environment validation
  - ✅ Azure authentication verification
  - 📊 Subscription access validation
  - 🔍 Resource quota checking for East US and East US 2
  - 💰 Cost estimation for Elastic Premium SKUs
  - 🚦 Deployment readiness assessment
  - 📈 Interactive cost visualization and analysis

**Features:**
- Interactive Azure SDK integration
- Real-time quota and resource checking
- Cost analysis with charts and visualizations
- Deployment readiness validation
- Export validation reports to JSON

Access Jupyter Lab at: `http://localhost:8888` (when running locally)

## Manual Setup (Alternative)

If you prefer not to use DevContainer:

### Prerequisites

- Python 3.13
- Azure CLI
- Azure Functions Core Tools v4
- GitHub CLI
- Docker (for Azurite)

### Installation

1. Install all development tools:

   ```bash
   ./install.sh
   ```

2. Authenticate with Azure and GitHub:

   ```bash
   az login
   gh auth login
   ```

3. Set up Azure Functions:

   ```bash
   cd functions/basic
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

4. Start Azurite (in a separate terminal):

   ```bash
   azurite --silent --location /tmp/azurite --debug /tmp/azurite/debug.log
   ```

5. Start Azure Functions:

   ```bash
   func start
   ```

## Requirements Management

This project uses a centralized requirements management system to avoid version conflicts and simplify dependency management:

- **`requirements/base.txt`** - Core dependencies (Azure SDK, utilities)
- **`requirements/dev.txt`** - Development tools (includes base.txt)
- **`requirements/functions.txt`** - Minimal Azure Functions runtime dependencies
- **`requirements/test.txt`** - Testing framework dependencies (pytest, coverage, mocking)
- **`requirements.txt`** - Main development requirements (includes dev.txt)

### Installing Dependencies

```bash
# Install all development dependencies
pip install -r requirements.txt

# Install only function runtime dependencies
cd functions/basic
pip install -r requirements.txt

# Install only testing dependencies
pip install -r requirements/test.txt
```

### Adding New Dependencies

1. **Core dependencies** (needed everywhere): Add to `requirements/base.txt`
2. **Development tools** (testing, linting): Add to `requirements/dev.txt`
3. **Function-specific runtime**: Add to `requirements/functions.txt`
4. **Testing framework**: Add to `requirements/test.txt`

See `requirements/README.md` for detailed documentation.

## Development Workflow

### Azure Policy Development

1. Create or modify policy definitions in `policies/`
2. Validate policies: `./run-tests.sh policies`
3. Use scripts in `scripts/` to deploy and manage policies
4. Run integration tests: `./run-tests.sh integration`
5. Test policy compliance and remediation

### Azure Functions Development

1. Modify functions in `functions/basic/function_app.py`
2. Run tests: `./run-tests.sh` or `python -m pytest tests/ -v`
3. Format code: `black .` (automatic with pre-commit hooks)
4. Test locally with `func start`
5. Validate with coverage: `./run-tests.sh coverage`

### Testing Workflow

1. **Smoke tests**: `./run-tests.sh smoke` - Quick validation
2. **Full tests**: `./run-tests.sh` - Complete test suite with coverage
3. **Category tests**: `./run-tests.sh [policies|integration|infrastructure]`
4. **Coverage analysis**: Check `htmlcov/index.html` after running coverage tests

### VS Code Integration

The repository includes comprehensive VS Code configuration:

- **Extensions**: Automatically installs recommended extensions
- **Tasks**: Pre-configured tasks for common operations
- **Debugging**: Launch configurations for Azure Functions
- **Settings**: Optimized settings for Python and Azure development
- **Testing**: Integrated pytest runner with coverage support

## Available Scripts

### Environment Setup

- `start-functions.sh` - Verify and setup Azure Functions development environment
- `start-jupyter.sh` - Start Jupyter Lab for interactive Azure environment validation
- `run-tests.sh` - Comprehensive test runner with multiple execution modes

### Testing Scripts

- `./run-tests.sh` - Run all tests with coverage
- `./run-tests.sh smoke` - Quick smoke tests for fast validation
- `./run-tests.sh policies` - Policy validation tests only
- `./run-tests.sh integration` - Azure CLI integration tests only
- `./run-tests.sh infrastructure` - Infrastructure tests only
- `./run-tests.sh coverage` - Generate detailed coverage reports

### DevContainer Testing

- `test-devcontainer.sh` - Complete DevContainer build and test suite
- `quick-rebuild-devcontainer.sh` - Fast rebuild for iterative development
- `debug-devcontainer.sh` - Comprehensive diagnostic and debugging tool
- `validate-requirements.sh` - Validate Python requirements setup

See `docs/DEVCONTAINER_TESTING.md` for detailed usage and troubleshooting guide.

### Policy Management (`scripts/`)

- `menu.sh` - Interactive menu for policy operations
- `01-list-policies.sh` - List all policies
- `02-show-policy-details.sh` - Show policy details
- `03-list-assignments.sh` - List policy assignments
- `04-create-assignment.sh` - Create policy assignment
- `05-compliance-report.sh` - Generate compliance report
- And more...

### VS Code Tasks

- **Start Azure Functions** - Launch function app locally
- **Start Azurite** - Start Azure Storage emulator
- **Install Python Dependencies** - Install/update packages
- **Run Tests** - Execute unit tests with pytest
- **Format Code** - Format with Black
- **Lint Code** - Run pylint

## Testing

This project includes a comprehensive testing framework with **81% code coverage** and multiple test categories:

### Quick Testing

```bash
# Run all tests with the test runner
./run-tests.sh

# Run smoke tests only (fast validation)
./run-tests.sh smoke

# Run with coverage report
./run-tests.sh coverage
```

### Detailed Testing

```bash
# Run policy validation tests
./run-tests.sh policies

# Run Azure CLI integration tests
./run-tests.sh integration

# Run infrastructure tests
./run-tests.sh infrastructure

# Run specific test files
python -m pytest tests/policies/test_policy_validation.py -v

# Run with detailed coverage
python -m pytest tests/ --cov=. --cov-report=html --cov-report=term
```

### Test Categories

- **Policy Tests**: Validate policy definitions and fragments
- **Integration Tests**: Azure CLI and cloud service integration
- **Infrastructure Tests**: Terraform and resource validation
- **Utility Tests**: Helper functions and common utilities

### Azure Functions Testing

```bash
# Run Azure Functions tests specifically
cd functions/basic
python -m pytest tests/ -v

# Run with coverage
python -m pytest tests/ --cov=. --cov-report=html
```

See `docs/TESTING.md` for comprehensive testing documentation and troubleshooting.

## Documentation

### Component Documentation
- **Azure Policy**: See `policies/README.md`
- **Azure Functions**: See `functions/basic/README.md`
- **Scripts**: See `scripts/README.md`
- **Testing**: See `docs/TESTING.md` - Comprehensive testing framework guide
- **Requirements**: See `docs/REQUIREMENTS.md` - Dependency management
- **Troubleshooting**: See `docs/TROUBLESHOOTING.md` - Common issues and solutions

### Setup & Configuration Guides
- **DevContainer**: See `docs/DEVCONTAINER_TESTING.md`
- **Azure Secrets**: See `docs/AZURE_SECRETS_SETUP.md`
- **GitHub Secrets**: See `docs/GITHUB_SECRETS_SETUP.md`
- **Terraform Cloud**: See `docs/TERRAFORM_CLOUD_SETUP.md`
- **Infrastructure**: See `docs/INFRASTRUCTURE.md`

### Development Guides
- **Pre-commit Integration**: See `docs/PRE_COMMIT_INTEGRATION.md`
- **Functions Development**: See `docs/FUNCTIONS.md`
- **Policy Development**: See `docs/POLICIES.md`

See `docs/README.md` for a complete documentation index.

## Resources

- [Azure Policy Documentation](https://learn.microsoft.com/azure/governance/policy/)
- [Azure Functions Python Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-python)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)

## Contributing

1. Use the DevContainer for consistent development environment
2. Follow the existing code style and formatting
3. Add tests for new functionality
4. Update documentation as needed

## Next Steps

- **Azure Policy**: Create custom policies for your organization
- **Azure Functions**: Add more triggers (timer, blob, queue)
- **Integration**: Connect functions with Azure Policy for automated compliance
- **Monitoring**: Add Application Insights for telemetry
- **Security**: Implement authentication and authorization
