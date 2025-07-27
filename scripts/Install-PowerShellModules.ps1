#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs and manages PowerShell modules for Azure Policy and Functions development.

.DESCRIPTION
    This script installs essential PowerShell modules for Azure development, including
    Azure PowerShell modules, security tools, and development utilities. It provides
    functions to install, update, and manage PowerShell modules consistently across
    development environments.

.PARAMETER Force
    Forces reinstallation of modules even if they already exist

.PARAMETER Scope
    Installation scope: AllUsers or CurrentUser (default: CurrentUser)

.PARAMETER SkipPublisherCheck
    Skip publisher verification for modules (useful in automated environments)

.EXAMPLE
    ./Install-PowerShellModules.ps1
    Installs all modules for the current user

.EXAMPLE
    ./Install-PowerShellModules.ps1 -Force -Scope AllUsers
    Forces reinstallation for all users

.NOTES
    Author: Azure Policy & Functions Development Team
    Version: 1.0.0
    Last Modified: 2025-01-27
#>

[CmdletBinding()]
param (
    [Parameter(HelpMessage = "Force reinstallation of modules")]
    [switch]$Force,

    [Parameter(HelpMessage = "Installation scope")]
    [ValidateSet("AllUsers", "CurrentUser")]
    [string]$Scope = "CurrentUser",

    [Parameter(HelpMessage = "Skip publisher verification")]
    [switch]$SkipPublisherCheck
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Define color functions for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )

    $colors = @{
        "Red" = [System.ConsoleColor]::Red
        "Green" = [System.ConsoleColor]::Green
        "Yellow" = [System.ConsoleColor]::Yellow
        "Blue" = [System.ConsoleColor]::Blue
        "Cyan" = [System.ConsoleColor]::Cyan
        "Magenta" = [System.ConsoleColor]::Magenta
        "White" = [System.ConsoleColor]::White
        "Gray" = [System.ConsoleColor]::Gray
        "DarkGray" = [System.ConsoleColor]::DarkGray
    }

    if ($colors.ContainsKey($Color)) {
        Write-Host $Message -ForegroundColor $colors[$Color]
    } else {
        Write-Host $Message -ForegroundColor White
    }
}

function Write-Header {
    param([string]$Title)
    Write-ColorOutput "`n=== $Title ===" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" "Red"
}

# Define module groups
$ModuleGroups = @{
    "Core Azure Modules" = @(
        @{
            Name = "Az"
            Description = "Azure PowerShell module - comprehensive Azure management"
            MinimumVersion = "11.0.0"
            Essential = $true
        },
        @{
            Name = "Az.Accounts"
            Description = "Azure authentication and account management"
            MinimumVersion = "2.15.0"
            Essential = $true
        },
        @{
            Name = "Az.Profile"
            Description = "Azure profile and context management"
            MinimumVersion = "1.15.0"
            Essential = $true
        },
        @{
            Name = "Az.Resources"
            Description = "Azure Resource Manager operations"
            MinimumVersion = "6.12.0"
            Essential = $true
        },
        @{
            Name = "Az.Storage"
            Description = "Azure Storage account management"
            MinimumVersion = "6.1.0"
            Essential = $true
        }
    )

    "Policy & Governance" = @(
        @{
            Name = "Az.PolicyInsights"
            Description = "Azure Policy compliance and insights"
            MinimumVersion = "1.6.0"
            Essential = $true
        },
        @{
            Name = "Az.ResourceGraph"
            Description = "Azure Resource Graph queries"
            MinimumVersion = "0.13.0"
            Essential = $true
        },
        @{
            Name = "Az.Security"
            Description = "Azure Security Center management"
            MinimumVersion = "1.6.0"
            Essential = $false
        }
    )

    "Functions & Compute" = @(
        @{
            Name = "Az.Functions"
            Description = "Azure Functions management"
            MinimumVersion = "4.0.8"
            Essential = $true
        },
        @{
            Name = "Az.Websites"
            Description = "Azure App Service and Function Apps"
            MinimumVersion = "3.1.0"
            Essential = $true
        },
        @{
            Name = "Az.Monitor"
            Description = "Azure Monitor and Application Insights"
            MinimumVersion = "4.5.0"
            Essential = $false
        }
    )

    "Development Tools" = @(
        @{
            Name = "PSScriptAnalyzer"
            Description = "PowerShell script analysis and linting"
            MinimumVersion = "1.21.0"
            Essential = $true
        },
        @{
            Name = "Pester"
            Description = "PowerShell testing framework"
            MinimumVersion = "5.5.0"
            Essential = $true
        },
        @{
            Name = "PowerShellGet"
            Description = "PowerShell module management"
            MinimumVersion = "2.2.5"
            Essential = $true
        },
        @{
            Name = "Microsoft.PowerShell.SecretManagement"
            Description = "Secret management framework"
            MinimumVersion = "1.1.2"
            Essential = $false
        },
        @{
            Name = "Microsoft.PowerShell.SecretStore"
            Description = "Local secret store vault"
            MinimumVersion = "1.0.6"
            Essential = $false
        }
    )

    "Utility Modules" = @(
        @{
            Name = "ImportExcel"
            Description = "Excel file manipulation without Excel"
            MinimumVersion = "7.8.6"
            Essential = $false
        },
        @{
            Name = "PowerHTML"
            Description = "HTML parsing and manipulation"
            MinimumVersion = "0.2.3"
            Essential = $false
        },
        @{
            Name = "PSReadLine"
            Description = "Enhanced command line editing"
            MinimumVersion = "2.3.4"
            Essential = $false
        }
    )
}

