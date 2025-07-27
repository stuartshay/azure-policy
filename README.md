# Azure Policy & Functions Development Environment

This repository contains tools and examples for Azure Policy management and Azure Functions development, with a complete DevContainer setup for streamlined development.

## Repository Structure

- **`policies/`** - Azure Policy definitions and examples
- **`scripts/`** - Azure CLI scripts for policy management
- **`functions/basic/`** - Azure Functions with HTTP triggers (Python 3.13)
- **`.devcontainer/`** - Complete development environment setup
- **`.vscode/`** - VS Code configuration and recommended extensions

## Features

### Azure Policy Tools

- Policy definitions and examples
- Azure CLI scripts for policy management
- Compliance reporting tools

### Azure Functions

- Python 3.13 with Azure Functions v4
- HTTP triggers with "Hello World" example
- Health check and info endpoints
- Comprehensive testing with pytest
- Local development with Azurite storage emulator

### Development Environment

- **DevContainer**: Complete containerized development environment
- **Python 3.13**: Latest Python runtime
- **Azure CLI**: For Azure resource management
- **Azure Functions Core Tools**: For local function development
- **GitHub CLI**: For repository and pull request management
- **Azurite**: Local Azure Storage emulator
- **VS Code Extensions**: Recommended extensions for optimal development experience

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

## Development Workflow

### Azure Policy Development

1. Create or modify policy definitions in `policies/`
2. Use scripts in `scripts/` to deploy and manage policies
3. Test policy compliance and remediation

### Azure Functions Development

1. Modify functions in `functions/basic/function_app.py`
2. Run tests: `python -m pytest tests/ -v`
3. Format code: `black .`
4. Test locally with `func start`

### VS Code Integration

The repository includes comprehensive VS Code configuration:

- **Extensions**: Automatically installs recommended extensions
- **Tasks**: Pre-configured tasks for common operations
- **Debugging**: Launch configurations for Azure Functions
- **Settings**: Optimized settings for Python and Azure development

## Available Scripts

### Environment Setup

- `start-functions.sh` - Verify and setup Azure Functions development environment

### Policy Management (`scripts/`)

- `menu.sh` - Interactive menu for policy operations
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
- **Run Tests** - Execute unit tests
- **Format Code** - Format with Black
- **Lint Code** - Run pylint

## Testing

```bash
# Run Azure Functions tests
cd functions/basic
python -m pytest tests/ -v

# Run with coverage
python -m pytest tests/ --cov=. --cov-report=html
```

## Documentation

- **Azure Policy**: See `policies/README.md`
- **Azure Functions**: See `functions/basic/README.md`
- **Scripts**: See `scripts/README.md`
- **Troubleshooting**: See `TROUBLESHOOTING.md`

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
