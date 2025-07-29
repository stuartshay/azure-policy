# Azure Policy Management Project

A comprehensive Azure Policy management solution that provides custom policy definitions, infrastructure automation, and Azure Functions for policy processing. This project demonstrates enterprise-grade governance with Infrastructure as Code (IaC) and GitOps practices.

## 🏗️ Project Overview

This repository contains a complete Azure Policy management platform with:

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
docker run --rm --volume "$(pwd):/terraform-docs" -u $(id -u) quay.io/terraform-docs/terraform-docs:0.20.0 markdown /terraform-docs
```

If `output.file` is not enabled for this module, generated output can be redirected
back to a file:

```bash
docker run --rm --volume "$(pwd):/terraform-docs" -u $(id -u) quay.io/terraform-docs/terraform-docs:0.20.0 markdown /terraform-docs > doc.md
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
    rev: "v0.20.0"
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
  include-main: true

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
