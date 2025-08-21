# Azure Policy & Functions Development Environment

[![Pre-commit](https://github.com/stuartshay/azure-policy/workflows/Pre-commit/badge.svg)](https://github.com/stuartshay/azure-policy/actions/workflows/pre-commit.yml)

[![Deploy Azure Function](https://github.com/stuartshay/azure-policy/actions/workflows/deploy-function.yml/badge.svg)](https://github.com/stuartshay/azure-policy/actions/workflows/deploy-function.yml)

This repository contains tools and examples for Azure Policy management and Azure Functions development, with a complete DevContainer setup for streamlined development.

## 🚀 Azure Functions Overview

This project includes three distinct Azure Function types, each designed for different use cases and complexity levels:

| 🎯 Function Type | ⚙️ Trigger | 🎨 Purpose | 📚 Documentation |
|------------------|------------|------------|------------------|
| ⚡ **Basic** | 🌐 HTTP | Simple REST API endpoints with health monitoring | [📖 Basic Function](https://github.com/stuartshay/azure-policy/tree/develop/functions/basic) |
| ⏰ **Advanced** | ⏲️ Timer + 🌐 HTTP | Scheduled tasks with Service Bus integration | [📖 Advanced Function](https://github.com/stuartshay/azure-policy/tree/develop/functions/advanced) |
| 🔧 **Infrastructure** | ⏲️ Timer + 🌐 HTTP | Automated secret rotation and infrastructure management | [📖 Infrastructure Function](https://github.com/stuartshay/azure-policy/tree/develop/functions/infrastructure) |

### Basic Function (HTTP Triggers)
- **Purpose**: Simple HTTP-triggered functions for REST API development
- **Key Features**: Hello World, Health Check, and Info endpoints
- **Use Cases**: API development, health monitoring, basic web services
- **Quick Start**:
  ```bash
  cd functions/basic
  func start
  ```
- **Endpoints**: `/api/hello`, `/api/health`, `/api/info`

### Advanced Function (Timer + Service Bus)
- **Purpose**: Timer-triggered functions with Azure Service Bus integration
- **Key Features**: Scheduled message sending (every 10 seconds), Service Bus health monitoring
- **Use Cases**: Scheduled tasks, message queue processing, event-driven architecture
- **Prerequisites**: Azure Service Bus namespace and queue
- **Quick Start**:
  ```bash
  cd functions/advanced
  # Configure Service Bus connection in local.settings.json
  func start
  ```
- **Endpoints**: `/api/health`, `/api/health/servicebus`, `/api/info`, `/api/test/send-message`

### Infrastructure Function (Secret Rotation)
- **Purpose**: Automated secret rotation for Service Bus authorization rules
- **Key Features**: Daily secret rotation, Key Vault integration, manual rotation endpoint
- **Use Cases**: Security automation, compliance, secret management
- **Prerequisites**: Azure Service Bus, Key Vault, Managed Identity with proper RBAC roles
- **Quick Start**:
  ```bash
  cd functions/infrastructure
  # Configure Azure resources and managed identity
  func start
  ```
- **Endpoints**: `/api/health`, `/api/info`, `/api/rotate`

## Repository Structure

### Core Directories
- **`policies/`** - Azure Policy definitions and examples
- **`scripts/`** - Azure CLI scripts for policy management
- **`functions/basic/`** - Azure Functions with HTTP triggers (Python 3.13)
- **`infrastructure/`** - Terraform infrastructure as code
- **`notebooks/`** - Jupyter Notebooks for interactive Azure environment validation and analysis
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
- **CI/CD Pipeline**: Robust GitHub Actions workflow with comprehensive error handling

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

## Pre-commit Workflow

This repository includes a comprehensive pre-commit workflow that runs automatically on every commit and pull request, ensuring code quality and consistency across all development environments.

### Code Quality Checks

The pre-commit workflow performs extensive validation:

- **File Formatting**: Trailing whitespace, end-of-file fixes, line ending consistency
- **Language Validation**: YAML, JSON, TOML, XML syntax validation
- **Python Code Quality**: Black formatting, isort imports, flake8 linting
- **Jupyter Notebooks**: Output clearing and code formatting
- **PowerShell Analysis**: PSScriptAnalyzer for PowerShell scripts
- **Shell Script Linting**: shellcheck for bash/shell scripts
- **Azure-Specific Validation**: Policy JSON validation, Bicep template validation
- **Infrastructure as Code**: Terraform formatting, validation, and security scanning
- **GitHub Actions**: Workflow file linting
- **Security Scanning**: bandit for Python security issues

### CI/CD Integration

The GitHub Actions workflow provides:

- **Multi-Environment Compatibility**: Works across local development and CI environments
- **Comprehensive Tool Installation**: Automated setup of Python, PowerShell, Azure CLI, Terraform, and more
- **Enhanced Error Reporting**: Detailed debugging output for quick issue identification
- **Robust Error Handling**: Graceful handling of tool installation and execution failures
- **Caching**: Optimized pre-commit environment caching for faster execution

### Local Development

Pre-commit hooks run automatically on every commit:

```bash
# Install pre-commit hooks (done automatically in DevContainer)
pre-commit install

# Run pre-commit checks manually
pre-commit run --all-files

# Run specific hooks
pre-commit run black --all-files
pre-commit run terraform_fmt --all-files
```

### Configuration Files

- **`.pre-commit-config.yaml`**: Complete hook configuration with environment-agnostic paths
- **`.checkov.yaml`**: Security scanning configuration optimized for development environments
- **`.github/workflows/pre-commit.yml`**: CI/CD workflow with enhanced debugging and error handling

The workflow ensures consistent code quality whether you're developing locally or contributing via pull requests.

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
- **Security**: Implement authentication and authorization## What is terraform-docs

A utility to generate documentation from Terraform modules in various output formats.

## Installation

macOS users can install using [Homebrew]:

```bash
brew install terraform-docs
```

or

```bash
brew install terraform-docs/tap/terraform-docs
```

Windows users can install using [Scoop]:

```bash
scoop bucket add terraform-docs https://github.com/terraform-docs/scoop-bucket
scoop install terraform-docs
```

or [Chocolatey]:

```bash
choco install terraform-docs
```

Stable binaries are also available on the [releases] page. To install, download the
binary for your platform from "Assets" and place this into your `$PATH`:

```bash
curl -Lo ./terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.17.0/terraform-docs-v0.17.0-$(uname)-amd64.tar.gz
tar -xzf terraform-docs.tar.gz
chmod +x terraform-docs
mv terraform-docs /usr/local/bin/terraform-docs
```

**NOTE:** Windows releases are in `ZIP` format.

The latest version can be installed using `go install` or `go get`:

```bash
# go1.17+
go install github.com/terraform-docs/terraform-docs@v0.17.0
```

```bash
# go1.16
GO111MODULE="on" go get github.com/terraform-docs/terraform-docs@v0.17.0
```

**NOTE:** please use the latest Go to do this, minimum `go1.16` is required.

This will put `terraform-docs` in `$(go env GOPATH)/bin`. If you encounter the error
`terraform-docs: command not found` after installation then you may need to either add
that directory to your `$PATH` as shown [here] or do a manual installation by cloning
the repo and run `make build` from the repository which will put `terraform-docs` in:

```bash
$(go env GOPATH)/src/github.com/terraform-docs/terraform-docs/bin/$(uname | tr '[:upper:]' '[:lower:]')-amd64/terraform-docs
```

## Usage

### Running the binary directly

To run and generate documentation into README within a directory:

```bash
terraform-docs markdown table --output-file README.md --output-mode inject /path/to/module
```

Check [`output`] configuration for more details and examples.

### Using docker

terraform-docs can be run as a container by mounting a directory with `.tf`
files in it and run the following command:

```bash
docker run --rm --volume "$(pwd):/terraform-docs" -u $(id -u) quay.io/terraform-docs/terraform-docs:0.17.0 markdown /terraform-docs
```

If `output.file` is not enabled for this module, generated output can be redirected
back to a file:

```bash
docker run --rm --volume "$(pwd):/terraform-docs" -u $(id -u) quay.io/terraform-docs/terraform-docs:0.17.0 markdown /terraform-docs > doc.md
```

**NOTE:** Docker tag `latest` refers to _latest_ stable released version and `edge`
refers to HEAD of `master` at any given point in time.

### Using GitHub Actions

To use terraform-docs GitHub Action, configure a YAML workflow file (e.g.
`.github/workflows/documentation.yml`) with the following:

```yaml
name: Generate terraform docs
on:
  - pull_request

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      with:
        ref: ${{ github.event.pull_request.head.ref }}

    - name: Render terraform docs and push changes back to PR
      uses: terraform-docs/gh-actions@main
      with:
        working-dir: .
        output-file: README.md
        output-method: inject
        git-push: "true"
```

Read more about [terraform-docs GitHub Action] and its configuration and
examples.

### pre-commit hook

With pre-commit, you can ensure your Terraform module documentation is kept
up-to-date each time you make a commit.

First [install pre-commit] and then create or update a `.pre-commit-config.yaml`
in the root of your Git repo with at least the following content:

```yaml
repos:
  - repo: https://github.com/terraform-docs/terraform-docs
    rev: "v0.17.0"
    hooks:
      - id: terraform-docs-go
        args: ["markdown", "table", "--output-file", "README.md", "./mymodule/path"]
```

Then run:

```bash
pre-commit install
pre-commit install-hooks
```

Further changes to your module's `.tf` files will cause an update to documentation
when you make a commit.

## Configuration

terraform-docs can be configured with a yaml file. The default name of this file is
`.terraform-docs.yml` and the path order for locating it is:

1. root of module directory
1. `.config/` folder at root of module directory
1. current directory
1. `.config/` folder at current directory
1. `$HOME/.tfdocs.d/`

```yaml
formatter: "" # this is required

version: ""

header-from: main.tf
footer-from: ""

recursive:
  enabled: false
  path: modules

sections:
  hide: []
  show: []

content: ""

output:
  file: ""
  mode: inject
  template: |-
    <!-- BEGIN_TF_DOCS -->
    {{ .Content }}
    <!-- END_TF_DOCS -->

output-values:
  enabled: false
  from: ""

sort:
  enabled: true
  by: name

settings:
  anchor: true
  color: true
  default: true
  description: false
  escape: true
  hide-empty: false
  html: true
  indent: 2
  lockfile: true
  read-comments: true
  required: true
  sensitive: true
  type: true
```

## Content Template

Generated content can be customized further away with `content` in configuration.
If the `content` is empty the default order of sections is used.

Compatible formatters for customized content are `asciidoc` and `markdown`. `content`
will be ignored for other formatters.

`content` is a Go template with following additional variables:

- `{{ .Header }}`
- `{{ .Footer }}`
- `{{ .Inputs }}`
- `{{ .Modules }}`
- `{{ .Outputs }}`
- `{{ .Providers }}`
- `{{ .Requirements }}`
- `{{ .Resources }}`

and following functions:

- `{{ include "relative/path/to/file" }}`

These variables are the generated output of individual sections in the selected
formatter. For example `{{ .Inputs }}` is Markdown Table representation of _inputs_
when formatter is set to `markdown table`.

Note that sections visibility (i.e. `sections.show` and `sections.hide`) takes
precedence over the `content`.

Additionally there's also one extra special variable avaialble to the `content`:

- `{{ .Module }}`

As opposed to the other variables mentioned above, which are generated sections
based on a selected formatter, the `{{ .Module }}` variable is just a `struct`
representing a [Terraform module].

````yaml
content: |-
  Any arbitrary text can be placed anywhere in the content

  {{ .Header }}

  and even in between sections

  {{ .Providers }}

  and they don't even need to be in the default order

  {{ .Outputs }}

  include any relative files

  {{ include "relative/path/to/file" }}

  {{ .Inputs }}

  # Examples

  ```hcl
  {{ include "examples/foo/main.tf" }}
  ```

  ## Resources

  {{ range .Module.Resources }}
  - {{ .GetMode }}.{{ .Spec }} ({{ .Position.Filename }}#{{ .Position.Line }})
  {{- end }}
````

## Build on top of terraform-docs

terraform-docs primary use-case is to be utilized as a standalone binary, but
some parts of it is also available publicly and can be imported in your project
as a library.

```go
import (
    "github.com/terraform-docs/terraform-docs/format"
    "github.com/terraform-docs/terraform-docs/print"
    "github.com/terraform-docs/terraform-docs/terraform"
)

// buildTerraformDocs for module root `path` and provided content `tmpl`.
func buildTerraformDocs(path string, tmpl string) (string, error) {
    config := print.DefaultConfig()
    config.ModuleRoot = path // module root path (can be relative or absolute)

    module, err := terraform.LoadWithOptions(config)
    if err != nil {
        return "", err
    }

    // Generate in Markdown Table format
    formatter := format.NewMarkdownTable(config)

    if err := formatter.Generate(module); err != nil {
        return "", err
    }

    // // Note: if you don't intend to provide additional template for the generated
    // // content, or the target format doesn't provide templating (e.g. json, yaml,
    // // xml, or toml) you can use `Content()` function instead of `Render()`.
    // // `Content()` returns all the sections combined with predefined order.
    // return formatter.Content(), nil

    return formatter.Render(tmpl)
}
```

## Plugin

Generated output can be heavily customized with [`content`], but if using that
is not enough for your use-case, you can write your own plugin.

In order to install a plugin the following steps are needed:

- download the plugin and place it in `~/.tfdocs.d/plugins` (or `./.tfdocs.d/plugins`)
- make sure the plugin file name is `tfdocs-format-<NAME>`
- modify [`formatter`] of `.terraform-docs.yml` file to be `<NAME>`

**Important notes:**

- if the plugin file name is different than the example above, terraform-docs won't
be able to to pick it up nor register it properly
- you can only use plugin thorough `.terraform-docs.yml` file and it cannot be used
with CLI arguments

To create a new plugin create a new repository called `tfdocs-format-<NAME>` with
following `main.go`:

```go
package main

import (
    _ "embed" //nolint

    "github.com/terraform-docs/terraform-docs/plugin"
    "github.com/terraform-docs/terraform-docs/print"
    "github.com/terraform-docs/terraform-docs/template"
    "github.com/terraform-docs/terraform-docs/terraform"
)

func main() {
    plugin.Serve(&plugin.ServeOpts{
        Name:    "<NAME>",
        Version: "0.1.0",
        Printer: printerFunc,
    })
}

//go:embed sections.tmpl
var tplCustom []byte

// printerFunc the function being executed by the plugin client.
func printerFunc(config *print.Config, module *terraform.Module) (string, error) {
    tpl := template.New(config,
        &template.Item{Name: "custom", Text: string(tplCustom)},
    )

    rendered, err := tpl.Render("custom", module)
    if err != nil {
        return "", err
    }

    return rendered, nil
}
```

Please refer to [tfdocs-format-template] for more details. You can create a new
repository from it by clicking on `Use this template` button.

## Documentation

- **Users**
  - Read the [User Guide] to learn how to use terraform-docs
  - Read the [Formats Guide] to learn about different output formats of terraform-docs
  - Refer to [Config File Reference] for all the available configuration options
- **Developers**
  - Read [Contributing Guide] before submitting a pull request

Visit [our website] for all documentation.

## Community

- Discuss terraform-docs on [Slack]

## License

MIT License - Copyright (c) 2021 The terraform-docs Authors.

[Chocolatey]: https://www.chocolatey.org
[Config File Reference]: https://terraform-docs.io/user-guide/configuration/
[`content`]: https://terraform-docs.io/user-guide/configuration/content/
[Contributing Guide]: CONTRIBUTING.md
[Formats Guide]: https://terraform-docs.io/reference/terraform-docs/
[`formatter`]: https://terraform-docs.io/user-guide/configuration/formatter/
[here]: https://golang.org/doc/code.html#GOPATH
[Homebrew]: https://brew.sh
[install pre-commit]: https://pre-commit.com/#install
[`output`]: https://terraform-docs.io/user-guide/configuration/output/
[releases]: https://github.com/terraform-docs/terraform-docs/releases
[Scoop]: https://scoop.sh/
[Slack]: https://slack.terraform-docs.io/
[terraform-docs GitHub Action]: https://github.com/terraform-docs/gh-actions
[Terraform module]: https://pkg.go.dev/github.com/terraform-docs/terraform-docs/terraform#Module
[tfdocs-format-template]: https://github.com/terraform-docs/tfdocs-format-template
[our website]: https://terraform-docs.io/
[User Guide]: https://terraform-docs.io/user-guide/introduction/
