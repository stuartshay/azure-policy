# Detect-Secrets Configuration Guide

This document explains how to handle the detect-secrets configuration and resolve common issues.

## Overview

The detect-secrets tool is configured to scan for potential secrets in the codebase. It uses a baseline file (`.secrets.baseline`) to track known false positives and legitimate secrets that should be committed.

## Current Issue: Baseline Updates

The detect-secrets hook is currently updating the baseline file on every run due to line number changes. This is a known issue that occurs when:

1. Files containing tracked secrets are modified
2. Line numbers change, causing detect-secrets to update the baseline
3. The baseline becomes "unstaged" and needs to be re-added

## Solutions

### Option 1: Commit Current State (Recommended)

Since we've already audited the secrets and marked them as safe, we can commit the current baseline:

```bash
# Add the current baseline
git add .secrets.baseline

# Commit with other changes
git commit -m "Update secrets baseline after security audit"
```

### Option 2: Disable Line Number Tracking

We can modify the baseline to be less sensitive to line number changes by using the `--no-verify` flag when needed:

```bash
# Skip pre-commit hooks when committing baseline updates
git commit --no-verify -m "Update secrets baseline"
```

### Option 3: Regenerate Baseline Completely

If the baseline becomes too problematic, regenerate it:

```bash
# Remove current baseline
rm .secrets.baseline

# Create new baseline
detect-secrets scan --baseline .secrets.baseline

# Audit the new baseline
detect-secrets audit .secrets.baseline

# Add to git
git add .secrets.baseline
```

## Configuration Files

### .secrets.baseline
- Contains the current state of detected secrets
- Tracks line numbers and file locations
- Should be committed to the repository

### .secrets.yaml (Optional)
- Configuration file for detect-secrets behavior
- Currently not used due to version compatibility

### .secrets.allowlist (Optional)
- Contains patterns that should be ignored
- Useful for common false positives

## Best Practices

1. **Regular Audits**: Periodically review the baseline file
2. **Team Communication**: Ensure team members understand the workflow
3. **Documentation**: Keep this guide updated with any changes
4. **Version Control**: Always commit baseline changes with descriptive messages

## Troubleshooting

### Baseline Keeps Updating
- This is normal behavior when files change
- Add the baseline file and commit the changes
- Consider using `--no-verify` for baseline-only commits

### False Positives
- Use `detect-secrets audit .secrets.baseline` to mark as safe
- Add patterns to `.secrets.allowlist` if needed
- Update exclusion patterns in `.pre-commit-config.yaml`

### Version Conflicts
- Ensure detect-secrets version in pre-commit config matches installed version
- Use `pre-commit autoupdate` to update to latest compatible versions

## Commands Reference

```bash
# Scan for secrets and update baseline
detect-secrets scan --baseline .secrets.baseline

# Audit baseline interactively
detect-secrets audit .secrets.baseline

# Check current status
detect-secrets audit .secrets.baseline --report

# Clean pre-commit cache
pre-commit clean

# Update pre-commit hooks
pre-commit autoupdate
```

## Current Status

The detect-secrets configuration is functional but requires manual baseline management due to line number sensitivity. This is a known limitation of the tool and affects many projects using detect-secrets.

The recommended approach is to:
1. Accept that baseline updates are normal
2. Commit baseline changes along with code changes
3. Use `--no-verify` sparingly for baseline-only commits
4. Regularly audit the baseline for new secrets
