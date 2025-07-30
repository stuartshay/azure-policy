# Azure Policy Learning Scripts

A comprehensive collection of interactive scripts to help you learn and master Azure Policy concepts and implementation.

## 🎯 Overview

These scripts provide hands-on experience with Azure Policy, covering everything from basic policy listing to advanced remediation scenarios. Each script is designed to be educational, interactive, and practical.

## 📋 Prerequisites

- Azure CLI installed and configured
- Active Azure subscription
- Appropriate permissions to view and manage Azure Policy
- Bash shell (Linux, macOS, or WSL on Windows)
- **PowerShell (optional)** for enhanced Azure automation

## 🚀 Quick Start

### Bash Scripts

1. **Make scripts executable:**

   ```bash
   chmod +x *.sh
   ```

2. **Start with the interactive menu:**

   ```bash
   ./menu.sh
   ```

3. **Or run scripts individually:**

   ```bash
   ./01-list-policies.sh
   ```

### PowerShell Setup

1. **Install PowerShell modules:**

   ```bash
   pwsh ./Install-PowerShellModules.ps1
   ```

2. **Setup PowerShell profile:**

   ```bash
   pwsh ./Setup-PowerShellProfile.ps1
   ```

3. **Start PowerShell with Azure context:**

   ```bash
   pwsh
   azconnect  # Connect to Azure
   ```

## 📚 Script Descriptions

### Basic Operations (Bash)

| Script | Description | Learning Focus |
|--------|-------------|----------------|
| `01-list-policies.sh` | Lists built-in and custom Azure policies | Policy discovery, categories |
| `02-show-policy-details.sh` | Shows detailed information about specific policies | Policy structure, rules, parameters |
| `03-list-assignments.sh` | Lists all policy assignments in subscription | Assignment scopes, enforcement modes |
| `04-create-assignment.sh` | Interactive policy assignment creation | Assignment process, scoping |
| `05-compliance-report.sh` | Generates compliance status reports | Compliance evaluation, reporting |

### Advanced Topics (Bash)

| Script | Description | Learning Focus |
|--------|-------------|----------------|
| `06-list-initiatives.sh` | Explores policy initiatives (policy sets) | Initiative concepts, compliance frameworks |
| `07-create-custom-policy.sh` | Creates custom policy definitions | Policy authoring, JSON structure |
| `08-remediation.sh` | Demonstrates policy remediation | Remediation tasks, managed identities |

### PowerShell Environment

| Script | Description | Purpose |
|--------|-------------|---------|
| `Install-PowerShellModules.ps1` | Installs Azure PowerShell modules | Module management, environment setup |
| `Setup-PowerShellProfile.ps1` | Configures PowerShell profile | Enhanced Azure development experience |

### Utilities

| Script | Description |
|--------|-------------|
| `menu.sh` | Interactive menu for all scripts |

## 🔧 PowerShell Modules Included

### Core Azure Modules

- **Az** - Complete Azure PowerShell module suite
- **Az.Accounts** - Azure authentication and account management
- **Az.Resources** - Azure Resource Manager operations
- **Az.Storage** - Azure Storage account management

### Policy & Governance

- **Az.PolicyInsights** - Azure Policy compliance and insights
- **Az.ResourceGraph** - Azure Resource Graph queries for advanced analytics
- **Az.Security** - Azure Security Center management

### Functions & Compute

- **Az.Functions** - Azure Functions management
- **Az.Websites** - Azure App Service and Function Apps
- **Az.Monitor** - Azure Monitor and Application Insights

### Development Tools

- **PSScriptAnalyzer** - PowerShell script analysis and linting
- **Pester** - PowerShell testing framework
- **PowerShellGet** - PowerShell module management
- **Microsoft.PowerShell.SecretManagement** - Secure credential management

### Utility Modules

- **ImportExcel** - Excel file manipulation without Excel
- **PSReadLine** - Enhanced command line editing

## 🎓 Learning Path

### Beginner (Start Here)