function Test-ModuleInstalled {
    param(
        [string]$ModuleName,
        [string]$MinimumVersion = $null
    )

    $module = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1

    if (-not $module) {
        return $false
    }

    if ($MinimumVersion -and ($module.Version -lt [version]$MinimumVersion)) {
        return $false
    }

    return $true
}

function Install-PowerShellModule {
    param(
        [hashtable]$ModuleInfo,
        [string]$InstallScope,
        [bool]$ForceInstall,
        [bool]$SkipPublisher
    )

    $moduleName = $ModuleInfo.Name
    $minVersion = $ModuleInfo.MinimumVersion
    $description = $ModuleInfo.Description

    Write-ColorOutput "  📦 $moduleName" "White"
    Write-ColorOutput "     $description" "Gray"

    try {
        # Check if module is already installed with correct version
        if (-not $ForceInstall -and (Test-ModuleInstalled -ModuleName $moduleName -MinimumVersion $minVersion)) {
            $installedVersion = (Get-Module -ListAvailable -Name $moduleName | Sort-Object Version -Descending | Select-Object -First 1).Version
            Write-ColorOutput "     Already installed (v$installedVersion)" "Green"
            return $true
        }

        # Prepare installation parameters
        $installParams = @{
            Name = $moduleName
            Scope = $InstallScope
            Force = $ForceInstall
            AllowClobber = $true
        }

        if ($minVersion) {
            $installParams.MinimumVersion = $minVersion
        }

        if ($SkipPublisher) {
            $installParams.SkipPublisherCheck = $true
        }

        # Install the module
        Install-Module @installParams

        # Verify installation
        if (Test-ModuleInstalled -ModuleName $moduleName -MinimumVersion $minVersion) {
            $installedVersion = (Get-Module -ListAvailable -Name $moduleName | Sort-Object Version -Descending | Select-Object -First 1).Version
            Write-ColorOutput "     Installed successfully (v$installedVersion)" "Green"
            return $true
        } else {
            Write-ColorOutput "     Installation verification failed" "Red"
            return $false
        }

    } catch {
        Write-ColorOutput "     Installation failed: $($_.Exception.Message)" "Red"
        return $false
    }
}

function Show-ModuleSummary {
    Write-Header "Installation Summary"

    $totalModules = 0
    $installedModules = 0
    $failedModules = @()

    foreach ($groupName in $ModuleGroups.Keys) {
        Write-ColorOutput "`n${groupName}:" "Yellow"

        foreach ($module in $ModuleGroups[$groupName]) {
            $totalModules++
            $moduleName = $module.Name
            $minVersion = $module.MinimumVersion

            if (Test-ModuleInstalled -ModuleName $moduleName -MinimumVersion $minVersion) {
                $installedVersion = (Get-Module -ListAvailable -Name $moduleName | Sort-Object Version -Descending | Select-Object -First 1).Version
                Write-ColorOutput "  ✅ $moduleName (v$installedVersion)" "Green"
                $installedModules++
            } else {
                Write-ColorOutput "  ❌ $moduleName (not installed or outdated)" "Red"
                $failedModules += $moduleName
            }
        }
    }

    Write-ColorOutput "`nOverall Status:" "Cyan"
    Write-ColorOutput "  Total modules: $totalModules" "White"
    Write-ColorOutput "  Successfully installed: $installedModules" "Green"
    Write-ColorOutput "  Failed/Missing: $($totalModules - $installedModules)" "Red"

    if ($failedModules.Count -gt 0) {
        Write-ColorOutput "`nFailed modules:" "Red"
        foreach ($module in $failedModules) {
            Write-ColorOutput "  - $module" "Red"
        }
    }

    $successRate = [math]::Round(($installedModules / $totalModules) * 100, 1)
    Write-ColorOutput "`nSuccess rate: $successRate%" $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
}

