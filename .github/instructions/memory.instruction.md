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
