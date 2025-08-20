# GitHub Actions Pre-commit Integration

This document describes the GitHub Action workflow that automatically runs pre-commit checks on code check-in.

## Overview

The pre-commit GitHub Action (`.github/workflows/pre-commit.yml`) ensures code quality and consistency by running the same pre-commit hooks that developers use locally in the CI/CD pipeline.

## Workflow Triggers

The workflow runs automatically on:

- **Pull Requests**: All pull requests targeting `main` or `develop` branches
- **Push Events**: Direct pushes to `main` or `develop` branches
- **Manual Dispatch**: Can be triggered manually from the GitHub Actions tab

## Pre-commit Checks Performed

The workflow runs all hooks defined in `.pre-commit-config.yaml`:

### File Formatting & Validation
- ✅ Trailing whitespace removal
- ✅ End-of-file fixing
- ✅ YAML, JSON, TOML, XML validation
- ✅ Large file detection
- ✅ Merge conflict detection
- ✅ Private key detection

### Python Code Quality
- ✅ **Black** - Code formatting (88 character line length)
- ✅ **isort** - Import sorting with Black profile
- ✅ **flake8** - Linting with extended ignore rules
- ✅ **bandit** - Security vulnerability scanning

### Jupyter Notebooks
- ✅ **nbstripout** - Remove notebook outputs
- ✅ **nbqa-black** - Format notebook code cells
- ✅ **nbqa-isort** - Sort notebook imports
- ✅ **nbqa-flake8** - Lint notebook code with notebook-specific rules

### Shell & PowerShell Scripts
- ✅ **shellcheck** - Shell script linting
- ✅ **PSScriptAnalyzer** - PowerShell script analysis (when available)

### Azure-Specific Validations
- ✅ **Azure Policy JSON** - Validate policy definition syntax
- ✅ **Bicep Templates** - Validate Bicep template syntax
- ✅ **Documentation Structure** - Enforce docs/ folder organization

### Infrastructure as Code
- ✅ **Terraform Format** - Code formatting
- ✅ **Terraform Validate** - Configuration validation
- ✅ **Terraform Docs** - Documentation generation
- ✅ **TFLint** - Terraform linting
- ✅ **Checkov** - Security and compliance scanning

### GitHub Actions
- ✅ **actionlint** - GitHub Actions workflow validation

## Workflow Environment

The workflow runs on `ubuntu-latest` with the following tools installed:

### System Dependencies
- Python 3.11
- jq (JSON processor)
- shellcheck (shell script linter)

### Azure Tools
- Azure CLI (latest)
- PowerShell Core (for PS1 analysis)

### Terraform Tools
- Terraform 1.6.0
- TFLint (latest)
- Checkov (latest)

### Performance Optimizations
- **Pre-commit Cache**: Caches pre-commit environments for faster subsequent runs
- **Dependency Caching**: Reuses installed tools across workflow runs

## Status Badge

The repository includes a status badge in the README.md:

```markdown
[![Pre-commit](https://github.com/stuartshay/azure-policy/workflows/Pre-commit/badge.svg)](https://github.com/stuartshay/azure-policy/actions/workflows/pre-commit.yml)
```

This badge shows:
- ✅ **Green**: All pre-commit checks passed
- ❌ **Red**: One or more pre-commit checks failed
- 🟡 **Yellow**: Workflow is currently running

## Workflow Behavior

### Success Scenario
When all pre-commit checks pass:
1. All hooks execute successfully
2. Workflow completes with success status
3. Status badge shows green
4. Pull request can be merged (if other checks pass)

### Failure Scenario
When pre-commit checks fail:
1. Workflow stops at the first failing hook
2. Detailed error output is provided
3. Status badge shows red
4. Pull request is blocked from merging
5. Developer must fix issues and push new commits

### Summary Report
The workflow generates a summary report showing:
- Overall status (pass/fail)
- List of all checks performed
- Timestamp of execution
- Links to detailed logs

## Local vs CI Consistency

The GitHub Action uses the exact same `.pre-commit-config.yaml` file as local development, ensuring:

- **Identical Checks**: Same hooks run locally and in CI
- **Consistent Results**: No surprises when pushing code
- **Predictable Behavior**: Developers can test locally before pushing

## Troubleshooting

### Common Issues

#### 1. Checkov Path Error
**Problem**: Checkov fails with hardcoded path error
**Solution**: The workflow automatically fixes the path in `.pre-commit-config.yaml` during execution

#### 2. PowerShell Not Available
**Problem**: PowerShell hooks fail in CI
**Solution**: The workflow installs PowerShell Core; local hooks gracefully handle missing PowerShell

#### 3. Azure CLI Authentication
**Problem**: Bicep validation fails due to authentication
**Solution**: Bicep validation gracefully skips when Azure CLI is not authenticated

#### 4. Tool Installation Failures
**Problem**: Required tools fail to install
**Solution**: Check the workflow logs for specific installation errors and update tool versions if needed

### Debugging Steps

1. **Check Workflow Logs**: Go to Actions tab → Pre-commit workflow → View logs
2. **Run Locally**: Execute `pre-commit run --all-files` locally to reproduce issues
3. **Update Hooks**: Ensure `.pre-commit-config.yaml` uses compatible tool versions
4. **Test Specific Hooks**: Run individual hooks with `pre-commit run <hook-id>`

## Maintenance

### Updating Tool Versions

To update tool versions in the workflow:

1. **Pre-commit Hooks**: Update versions in `.pre-commit-config.yaml`
2. **System Tools**: Update installation commands in workflow
3. **Terraform**: Update version in `hashicorp/setup-terraform` action
4. **Python**: Update version in `actions/setup-python` action

### Adding New Checks

To add new pre-commit checks:

1. Add hook to `.pre-commit-config.yaml`
2. Test locally with `pre-commit run --all-files`
3. Ensure required tools are installed in the workflow
4. Update this documentation

## Integration with Development Workflow

### For Developers

1. **Install Pre-commit Locally**:
   ```bash
   pip install pre-commit
   pre-commit install
   ```

2. **Run Before Committing**:
   ```bash
   pre-commit run --all-files
   ```

3. **Fix Issues**: Address any failures before pushing

4. **Push with Confidence**: CI will run the same checks

### For Code Reviews

1. **Automated Quality**: Pre-commit handles formatting and basic quality
2. **Focus on Logic**: Reviewers can focus on business logic and architecture
3. **Consistent Style**: All code follows the same formatting standards
4. **Security Baseline**: Basic security checks are automated

## Related Documentation

- **Pre-commit Integration**: `docs/PRE_COMMIT_INTEGRATION.md`
- **GitHub Actions Overview**: `docs/GITHUB_ACTIONS_FIX_SUMMARY.md`
- **Development Workflow**: `README.md#development-workflow`
- **Testing Framework**: `docs/TESTING.md`

## Best Practices

1. **Run Locally First**: Always run pre-commit locally before pushing
2. **Keep Hooks Updated**: Regularly update hook versions for security and features
3. **Monitor Performance**: Watch workflow execution times and optimize as needed
4. **Document Changes**: Update this documentation when modifying the workflow
5. **Test Thoroughly**: Test workflow changes in a feature branch before merging
