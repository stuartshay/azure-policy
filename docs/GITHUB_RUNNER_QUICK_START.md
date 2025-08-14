# GitHub Self-Hosted Runner Quick Start

## 🚀 Quick Deployment

```bash
# Navigate to the module
cd infrastructure/github-runner

# 1. Setup configuration
make prep-deploy
# Edit terraform.tfvars with your GitHub token

# 2. Deploy everything
make full-deploy

# 3. Test the runner
make test-runner
```

## 📋 Available Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make prep-deploy` | Create and configure terraform.tfvars |
| `make full-deploy` | Complete deployment workflow |
| `make status` | Show deployment status |
| `make test-runner` | Test runner connectivity |
| `make ssh` | SSH to runner VM |
| `make logs` | View runner service logs |
| `make destroy` | Remove runner infrastructure |

## 📁 Module Structure

```
infrastructure/github-runner/
├── Makefile                 # Deployment automation
├── main.tf                  # Infrastructure definition
├── variables.tf             # Configuration options
├── terraform.tfvars.example # Configuration template
├── runner-setup.sh          # VM setup script
├── .gitignore              # Ignore sensitive files
└── README.md               # Detailed documentation
```

## 🔧 Prerequisites

1. **Core Infrastructure**: Deploy core networking first
   ```bash
   cd ../core && make apply
   ```

2. **GitHub Token**: Create Personal Access Token
   - Go to: GitHub → Settings → Developer settings → Personal access tokens
   - Scopes: `repo`, `workflow`, `admin:org` (if using organization)

3. **Configuration**: Set up terraform.tfvars
   ```bash
   make prep-deploy  # Creates from template
   # Edit terraform.tfvars with your values
   ```

The Makefile handles all prerequisites checking and provides clear error messages if anything is missing! 🎉
