# Azure Policy & Functions Project Rules

This document defines the coding standards, architectural principles, and development guidelines for the Azure Policy and Functions project.

## Table of Contents

- [General Principles](#general-principles)
- [Project Structure](#project-structure)
- [Azure Functions Development](#azure-functions-development)
- [Azure Policy Development](#azure-policy-development)
- [Python Coding Standards](#python-coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Security Guidelines](#security-guidelines)
- [Documentation Standards](#documentation-standards)
- [Git and CI/CD Guidelines](#git-and-cicd-guidelines)
- [Environment and Infrastructure](#environment-and-infrastructure)

## General Principles

### 1. Directory Awareness - Always Check Location First

- **Rule**: ALWAYS run `pwd` before executing any commands or operations
- **Rationale**: Prevents accidental operations in wrong directories, ensures context awareness
- **Implementation**: Make `pwd` your first command in any terminal session or operation
- **Example**:
```bash
# ALWAYS start with location check
pwd
# Expected: /home/vagrant/git/azure-policy (project root)

# Then proceed with operations
cd functions/basic
pwd
# Expected: /home/vagrant/git/azure-policy/functions/basic
```

### 2. Cloud-First Development

- **Rule**: All solutions must be designed for Azure cloud deployment
- **Rationale**: Ensures scalability, reliability, and leverages Azure-native services
- **Implementation**: Use Azure services (Functions, Storage, Policy) over custom implementations

### 3. Security by Design

- **Rule**: Security considerations must be implemented from the start, not added later
- **Rationale**: Prevents vulnerabilities and ensures compliance
- **Implementation**: Use managed identities, least privilege access, secure configurations

### 4. Infrastructure as Code

- **Rule**: All infrastructure must be defined and managed through code
- **Rationale**: Ensures consistency, repeatability, and version control
- **Implementation**: Use ARM templates, Bicep, or Terraform for infrastructure definitions

## Project Structure

### Directory Organization

```
/
├── functions/              # Azure Functions applications
│   └── basic/             # Basic HTTP trigger functions
├── policies/              # Azure Policy definitions
├── scripts/               # Azure CLI management scripts
├── infrastructure/        # Infrastructure as Code templates
├── .devcontainer/         # Development environment configuration
├── .vscode/              # VS Code settings and tasks
└── .github/              # GitHub workflows and templates
```

### File Naming Conventions

- **Azure Functions**: Use descriptive names like `function_app.py`, `requirements.txt`
- **Azure Policies**: Use kebab-case with descriptive names like `storage-naming-convention.json`
- **Scripts**: Use numbered prefixes for ordered execution like `01-list-policies.sh`
- **Tests**: Prefix with `test_` and match the module name like `test_function_app.py`

## Azure Functions Development

### 1. Function Structure

- **Rule**: Use Azure Functions Python v2 programming model
- **Implementation**: Always use `@app.function_name()` and `@app.route()` decorators
- **Example**:

```python
@app.function_name(name="FunctionName")
@app.route(route="endpoint", methods=["GET", "POST"])
def function_handler(req: func.HttpRequest) -> func.HttpResponse:
    # Function implementation
```

### 2. HTTP Response Standards

- **Rule**: All HTTP functions must return consistent JSON responses
- **Required fields**: `message`, `timestamp`, `status`
- **Headers**: Include `Content-Type: application/json`
- **Error handling**: Return appropriate HTTP status codes (200, 400, 500)

### 3. Logging Standards

- **Rule**: Use structured logging with appropriate levels
- **Implementation**: Use Python's `logging` module with INFO, WARNING, ERROR levels
- **Format**: Include function name, timestamp, and relevant context

### 4. Function Endpoints

- **Rule**: All functions must implement these standard endpoints:
  - Health check endpoint (`/health`) for monitoring
  - Info endpoint (`/info`) for service discovery
  - Functional endpoints with clear, RESTful naming

### 5. Environment Configuration

- **Rule**: Use `local.settings.json` for local development
- **Rule**: Never commit sensitive configuration to version control
- **Implementation**: Use Azure Key Vault for secrets in production

## Azure Policy Development

### 1. Policy Definition Structure

- **Rule**: All policies must include proper metadata
- **Required fields**: `displayName`, `description`, `mode`, `policyRule`
- **Parameters**: Use parameters for flexibility and reusability

### 2. Naming Conventions

- **Rule**: Use descriptive, kebab-case names for policy files
- **Pattern**: `{resource-type}-{purpose}.json`
- **Examples**: `storage-naming-convention.json`, `resource-group-naming.json`

### 3. Policy Effects

- **Rule**: Start with `Audit` effect for new policies
- **Progression**: Audit → DoNotEnforce → Deny
- **Documentation**: Document the rationale for each effect choice

### 4. Policy Testing

- **Rule**: Test policies in development environments first
- **Implementation**: Use policy assignments with test scopes
- **Validation**: Verify both compliant and non-compliant scenarios

## Python Coding Standards

### 1. Code Style

- **Tool**: Use Black for code formatting
- **Line length**: 88 characters (Black default)
- **Imports**: Use isort for import organization
- **Type hints**: Use type hints for all function parameters and return values

### 2. Documentation

- **Rule**: All functions must have comprehensive docstrings
- **Format**: Use Google-style docstrings
- **Content**: Include purpose, parameters, return values, and examples

### 3. Error Handling

- **Rule**: Implement comprehensive error handling
- **Implementation**: Use try-catch blocks with specific exception types
- **Logging**: Log errors with appropriate context and stack traces

### 4. Dependencies

- **Rule**: Pin dependency versions in `requirements.txt`
- **Security**: Regularly update dependencies for security patches
- **Minimal**: Only include necessary dependencies

## Testing Guidelines

### 1. Test Coverage and Strategy

- **Rule**: Maintain minimum 80% test coverage for functions, validate all policy files
- **Tools**: Use pytest for testing, coverage.py for coverage reporting
- **Types**: Unit tests, integration tests, policy validation tests, and infrastructure tests
- **Command**: Use `./run-tests.sh` for comprehensive testing workflows

### 2. Policy Testing Framework

- **Location**: `tests/` directory with organized subdirectories
- **Policy validation**: Test JSON syntax, structure, and Azure compliance
- **Fragment support**: Handle both complete policies and modular policy components
- **Azure CLI integration**: Simulate and validate Azure CLI policy operations
- **Naming validation**: Enforce consistent policy file naming conventions

### 3. Test Structure and Organization

```
tests/
├── __init__.py                    # Package initialization
├── conftest.py                   # Shared fixtures and utilities
├── policies/                     # Azure Policy validation tests
│   ├── test_policy_validation.py    # Structure and syntax validation
│   ├── test_existing_policies.py    # Tests for specific policy files
│   └── test_policy_fragments.py     # Modular policy component tests
├── integration/                  # Integration and Azure CLI tests
│   └── test_azure_cli_integration.py # CLI simulation and live tests
├── infrastructure/              # Infrastructure testing (future)
└── utils/                      # Test utilities and helpers
```

### 4. Testing Commands and Workflows

```bash
# Quick validation
./run-tests.sh smoke              # Fast syntax validation

# Comprehensive testing
./run-tests.sh all                # Run all tests
./run-tests.sh policy             # Policy validation only
./run-tests.sh integration        # Integration tests only
./run-tests.sh coverage           # Tests with coverage report

# Specific validation
./run-tests.sh validate policies/storage-naming.json

# Generate reports
./run-tests.sh report             # Comprehensive HTML report
```

### 5. Test Data and Fixtures

- **Rule**: Use fixtures for reusable test data in `conftest.py`
- **Policy helpers**: Use `PolicyTestHelper` for validation logic
- **Mock data**: Provide sample policies and Azure resource structures
- **Isolation**: Each test should be independent and isolated

### 6. Mock External Dependencies

- **Rule**: Mock all external API calls and Azure services
- **Azure CLI**: Simulate commands without requiring authentication
- **Live tests**: Optional live tests marked with `@pytest.mark.live`
- **Tools**: Use unittest.mock, pytest-mock, and responses for HTTP mocking

## Security Guidelines

### 1. Authentication and Authorization

- **Rule**: Use Azure managed identities for service-to-service authentication
- **Implementation**: Avoid hardcoded credentials or connection strings
- **Principle**: Implement least privilege access

### 2. Data Protection

- **Rule**: Encrypt data in transit and at rest
- **Implementation**: Use HTTPS for all communications
- **Compliance**: Follow GDPR and other relevant regulations

### 3. Secrets Management

- **Rule**: Use Azure Key Vault for all secrets
- **Local Development**: Use local.settings.json (never committed)
- **CI/CD**: Use GitHub Secrets for pipeline variables

### 4. Input Validation

- **Rule**: Validate and sanitize all inputs
- **Implementation**: Use proper validation for JSON, query parameters
- **Security**: Prevent injection attacks and data corruption

## Documentation Standards

### 1. README Files

- **Rule**: Every directory must have a README.md
- **Content**: Purpose, setup instructions, usage examples
- **Maintenance**: Keep documentation current with code changes

### 2. API Documentation

- **Rule**: Document all HTTP endpoints
- **Format**: Include method, path, parameters, responses
- **Examples**: Provide curl examples for each endpoint

### 3. Policy Documentation

- **Rule**: Document policy purpose, rules, and examples
- **Format**: Include compliant and non-compliant examples
- **Parameters**: Document all parameters and their effects

### 4. Code Comments

- **Rule**: Use comments sparingly for complex logic
- **Focus**: Explain "why" not "what"
- **Maintenance**: Remove or update outdated comments

## Git and CI/CD Guidelines

### 1. Branch Strategy

- **Main Branch**: `master` for production-ready code
- **Feature Branches**: Use descriptive names like `feature/storage-policy`
- **Protection**: Require pull requests for main branch changes

### 2. Commit Messages

- **Format**: Use conventional commit format
- **Examples**: `feat: add storage naming policy`, `fix: resolve function timeout`
- **Scope**: Keep commits focused and atomic

### 3. Pull Request Guidelines

- **Rule**: All changes must go through pull requests
- **Reviews**: Require at least one reviewer
- **Checks**: All tests and linting must pass

### 4. Automated Testing

- **Rule**: Run tests on every pull request
- **Tools**: GitHub Actions for CI/CD pipelines
- **Coverage**: Fail builds if coverage drops below threshold

## Environment and Infrastructure

### 1. Development Environment

- **Rule**: Use DevContainer for consistent development
- **Tools**: Python 3.13, Azure CLI, Azure Functions Core Tools
- **Configuration**: VS Code with recommended extensions

#### Current Environment Setup
- **Python**: 3.13.5 (venv environment)
- **Azure CLI**: 2.75.0
- **Terraform**: 1.12.2
- **Azure Functions Core Tools**: 4.1.0
- **Node.js**: 24.4.1 (for additional tooling)
- **jq**: 1.6 (JSON processing)

#### Pre-commit Hooks Configuration
- **actionlint**: v1.7.7 (GitHub Actions validation)
- **black**: 25.1.0 (Python formatting)
- **isort**: 6.0.1 (Import organization)
- **flake8**: 7.1.1 (Python linting)
- **shellcheck**: v0.10.0.1 (Shell script validation)
- **terraform**: v1.96.1 (Terraform validation and formatting)
- **checkov**: Security scanning for Terraform
- **bandit**: 1.7.10 (Python security analysis)

### 2. Local Development

- **Storage**: Use Azurite for local Azure Storage emulation
- **Functions**: Use Azure Functions Core Tools for local testing
- **Policies**: Test with Azure CLI in development subscriptions

#### Azure Functions Setup
```bash
# Function app structure
functions/basic/
├── function_app.py          # Main function definitions
├── host.json               # Function host configuration
├── local.settings.json     # Local development settings
├── requirements.txt        # Python dependencies
├── .venv/                 # Virtual environment
└── tests/                 # Unit tests
```

#### Environment Configuration (.env)
```bash
# Terraform Cloud
TF_API_TOKEN=<your_terraform_cloud_token>
TF_CLOUD_ORGANIZATION=azure-policy-cloud

# Azure Service Principal
ARM_CLIENT_ID=<service_principal_id>
ARM_CLIENT_SECRET=<service_principal_secret>
ARM_SUBSCRIPTION_ID=<subscription_id>
ARM_TENANT_ID=<tenant_id>

# Project Configuration
TF_VAR_environment=dev
TF_VAR_location="East US"
TF_VAR_owner=platform-team
TF_VAR_cost_center=development
```

### 3. Deployment Environments

- **Stages**: Development, Testing, Production
- **Isolation**: Use separate Azure subscriptions or resource groups
- **Promotion**: Automated deployment through approved changes

#### Terraform Cloud Configuration
- **Organization**: azure-policy-cloud
- **Backend**: Terraform Cloud for state management
- **Modules**: infrastructure, functions, policies
- **Workspaces**: Separate workspaces per module and environment

#### Infrastructure Structure
```
infrastructure/
├── infrastructure/         # Core resources (networking, RG, storage)
├── functions/             # Azure Functions resources
├── policies/              # Azure Policy definitions
└── terraform/            # Main Terraform configuration
    └── modules/          # Reusable Terraform modules
        ├── networking/   # Virtual networks, subnets, NSGs
        └── policies/     # Policy definitions and assignments
```

### 4. Monitoring and Logging

- **Rule**: Implement comprehensive monitoring
- **Tools**: Application Insights for functions, Azure Monitor for policies
- **Alerts**: Set up alerts for errors and performance issues

#### GitHub Actions Workflows
- **terraform-validate.yml**: Validates all Terraform configurations
- **terraform-apply.yml**: Deploys infrastructure changes
- **terraform-destroy.yml**: Safely destroys development environments
- **docs-structure-check.yml**: Validates documentation organization

### 5. Environment Validation

#### Quick Environment Check
```bash
# Run all pre-commit hooks
pre-commit run --all-files

# Validate specific components
pre-commit run actionlint --all-files          # GitHub Actions
pre-commit run terraform_validate --all-files  # Terraform
pre-commit run black --all-files              # Python formatting
```

#### Terraform Cloud Connectivity Test
```bash
# Load environment variables
source .env

# Test Terraform initialization (with backend)
cd infrastructure/infrastructure
terraform init

# Validate configuration
terraform validate

# Plan changes (dry run)
terraform plan
```

#### Azure Functions Local Testing
```bash
# Start Azurite (Azure Storage emulator)
azurite --silent --location azurite-data

# Start Azure Functions locally
cd functions/basic
source .venv/bin/activate
func start --python

# Test health endpoint
curl http://localhost:7071/api/health
```

### 6. Troubleshooting

#### Common Issues and Solutions

**Terraform Cloud Authentication**
```bash
# If terraform init fails with token errors
export TF_API_TOKEN="your_token_here"
terraform login  # Alternative authentication method
```

**Python Environment Issues**
```bash
# Recreate virtual environment
cd functions/basic
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**Pre-commit Hook Failures**
```bash
# Update all hooks to latest versions
pre-commit autoupdate

# Clear and reinstall hooks
pre-commit clean
pre-commit install
```

**Azure CLI Authentication**
```bash
# Check current authentication status
az account show

# Login if needed
az login

# Set default subscription
az account set --subscription "your-subscription-id"
```

## Compliance and Governance

### 1. Azure Policy Compliance

- **Rule**: All resources must comply with organizational policies
- **Monitoring**: Regular compliance assessments
- **Remediation**: Automated where possible, manual when required

### 2. Resource Tagging

- **Rule**: All Azure resources must be properly tagged
- **Required Tags**: Environment, Owner, Project, CostCenter
- **Automation**: Use policies to enforce tagging standards

### 3. Cost Management

- **Rule**: Implement cost controls and monitoring
- **Budgets**: Set up budget alerts for all environments
- **Optimization**: Regular review of resource utilization

---

## Quick Reference

### Environment Validation Commands

```bash
# ALWAYS START WITH LOCATION CHECK
pwd                                   # Verify current directory location

# Complete environment validation
pre-commit run --all-files

# Individual component checks
terraform --version                    # Terraform v1.12.2
az --version                          # Azure CLI 2.75.0
func --version                        # Functions Core Tools 4.1.0
python3 --version                     # Python 3.10.12

# Load environment variables
source .env

# Test Azure connectivity
az account show

# Test Terraform Cloud connectivity
cd infrastructure/infrastructure && pwd && terraform init

# Start local development environment
azurite --silent --location azurite-data &
cd functions/basic && pwd && func start --python
```

### Common Commands

```bash
# ALWAYS VERIFY LOCATION FIRST
pwd                          # Check current directory

# Testing commands
./run-tests.sh smoke         # Quick validation
./run-tests.sh policy        # Policy validation tests
./run-tests.sh integration   # Integration tests
./run-tests.sh coverage      # Tests with coverage report
./run-tests.sh validate policies/policy-name.json  # Validate specific policy

# Azure Functions development
cd functions/basic && pwd && func start

# Run tests
pwd && python -m pytest tests/ -v

# Format code
pwd && black .

# Lint code
pwd && pylint function_app.py

# Deploy policy
pwd && az policy definition create --name "policy-name" --rules policy.json

# Terraform operations (from infrastructure modules)
cd infrastructure/infrastructure && pwd
terraform init      # Initialize with Terraform Cloud backend
terraform plan       # Preview changes
terraform apply      # Apply changes
terraform destroy    # Destroy resources (dev only)
```

### VS Code Tasks

- **Start Azure Functions**: Launches function app with Azurite
- **Run Tests**: Executes pytest with coverage
- **Format Code**: Runs Black formatter
- **Lint Code**: Runs pylint analysis
- **Install Python Dependencies**: Installs requirements in virtual environment
- **Start Azurite**: Starts Azure Storage emulator

### Environment Variables

#### Required for Development
- `TF_API_TOKEN`: Terraform Cloud API token
- `ARM_CLIENT_ID`: Azure Service Principal client ID
- `ARM_CLIENT_SECRET`: Azure Service Principal secret
- `ARM_SUBSCRIPTION_ID`: Target subscription for deployments
- `ARM_TENANT_ID`: Azure tenant identifier

#### Project Configuration
- `TF_VAR_environment`: Deployment environment (dev/staging/prod)
- `TF_VAR_location`: Azure region ("East US")
- `TF_VAR_owner`: Resource owner (platform-team)
- `TF_VAR_cost_center`: Cost center for billing (development)

#### Local Development Settings
- `AZURE_WebJobsStorage`: Azurite connection string
- `FUNCTIONS_WORKER_RUNTIME`: python
- `AzureWebJobsFeatureFlags`: EnableWorkerIndexing

### GitHub Actions Integration

#### Workflow Triggers
- **terraform-validate.yml**: On PR/push to infrastructure files
- **terraform-apply.yml**: Manual deployment workflow
- **terraform-destroy.yml**: Manual cleanup workflow
- **docs-structure-check.yml**: On markdown file changes

#### Required GitHub Secrets
- `TF_API_TOKEN`: Terraform Cloud token
- `AZURE_SUBSCRIPTION_ID`: Target Azure subscription
- `AZURE_LOCATION`: Default deployment region
- `AZURE_CLIENT_ID`: Service Principal ID (for automated deployments)
- `AZURE_CLIENT_SECRET`: Service Principal secret

### Pre-commit Hook Status

Current hooks configured and passing:
- ✅ General file formatting (trailing whitespace, EOF, YAML/JSON validation)
- ✅ Python formatting (black, isort, flake8)
- ✅ PowerShell analysis (PSScriptAnalyzer when available)
- ✅ Shell script linting (shellcheck)
- ✅ Documentation structure enforcement
- ✅ Azure Policy JSON validation
- ✅ Terraform formatting and validation (fmt, validate, docs, tflint, checkov)
- ✅ GitHub Actions linting (actionlint v1.7.7)
- ✅ Python security scanning (bandit)

---

## Environment Validation Checklist

### 🎯 **CRITICAL: Always Check Directory Location First**

**Before ANY operation, ALWAYS run:**
```bash
pwd
# Should return: /home/vagrant/git/azure-policy (for project root operations)
```

### ✅ **Local Environment Setup**

Use this checklist to ensure your development environment is properly configured:

#### Core Tools
- [ ] **Python 3.13.5** with virtual environment in `functions/basic/.venv`
- [ ] **Azure CLI 2.75.0** authenticated with `az account show`
- [ ] **Terraform 1.12.2** with Terraform Cloud credentials
- [ ] **Azure Functions Core Tools 4.1.0** for local testing
- [ ] **Node.js 24.4.1** and **jq 1.6** for additional tooling

#### Configuration Files
- [ ] **.env file** with all required tokens and variables
- [ ] **local.settings.json** in functions/basic with Azurite configuration
- [ ] **~/.terraform.d/credentials.tfrc.json** for Terraform Cloud authentication
- [ ] **.pre-commit-config.yaml** with all hooks configured

#### Pre-commit Hooks Status
Run `pre-commit run --all-files` to verify all hooks pass:
- [ ] **General file formatting** (whitespace, EOF, YAML/JSON)
- [ ] **Python formatting** (black, isort, flake8)
- [ ] **Shell script linting** (shellcheck)
- [ ] **Terraform validation** (fmt, validate, docs, tflint, checkov)
- [ ] **GitHub Actions linting** (actionlint v1.7.7)
- [ ] **Security scanning** (bandit)
- [ ] **Documentation structure** enforcement
- [ ] **Azure Policy JSON** validation

#### Connectivity Tests
- [ ] **Azure authentication**: `az account show` returns subscription details
- [ ] **Terraform Cloud**: `terraform init` succeeds in infrastructure modules
- [ ] **GitHub**: Actions workflows validate without errors
- [ ] **Python environment**: All dependencies installed and importable

#### Local Development Services
- [ ] **Azurite** starts successfully with `azurite --silent --location azurite-data`
- [ ] **Azure Functions** starts with `func start --python` in functions/basic
- [ ] **Health endpoint** responds at `http://localhost:7071/api/health`

### 🔧 **Troubleshooting Quick Fixes**

#### Directory Location Issues (Most Common Problem)
```bash
# ALWAYS check where you are first
pwd

# Navigate to project root if needed
cd /home/vagrant/git/azure-policy
pwd  # Verify you're in the right place

# Common correct locations:
# Project root: /home/vagrant/git/azure-policy
# Functions: /home/vagrant/git/azure-policy/functions/basic
# Infrastructure: /home/vagrant/git/azure-policy/infrastructure/infrastructure
```

#### If Pre-commit Hooks Fail
```bash
pwd  # Verify you're in project root
pre-commit clean && pre-commit install
pre-commit autoupdate
```

#### If Terraform Init Fails
```bash
pwd  # Should be in infrastructure/infrastructure
source ../../.env  # Load from project root
export TF_API_TOKEN="$TF_API_TOKEN"
terraform login  # Alternative method
```

#### If Python Environment Issues
```bash
cd /home/vagrant/git/azure-policy/functions/basic
pwd  # Verify location
rm -rf .venv && python3 -m venv .venv
source .venv/bin/activate && pip install -r requirements.txt
```

#### If Azure CLI Authentication Fails
```bash
pwd  # Check location first
az login
az account set --subscription "$ARM_SUBSCRIPTION_ID"
```

### 📊 **Project Health Dashboard**

| Component | Status | Command to Check |
|-----------|--------|------------------|
| Pre-commit Hooks | ✅ All Passing | `pre-commit run --all-files` |
| Python Environment | ✅ Active | `python --version` |
| Azure CLI | ✅ Authenticated | `az account show` |
| Terraform Cloud | ✅ Connected | `terraform init` |
| GitHub Actions | ✅ Valid | `pre-commit run actionlint --all-files` |
| Function App | ✅ Ready | `func start --python` |
| Azurite | ✅ Running | `curl http://localhost:10000` |

### 🚀 **Ready for Development**

Once all items above are checked, your environment is ready for:
- Azure Functions development and testing
- Azure Policy creation and validation
- Terraform infrastructure deployment
- GitHub Actions workflow execution
- Full CI/CD pipeline functionality

---

*This document should be reviewed and updated regularly to reflect project evolution and best practices.*
