# Azure Policy Management Project

A comprehensive Azure Policy management solution that provides custom policy definitions, infrastructure automation, and Azure Functions for policy processing. This project demonstrates enterprise-grade governance with Infrastructure as Code (IaC) and GitOps practices.

## 🏗️ Project Overview

This repository contains a complete Azure Policy management platform with:

- **Custom Azure Policy Definitions**: Governance rules for resource naming conventions and compliance
- **Infrastructure as Code**: Terraform modules for deploying Azure resources with best practices
- **Azure Functions**: Python-based functions for policy processing and automation
- **DevContainer Support**: Complete development environment with all required tools
- **GitOps Workflows**: GitHub Actions for CI/CD and infrastructure management
- **Local Development Tools**: Scripts and utilities for local development and testing

## 📁 Project Structure

```
azure-policy/
├── policies/                    # Custom Azure Policy definitions
│   ├── storage-naming-convention.json
│   ├── resource-group-naming.json
│   └── README.md
├── functions/                   # Azure Functions applications
│   └── basic/
│       ├── function_app.py     # HTTP triggers for policy processing
│       ├── tests/              # Unit tests
│       └── README.md
├── infrastructure/              # Terraform infrastructure code
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── modules/            # Reusable Terraform modules
│   │   └── terraform.tfvars.example
│   └── README.md
├── scripts/                     # Automation and utility scripts
│   ├── menu.sh                 # Interactive policy management menu
│   ├── 01-list-policies.sh     # List Azure policies
│   ├── 02-show-policy-details.sh
│   └── install.sh              # Development environment setup
├── requirements/                # Python dependencies
│   ├── base.txt
│   ├── dev.txt
│   └── functions.txt
├── .devcontainer/              # DevContainer configuration
├── .github/workflows/          # GitHub Actions workflows
└── README.md                   # This file
```

## 🚀 Quick Start

### Option 1: DevContainer (Recommended)

1. **Prerequisites**: Docker and VS Code with Dev Containers extension
2. **Open in DevContainer**:
   - Clone the repository
   - Open in VS Code
   - Click "Reopen in Container" when prompted
   - Wait for the container to build and setup to complete

3. **Start Development**:
   ```bash
   # Azure Functions will be available at http://localhost:7071
   # All tools (Azure CLI, PowerShell, Python, etc.) are pre-installed
   ```

### Option 2: Manual Setup

1. **Run the installation script**:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

2. **Configure Azure CLI**:
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

3. **Start Azure Functions locally**:
   ```bash
   cd functions/basic
   func start
   ```

## 🔧 Features

### Azure Policy Management

- **Storage Account Naming**: Enforces `st*[a-z0-9]*` pattern
- **Resource Group Naming**: Enforces `rg-*-*`, `dev-*`, `prod-*`, `test-*` patterns
- **Interactive Scripts**: Menu-driven policy management tools
- **Compliance Reporting**: Scripts for policy compliance analysis

### Azure Functions

- **HTTP Triggers**: RESTful API endpoints for policy operations
- **Health Monitoring**: Built-in health check and info endpoints
- **Local Development**: Azurite storage emulator integration
- **Testing**: Comprehensive unit tests with pytest
- **Code Quality**: Black, pylint, and mypy integration

### Infrastructure Automation

- **Terraform Modules**: Reusable infrastructure components
- **Multi-Environment**: Development, staging, and production configurations
- **Security Best Practices**: Network security groups, managed identities
- **Cost Management**: Budget alerts and cost optimization
- **Monitoring**: Application Insights and diagnostic logging

### Development Experience

- **Pre-commit Hooks**: Automated code quality checks
- **VS Code Tasks**: Integrated development tasks
- **DevContainer**: Consistent development environment
- **Documentation**: Comprehensive README files and inline documentation

## 🛠️ Available Scripts

### Policy Management Scripts

```bash
# Interactive policy management menu
./scripts/menu.sh

# List all Azure policies
./scripts/01-list-policies.sh

# Show detailed policy information
./scripts/02-show-policy-details.sh

# List policy assignments
./scripts/03-list-assignments.sh

# Create policy assignment
./scripts/04-create-assignment.sh

# Generate compliance report
./scripts/05-compliance-report.sh
```