1. `01-list-policies.sh` - Understand what policies exist
2. `02-show-policy-details.sh` - Examine policy structure
3. `03-list-assignments.sh` - See how policies are assigned

### Intermediate

4. `04-create-assignment.sh` - Create your first assignment
5. `05-compliance-report.sh` - Understand compliance evaluation
6. `06-list-initiatives.sh` - Learn about policy grouping

### Advanced

7. `07-create-custom-policy.sh` - Author your own policies
8. `08-remediation.sh` - Implement automated remediation

### PowerShell Automation

9. `Install-PowerShellModules.ps1` - Setup PowerShell environment
10. Use PowerShell for advanced Azure automation and bulk operations

## 💻 PowerShell Quick Commands

After setting up PowerShell environment:

```powershell
# Connect to Azure
azconnect

# List policy definitions
policies | Select-Object Name, DisplayName | Format-Table

# Check compliance
compliance

# Query resources
Search-AzureResources "Resources | where type == 'microsoft.storage/storageaccounts'"

# Get non-compliant resources
Get-NonCompliantResources -PolicyName "MyPolicy"

# List Function Apps
functions

# Analyze PowerShell scripts
analyze "script.ps1"
```

## 🔧 Script Features

### Interactive Elements

- **Guided prompts** for user input
- **Menu-driven choices** for different scenarios
- **Educational explanations** throughout execution
- **Next steps suggestions** after each operation

### Error Handling

- **Prerequisites checking** (Azure login, permissions)
- **Graceful error messages** with helpful suggestions
- **Input validation** for user choices

### Educational Content

- **Concept explanations** before technical operations
- **Best practices** and recommendations
- **Links to documentation** for deeper learning
- **Real-world examples** and use cases

## 📁 Generated Files

Scripts may create additional files and directories:

```
azure-policy/
├── scripts/
│   ├── *.sh (bash learning scripts)
│   ├── *.ps1 (PowerShell setup and utilities)
│   └── README.md (this file)
└── policies/
    └── *.json (custom policy definitions)
```

## 🏷️ Policy Examples Created

The custom policy script (`07-create-custom-policy.sh`) includes templates for:

1. **Tag Enforcement** - Require specific tags on resource groups
2. **Naming Conventions** - Enforce naming patterns for storage accounts
3. **Security Auditing** - Audit VMs without backup enabled
4. **Cost Control** - Deny expensive VM sizes

## 🔍 Common Use Cases

### Governance

- Enforce organizational standards
- Implement compliance frameworks
- Audit resource configurations

### Security

- Ensure security best practices
- Audit security configurations
- Enforce encryption requirements

### Cost Management

- Prevent expensive resource creation
- Enforce resource sizing limits
- Audit unused resources

### Automation (PowerShell)

- Bulk policy operations
- Advanced compliance reporting
- Resource graph queries
- Automated remediation workflows

## 💡 Tips for Learning

1. **Start with audit-only policies** before using deny effects
2. **Test on development subscriptions** first
3. **Use resource groups** for initial scoping
4. **Monitor compliance reports** regularly
5. **Read policy documentation** linked in scripts
6. **Use PowerShell for bulk operations** and advanced scenarios
7. **Leverage Resource Graph** for complex queries and reporting

## 🐛 Troubleshooting

### Common Issues

**"Not logged in to Azure"**

```bash
az login
# or in PowerShell
azconnect
```

**"Permission denied"**

```bash
chmod +x *.sh
```

**"PowerShell module not found"**

```powershell
./Install-PowerShellModules.ps1 -Force
```

**"No policies found"**

- Check your subscription access
- Verify Azure Policy is enabled
- Try different search terms

**"Policy evaluation pending"**

- Wait 30 minutes for initial evaluation
- Check assignment scope matches resources
- Verify policy effect is not "Disabled"

### Getting Help

1. Check script output for specific error messages
2. Review Azure Policy documentation
3. Verify your Azure permissions
4. Test with simpler scenarios first
5. Use PowerShell help system: `Get-Help <command>`

