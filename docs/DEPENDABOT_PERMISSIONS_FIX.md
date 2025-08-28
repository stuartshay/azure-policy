# Dependabot Pull Request Creation Fix

## Problem
Dependabot is detecting outdated packages but failing to create pull requests with the error:
```
Posting metrics to remote API endpoint but not creating a PR, do we need to set permissions
```

## Affected Updates
- `azure-policy-cloud/app-service-plan-function/azurerm` (from 1.1.34 to 1.1.35)
- `hashicorp/azurerm` (from 4.40.0 to 4.41.0)

## Root Cause
The issue appears to be related to GitHub repository permissions preventing Dependabot from creating pull requests.

## Solutions

### 1. Check Repository Settings

Navigate to **Repository Settings > Actions > General**:

- **Workflow permissions** should be set to:
  - ✅ "Read and write permissions"
  - ✅ "Allow GitHub Actions to create and approve pull requests" (checked)

### 2. Enable Dependabot Features

Go to **Settings > Code security and analysis** and ensure these are enabled:
- ✅ Dependabot alerts
- ✅ Dependabot security updates
- ✅ Dependabot version updates

### 3. Review Branch Protection Rules

If branch protection is enabled on `develop` or `master`:

- Go to **Settings > Branches**
- For protected branches, ensure:
  - "Allow specified actors to bypass required pull requests" includes `dependabot[bot]`
  - "Restrict pushes that create files" is disabled
  - Or add `dependabot[bot]` to allowed actors

### 4. Manual Testing

Test Dependabot manually:
1. Navigate to **Insights > Dependency graph > Dependabot**
2. Click "Check for updates" on Terraform ecosystem
3. Monitor if PRs are created successfully

### 5. Repository Permission Check

Verify that:
- Repository has "Issues" and "Pull Requests" features enabled
- No organization-level policies are restricting Dependabot
- Repository owner has necessary permissions

## Expected Outcome

After applying these fixes, Dependabot should:
- Detect dependency updates
- Successfully create pull requests
- Assign PRs to `stuartshay` as configured
- Apply appropriate labels and commit message prefixes

## Verification

To verify the fix is working:
1. Check for new Dependabot PRs in the repository
2. Monitor Dependabot logs in Actions for successful runs
3. Ensure PRs are created for the pending updates mentioned above

### Automated Testing with GitHub Actions

A new GitHub Actions workflow has been created to help test and monitor Dependabot:

**File**: `.github/workflows/dependabot-test.yml`

**Features**:
- **Config Validation**: Validates `dependabot.yml` syntax and structure
- **Update Checking**: Scans for potentially outdated dependencies
- **PR Monitoring**: Lists current and recent Dependabot pull requests
- **Permission Testing**: Verifies GitHub Actions permissions for PR creation

**Usage**:
1. **Manual Trigger**: Go to Actions → Dependabot Test and Monitor → Run workflow
2. **Scheduled**: Runs automatically every Monday at 9:00 AM
3. **Automatic**: Triggers when `dependabot.yml` is modified

**Test Types Available**:
- `check-updates` - Look for available dependency updates
- `validate-config` - Verify Dependabot configuration
- `monitor-prs` - Check status of Dependabot PRs
- `test-permissions` - Validate GitHub Actions permissions

## Related Files
- `.github/dependabot.yml` - Dependabot configuration
- `.github/workflows/dependabot-test.yml` - Testing and monitoring workflow
- Repository Settings - Permission configurations

## Date
August 28, 2025