function Set-PowerShellExecutionPolicy {
    Write-Header "Configuring PowerShell Execution Policy"

    try {
        $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
        Write-ColorOutput "Current execution policy: $currentPolicy" "White"

        if ($currentPolicy -eq "Restricted") {
            Write-ColorOutput "Setting execution policy to RemoteSigned for CurrentUser..." "Yellow"
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Success "Execution policy updated to RemoteSigned"
        } else {
            Write-Success "Execution policy is already configured appropriately"
        }
    } catch {
        Write-Warning "Could not modify execution policy: $($_.Exception.Message)"
    }
}

function Initialize-PowerShellGallery {
    Write-Header "Initializing PowerShell Gallery"

    try {
        $gallery = Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue

        if ($gallery.InstallationPolicy -ne "Trusted") {
            Write-ColorOutput "Setting PowerShell Gallery as trusted repository..." "Yellow"
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
            Write-Success "PowerShell Gallery is now trusted"
        } else {
            Write-Success "PowerShell Gallery is already trusted"
        }

        # Update PowerShellGet if needed
        $currentPSGet = Get-Module -ListAvailable -Name PowerShellGet | Sort-Object Version -Descending | Select-Object -First 1
        if ($currentPSGet.Version -lt [version]"2.2.5") {
            Write-ColorOutput "Updating PowerShellGet..." "Yellow"
            Install-Module -Name PowerShellGet -Force -Scope $Scope
            Write-Success "PowerShellGet updated"
        }

    } catch {
        Write-Warning "Could not configure PowerShell Gallery: $($_.Exception.Message)"
    }
}

# Main execution
try {
    Write-Header "Azure Policy & Functions PowerShell Module Installer"
    Write-ColorOutput "Installation scope: $Scope" "White"
    Write-ColorOutput "Force reinstall: $Force" "White"
    Write-ColorOutput "Skip publisher check: $SkipPublisherCheck" "White"

    # Configure PowerShell environment
    Set-PowerShellExecutionPolicy
    Initialize-PowerShellGallery

    # Install modules by group
    $installationResults = @{}

    foreach ($groupName in $ModuleGroups.Keys) {
        Write-Header "Installing $groupName"

        $installationResults[$groupName] = @{
            Total = $ModuleGroups[$groupName].Count
            Success = 0
            Failed = 0
        }

        foreach ($module in $ModuleGroups[$groupName]) {
            $result = Install-PowerShellModule -ModuleInfo $module -InstallScope $Scope -ForceInstall $Force -SkipPublisher $SkipPublisherCheck

            if ($result) {
                $installationResults[$groupName].Success++
            } else {
                $installationResults[$groupName].Failed++
            }
        }

        $groupSuccess = $installationResults[$groupName].Success
        $groupTotal = $installationResults[$groupName].Total
        Write-ColorOutput "`n${groupName}: $groupSuccess/$groupTotal modules installed successfully" $(if ($groupSuccess -eq $groupTotal) { "Green" } else { "Yellow" })
    }

    # Show final summary
    Show-ModuleSummary

    Write-Header "Quick Start Commands"
    Write-ColorOutput @"
# Connect to Azure
Connect-AzAccount

# Set subscription context
Set-AzContext -SubscriptionId "your-subscription-id"

# List Azure Policy definitions
Get-AzPolicyDefinition | Select-Object Name, DisplayName

# Get compliance summary
Get-AzPolicyStateSummary

# Create a new policy assignment
New-AzPolicyAssignment -Name "MyPolicy" -PolicyDefinition (Get-AzPolicyDefinition -Name "PolicyName") -Scope "/subscriptions/your-subscription-id"

# Query resources with Azure Resource Graph
Search-AzGraph -Query "Resources | where type == 'microsoft.storage/storageaccounts' | project name, location"

# List Function Apps
Get-AzFunctionApp

# Test PowerShell scripts
Invoke-ScriptAnalyzer -Path "your-script.ps1"
"@ "Gray"

    Write-Success "`nPowerShell module installation completed!"
    Write-ColorOutput "You can now use PowerShell for Azure Policy and Functions development." "White"

} catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
    exit 1
}