## 📖 Additional Resources

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Policy Definition Structure](https://docs.microsoft.com/azure/governance/policy/concepts/definition-structure)
- [Policy Effects](https://docs.microsoft.com/azure/governance/policy/concepts/effects)
- [Azure Policy Samples](https://github.com/Azure/azure-policy)
- [Azure PowerShell Documentation](https://docs.microsoft.com/powershell/azure/)
- [Azure Resource Graph Documentation](https://docs.microsoft.com/azure/governance/resource-graph/)

## 🤝 Contributing

Feel free to enhance these scripts by:

- Adding new policy examples
- Improving error handling
- Adding more educational content
- Creating additional use case scenarios
- Contributing PowerShell automation scripts

---

**Happy Learning!** 🎓

These scripts are designed to make Azure Policy accessible and understandable. Take your time with each script and don't hesitate to re-run them as you learn. The PowerShell environment provides additional power for advanced scenarios and automation.

## 🔧 Script Features

### Interactive Elements

- **Guided prompts** for user input
- **Menu-driven choices** for different scenarios
- **Educational explanations** throughout execution
- **Next steps suggestions** after each operation

### Error Handling

- **Prerequisites checking** (Azure login, permissions)
- **Graceful error messages** with helpful suggestions
- **Input validation** for user choices

### Educational Content

- **Concept explanations** before technical operations
- **Best practices** and recommendations
- **Links to documentation** for deeper learning
- **Real-world examples** and use cases

## 📁 Generated Files

Scripts may create additional files and directories:

```
azure-policy/
├── scripts/
│   ├── *.sh (learning scripts)
│   └── README.md (this file)
└── policies/
    └── *.json (custom policy definitions)
```

## 🏷️ Policy Examples Created

The custom policy script (`07-create-custom-policy.sh`) includes templates for:

1. **Tag Enforcement** - Require specific tags on resource groups
2. **Naming Conventions** - Enforce naming patterns for storage accounts
3. **Security Auditing** - Audit VMs without backup enabled
4. **Cost Control** - Deny expensive VM sizes

## 🔍 Common Use Cases

### Governance

- Enforce organizational standards
- Implement compliance frameworks
- Audit resource configurations

### Security

- Ensure security best practices
- Audit security configurations
- Enforce encryption requirements

### Cost Management

- Prevent expensive resource creation
- Enforce resource sizing limits
- Audit unused resources

## 💡 Tips for Learning

1. **Start with audit-only policies** before using deny effects
2. **Test on development subscriptions** first
3. **Use resource groups** for initial scoping
4. **Monitor compliance reports** regularly
5. **Read policy documentation** linked in scripts

## 🐛 Troubleshooting

### Common Issues

**"Not logged in to Azure"**

```bash
az login
```

**"Permission denied"**

```bash
chmod +x *.sh
```

**"No policies found"**

- Check your subscription access
- Verify Azure Policy is enabled
- Try different search terms

**"Policy evaluation pending"**

- Wait 30 minutes for initial evaluation
- Check assignment scope matches resources
- Verify policy effect is not "Disabled"

### Getting Help

1. Check script output for specific error messages
2. Review Azure Policy documentation
3. Verify your Azure permissions
4. Test with simpler scenarios first

## 📖 Additional Resources

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [Policy Definition Structure](https://docs.microsoft.com/azure/governance/policy/concepts/definition-structure)
- [Policy Effects](https://docs.microsoft.com/azure/governance/policy/concepts/effects)
- [Azure Policy Samples](https://github.com/Azure/azure-policy)

## 🤝 Contributing

Feel free to enhance these scripts by:

- Adding new policy examples
- Improving error handling
- Adding more educational content
- Creating additional use case scenarios

---

**Happy Learning!** 🎓

These scripts are designed to make Azure Policy accessible and understandable. Take your time with each script and don't hesitate to re-run them as you learn.