### Development Scripts

```bash
# Setup development environment
./install.sh

# Validate development environment
./scripts/validate-devcontainer.sh

# Clean up Azurite data
./scripts/cleanup-azurite.sh

# Run pre-commit hooks
./run_precommit.sh
```

## 🌐 Azure Functions Endpoints

When running locally (http://localhost:7071):

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/hello` | GET/POST | Hello world function with name parameter |
| `/api/health` | GET | Health check endpoint |
| `/api/info` | GET | Application information |

### Example Usage

```bash
# Hello world with query parameter
curl "http://localhost:7071/api/hello?name=Azure"

# Hello world with POST body
curl -X POST "http://localhost:7071/api/hello"
  -H "Content-Type: application/json"
  -d '{"name":"Functions"}'

# Health check
curl "http://localhost:7071/api/health"

# Application info
curl "http://localhost:7071/api/info"
```

## 🏗️ Infrastructure Deployment

### Prerequisites

1. Azure subscription with appropriate permissions
2. Azure CLI configured and authenticated
3. Terraform installed (via `install.sh`)

### Deployment Steps

1. **Navigate to infrastructure directory**:
   ```bash
   cd infrastructure/terraform
   ```

2. **Configure variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize and deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## 🧪 Testing

### Azure Functions Tests

```bash
cd functions/basic
python -m pytest tests/ -v
python -m pytest tests/ --cov=. --cov-report=html
```

### Code Quality Checks

```bash
# Format code
black .

# Lint code
pylint function_app.py

# Type checking
mypy function_app.py

# Run all pre-commit hooks
pre-commit run --all-files
```

## 🔒 Security and Compliance

- **Pre-commit Hooks**: Automated security scanning with bandit
- **Secret Detection**: Prevents committing secrets to repository
- **Code Analysis**: PowerShell and Python static analysis
- **Infrastructure Security**: Terraform security scanning
- **Azure Security**: Managed identities and least privilege access

## 🏷️ Naming Conventions

The project follows Azure naming conventions:

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Resource Group | `rg-{workload}-{env}-{region}` | `rg-azurepolicy-dev-eastus` |
| Storage Account | `st{workload}{env}{instance}` | `stazurepolicydev001` |
| Function App | `func-{workload}-{purpose}-{env}` | `func-azurepolicy-processor-dev` |

## 🤝 Contributing

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes and test**:
   ```bash
   # Run tests and quality checks
   pre-commit run --all-files
   ```

3. **Commit and push**:
   ```bash
   git commit -m "feat: add new feature"
   git push origin feature/your-feature-name
   ```

4. **Create pull request** with description of changes

## 📚 Documentation

- **[Policies README](policies/README.md)**: Azure Policy definitions and usage
- **[Functions README](functions/basic/README.md)**: Azure Functions development guide
- **[Infrastructure README](infrastructure/README.md)**: Terraform infrastructure guide
- **[Scripts README](scripts/README.md)**: Automation scripts documentation

## 🔧 Troubleshooting

### Common Issues

1. **Azure CLI not authenticated**:
   ```bash
   az login
   az account show
   ```

2. **Python environment issues**:
   ```bash
   cd functions/basic
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Azurite not running**:
   ```bash
   # Check if Azurite is installed
   which azurite

   # Start Azurite manually
   azurite --silent --location ./azurite-data --debug ./azurite-data/debug.log
   ```

4. **Terraform issues**:
   ```bash
   cd infrastructure/terraform
   terraform init -reconfigure
   terraform validate
   ```

### Getting Help

- Check the specific README files in each directory
- Review troubleshooting documentation in `docs/`
- Check GitHub Issues for known problems
- Review Azure documentation for policy-specific issues

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Next Steps

- [ ] Add more custom policy definitions
- [ ] Implement policy remediation functions
- [ ] Add Azure Policy compliance dashboard
- [ ] Extend infrastructure with more Azure services
- [ ] Add integration tests for end-to-end scenarios
- [ ] Implement automated policy deployment pipelines
