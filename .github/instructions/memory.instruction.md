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
