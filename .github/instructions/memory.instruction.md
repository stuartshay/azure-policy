---
applyTo: '**'
---

# User Memory

## User Preferences
- Programming languages: Python
- Code style preferences: Favors absolute imports for test discovery
- Development environment: VS Code, Linux, zsh
- Communication style: Concise, step-by-step, prefers robust solutions

## Project Context
- Current project type: Azure Functions, multi-folder Python project
- Tech stack: Python, Azure Functions, pytest, VS Code
- Architecture patterns: Modular, per-function subfolders with venvs
- Key requirements: All function test folders must be available in VS Code Test Explorer

## Coding Patterns
- Uses per-function venvs and test folders
- Test files use pytest and unittest
- Test discovery should work for all function folders

## Context7 Research History
- Not yet used for this project

## Monitoring Workspace Integration (PR #99)

### Summary of Changes
- Added new monitoring infrastructure workspace using a dedicated Terraform module (v0.5.0)
- Replaced hardcoded Application Insights workbook GUID with random_uuid resource
- Consolidated required_providers blocks in monitoring module to avoid Terraform validation errors
- Created terraform.tfvars.example for user configuration
- Updated monitoring/README.md for clear setup instructions
- Integrated monitoring workspace into Makefile, pre-commit, and GitHub Actions workflows (terraform-validate, terraform-apply)
- Validated module versioning and provider constraints (azurerm ~> 4.40, random >= 3.0)
- Ran pre-commit and CI/CD validation: all checks now pass

### Lessons Learned & Best Practices
- Always consolidate required_providers in a single terraform block per module to avoid validation errors
- Use random_uuid for unique resource names instead of hardcoded values
- Provide terraform.tfvars.example for user onboarding and documentation
- Keep documentation (README.md) in sync with module and workflow changes
- Ensure Makefile and CI/CD workflows are updated to include new workspaces/modules
- Run pre-commit and CI/CD validation after every major change
- Address all reviewer comments and validation warnings before merging

### Validation Results
- All pre-commit hooks (lint, format, security, docs, Terraform validate, tflint, checkov) pass
- Terraform validate and tflint confirm no duplicate provider or config errors
- CI/CD workflows now include monitoring workspace and pass all checks

### Next Steps
- Continue to use these patterns for future module/workspace additions
- Review .pre-commit-config.yaml and workflows when adding new modules
- Document any new best practices in memory for future reference

## Conversation History
- Problem: Only main tests folder was available in Test Explorer, function-specific test folders were not
- Solution: Added/updated .vscode/settings.json in each function folder to use its own venv and pytest for test discovery; fixed import in basic function test
- Result: All function test folders now available in Test Explorer; some test failures remain but are unrelated to discovery

## Notes
- If new function folders are added, ensure they have their own .vscode/settings.json for test discovery
- Use absolute imports in test files for robust discovery

## terraform-docs README.md Overwrite Root Cause

### Why does README.md get overwritten?
- The Makefile and CI/CD workflows (see docs-generate and pre-commit.yml) run `terraform-docs markdown table --output-file README.md --output-mode inject ...`.
- The pre-commit hook for terraform-docs (in .pre-commit-config.yaml) and the GitHub Actions workflow both auto-generate or update README.md files for Terraform modules and sometimes for the project root.
- If run in the wrong directory, or if the configuration is too broad, this can overwrite the main project README.md with Terraform module documentation.

### How to prevent accidental overwrite:
- Ensure terraform-docs is only run in module directories, not the project root, unless intentional.
- Check .pre-commit-config.yaml and Makefile to scope terraform-docs hooks to module subfolders only.
- Review CI/CD workflow steps to avoid running terraform-docs in the root unless desired.

### Recovery:
- Restore README.md from the master branch or backup if overwritten.

### Recommendation:
- Consider adding a test or CI check to detect if the root README.md was replaced with terraform-docs output and fail the build if so.
