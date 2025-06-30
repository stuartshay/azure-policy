# Azure Policy Learning Scripts

A comprehensive collection of interactive scripts to help you learn and master Azure Policy concepts and implementation.

## 🎯 Overview

These scripts provide hands-on experience with Azure Policy, covering everything from basic policy listing to advanced remediation scenarios. Each script is designed to be educational, interactive, and practical.

## 📋 Prerequisites

- Azure CLI installed and configured
- Active Azure subscription
- Appropriate permissions to view and manage Azure Policy
- Bash shell (Linux, macOS, or WSL on Windows)

## 🚀 Quick Start

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

## 📚 Script Descriptions

### Basic Operations

| Script | Description | Learning Focus |
|--------|-------------|----------------|
| `01-list-policies.sh` | Lists built-in and custom Azure policies | Policy discovery, categories |
| `02-show-policy-details.sh` | Shows detailed information about specific policies | Policy structure, rules, parameters |
| `03-list-assignments.sh` | Lists all policy assignments in subscription | Assignment scopes, enforcement modes |
| `04-create-assignment.sh` | Interactive policy assignment creation | Assignment process, scoping |
| `05-compliance-report.sh` | Generates compliance status reports | Compliance evaluation, reporting |

### Advanced Topics

| Script | Description | Learning Focus |
|--------|-------------|----------------|
| `06-list-initiatives.sh` | Explores policy initiatives (policy sets) | Initiative concepts, compliance frameworks |
| `07-create-custom-policy.sh` | Creates custom policy definitions | Policy authoring, JSON structure |
| `08-remediation.sh` | Demonstrates policy remediation | Remediation tasks, managed identities |

### Utilities

| Script | Description |
|--------|-------------|
| `menu.sh` | Interactive menu for all scripts |

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
