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

### 1. Cloud-First Development

- **Rule**: All solutions must be designed for Azure cloud deployment
- **Rationale**: Ensures scalability, reliability, and leverages Azure-native services
- **Implementation**: Use Azure services (Functions, Storage, Policy) over custom implementations

### 2. Security by Design

- **Rule**: Security considerations must be implemented from the start, not added later
- **Rationale**: Prevents vulnerabilities and ensures compliance
- **Implementation**: Use managed identities, least privilege access, secure configurations

### 3. Infrastructure as Code

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

### 1. Test Coverage

- **Rule**: Maintain minimum 80% test coverage
- **Tools**: Use pytest for testing, coverage.py for coverage reporting
- **Types**: Unit tests, integration tests, and functional tests

### 2. Test Structure

- **Rule**: Mirror source code structure in test directories
- **Naming**: Prefix test files with `test_`
- **Organization**: Group related tests in test classes

### 3. Test Data

- **Rule**: Use fixtures for reusable test data
- **Implementation**: Create `conftest.py` for shared fixtures
- **Isolation**: Each test should be independent and isolated

### 4. Mock External Dependencies

- **Rule**: Mock all external API calls and Azure services
- **Tools**: Use unittest.mock or pytest-mock
- **Rationale**: Ensures tests run consistently without external dependencies

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

### 2. Local Development

- **Storage**: Use Azurite for local Azure Storage emulation
- **Functions**: Use Azure Functions Core Tools for local testing
- **Policies**: Test with Azure CLI in development subscriptions

### 3. Deployment Environments

- **Stages**: Development, Testing, Production
- **Isolation**: Use separate Azure subscriptions or resource groups
- **Promotion**: Automated deployment through approved changes

### 4. Monitoring and Logging

- **Rule**: Implement comprehensive monitoring
- **Tools**: Application Insights for functions, Azure Monitor for policies
- **Alerts**: Set up alerts for errors and performance issues

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

### Common Commands

```bash
# Start Azure Functions locally
cd functions/basic && func start

# Run tests
python -m pytest tests/ -v

# Format code
black .

# Lint code
pylint function_app.py

# Deploy policy
az policy definition create --name "policy-name" --rules policy.json
```

### VS Code Tasks

- **Start Azure Functions**: Launches function app with Azurite
- **Run Tests**: Executes pytest with coverage
- **Format Code**: Runs Black formatter
- **Lint Code**: Runs pylint analysis

### Environment Variables

- `AZURE_SUBSCRIPTION_ID`: Target subscription for deployments
- `AZURE_TENANT_ID`: Azure tenant identifier
- `AZURE_CLIENT_ID`: Service principal client ID (CI/CD only)

---

*This document should be reviewed and updated regularly to reflect project evolution and best practices.*
