#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Configures PowerShell profile for Azure Policy and Functions development.

.DESCRIPTION
    This script sets up a PowerShell profile with useful aliases, functions, and
    configurations for Azure development. It includes shortcuts for common Azure
    operations, enhanced prompt, and development utilities.

.PARAMETER Force
    Forces overwrite of existing profile

.EXAMPLE
    ./Setup-PowerShellProfile.ps1
    Sets up the PowerShell profile

.EXAMPLE
    ./Setup-PowerShellProfile.ps1 -Force
    Forces overwrite of existing profile

.NOTES
    Author: Azure Policy & Functions Development Team
    Version: 1.0.0
    Last Modified: 2025-01-27
#>

[CmdletBinding()]
param (
    [Parameter(HelpMessage = "Force overwrite of existing profile")]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Profile content
$ProfileContent = @'
# Azure Policy & Functions Development PowerShell Profile
# Generated on {0}

# Set console encoding for better character support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Import essential modules
$ModulesToImport = @('Az.Accounts', 'Az.Resources', 'Az.PolicyInsights', 'Az.Functions')
foreach ($Module in $ModulesToImport) {
    if (Get-Module -ListAvailable -Name $Module) {
        Import-Module $Module -Global -Force -WarningAction SilentlyContinue
    }
}

# Azure Authentication Helpers
function Connect-Azure {
    <#
    .SYNOPSIS
    Quick Azure authentication with subscription selection
    #>
    [CmdletBinding()]
    param(
        [string]$SubscriptionId,
        [string]$TenantId
    )

    $connectParams = @{}
    if ($TenantId) { $connectParams.TenantId = $TenantId }

    Connect-AzAccount @connectParams

    if ($SubscriptionId) {
        Set-AzContext -SubscriptionId $SubscriptionId
    } else {
        # Show available subscriptions
        Get-AzSubscription | Format-Table Name, Id, State -AutoSize
        Write-Host "Use 'Set-AzContext -SubscriptionId <id>' to select a subscription" -ForegroundColor Yellow
    }
}

function Get-AzureContext {
    <#
    .SYNOPSIS
    Display current Azure context information
    #>
    $context = Get-AzContext
    if ($context) {
        [PSCustomObject]@{
            Account = $context.Account.Id
            Subscription = $context.Subscription.Name
            SubscriptionId = $context.Subscription.Id
            Tenant = $context.Tenant.Id
            Environment = $context.Environment.Name
        } | Format-List
    } else {
        Write-Warning "Not connected to Azure. Use Connect-Azure to authenticate."
    }
}

# Policy Management Functions
function Get-PolicyCompliance {
    <#
    .SYNOPSIS
    Get policy compliance summary
    #>
    [CmdletBinding()]
    param(
        [string]$Scope,
        [string]$PolicyName
    )

    $params = @{}
    if ($Scope) { $params.Scope = $Scope }
    if ($PolicyName) { $params.PolicyDefinitionName = $PolicyName }

    Get-AzPolicyStateSummary @params | Format-Table -AutoSize
}

function Search-AzureResources {
    <#
    .SYNOPSIS
    Quick Azure Resource Graph queries
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        [int]$Top = 100
    )

    if (-not (Get-Module -ListAvailable -Name Az.ResourceGraph)) {
        Write-Error "Az.ResourceGraph module not installed. Install with: Install-Module Az.ResourceGraph"
        return
    }

    Import-Module Az.ResourceGraph -Force
    Search-AzGraph -Query $Query -First $Top
}

function Get-NonCompliantResources {
    <#
    .SYNOPSIS
    Get resources that are not compliant with policies
    #>
    [CmdletBinding()]
    param(
        [string]$PolicyName,
        [string]$Scope
    )

    $params = @{
        Filter = "ComplianceState eq 'NonCompliant'"
    }

    if ($PolicyName) { $params.PolicyDefinitionName = $PolicyName }
    if ($Scope) { $params.Scope = $Scope }

    Get-AzPolicyState @params | Select-Object ResourceId, PolicyDefinitionName, ComplianceState, PolicyAssignmentName
}

# Function App Helpers
function Get-FunctionApps {
    <#
    .SYNOPSIS
    List Function Apps with key information
    #>
    Get-AzFunctionApp | Select-Object Name, ResourceGroupName, Location, State, Runtime | Format-Table -AutoSize
}

function Get-FunctionAppLogs {
    <#
    .SYNOPSIS
    Get recent logs for a Function App
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionAppName,
        [string]$ResourceGroupName,
        [int]$Hours = 1
    )

    $endTime = Get-Date
    $startTime = $endTime.AddHours(-$Hours)

    # This would require Application Insights integration
    Write-Host "To view logs, ensure Application Insights is configured for $FunctionAppName" -ForegroundColor Yellow
    Write-Host "Then use: Get-AzApplicationInsightsQuery for detailed log analysis" -ForegroundColor Gray
}

# Development Utilities
function Test-PowerShellScript {
    <#
    .SYNOPSIS
    Run PSScriptAnalyzer on PowerShell scripts
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Error "PSScriptAnalyzer module not installed. Install with: Install-Module PSScriptAnalyzer"
        return
    }

    Import-Module PSScriptAnalyzer -Force
    Invoke-ScriptAnalyzer -Path $Path -ReportSummary
}

function Format-Json {
    <#
    .SYNOPSIS
    Format JSON strings for readability
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string]$JsonString
    )

    process {
        try {
            $JsonString | ConvertFrom-Json | ConvertTo-Json -Depth 20
        } catch {
            Write-Error "Invalid JSON: $($_.Exception.Message)"
        }
    }
}

# Aliases for common operations
Set-Alias -Name azctx -Value Get-AzureContext
Set-Alias -Name azconnect -Value Connect-Azure
Set-Alias -Name policies -Value Get-AzPolicyDefinition
Set-Alias -Name compliance -Value Get-PolicyCompliance
Set-Alias -Name functions -Value Get-FunctionApps
Set-Alias -Name analyze -Value Test-PowerShellScript
Set-Alias -Name jformat -Value Format-Json

# Enhanced prompt with Azure context
function prompt {
    $originalTitle = $Host.UI.RawUI.WindowTitle

    # Get current location
    $currentPath = (Get-Location).Path
    $homePath = [Environment]::GetFolderPath("UserProfile")
    if ($currentPath.StartsWith($homePath)) {
        $currentPath = $currentPath.Replace($homePath, "~")
    }

    # Get Azure context if available
    $azureInfo = ""
    try {
        $context = Get-AzContext -ErrorAction SilentlyContinue
        if ($context) {
            $subName = $context.Subscription.Name
            if ($subName.Length -gt 15) {
                $subName = $subName.Substring(0, 12) + "..."
            }
            $azureInfo = " [Az: $subName]"
        }
    } catch {
        # Ignore errors
    }

    # Color coding
    $pathColor = "Blue"
    $azureColor = "Green"
    $promptColor = "Yellow"

    # Build prompt
    Write-Host $currentPath -ForegroundColor $pathColor -NoNewline
    if ($azureInfo) {
        Write-Host $azureInfo -ForegroundColor $azureColor -NoNewline
    }
    Write-Host " PS>" -ForegroundColor $promptColor -NoNewline

    # Set window title
    $Host.UI.RawUI.WindowTitle = "PowerShell - $currentPath$azureInfo"

    return " "
}

# Welcome message
Write-Host ""
Write-Host "🚀 Azure Policy & Functions PowerShell Environment Loaded!" -ForegroundColor Green
Write-Host ""
Write-Host "Quick Commands:" -ForegroundColor Yellow
Write-Host "  azconnect          - Connect to Azure" -ForegroundColor Gray
Write-Host "  azctx              - Show Azure context" -ForegroundColor Gray
Write-Host "  policies           - List policy definitions" -ForegroundColor Gray
Write-Host "  compliance         - Check policy compliance" -ForegroundColor Gray
Write-Host "  functions          - List Function Apps" -ForegroundColor Gray
Write-Host "  analyze <file>     - Analyze PowerShell script" -ForegroundColor Gray
Write-Host ""
Write-Host "Resource Queries:" -ForegroundColor Yellow
Write-Host "  Search-AzureResources 'Resources | limit 10'" -ForegroundColor Gray
Write-Host "  Get-NonCompliantResources -PolicyName 'MyPolicy'" -ForegroundColor Gray
Write-Host ""

# Auto-connect if in DevContainer or CI
if ($env:REMOTE_CONTAINERS -eq "true" -or $env:CI -eq "true") {
    Write-Host "DevContainer detected. Use 'azconnect' to authenticate with Azure." -ForegroundColor Cyan
}
'@

try {
    Write-Host "🔧 Setting up PowerShell profile..." -ForegroundColor Cyan

    # Get profile path
    $profilePath = $PROFILE.CurrentUserAllHosts
    $profileDir = Split-Path $profilePath -Parent

    # Create profile directory if it doesn't exist
    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        Write-Host "✅ Created profile directory: $profileDir" -ForegroundColor Green
    }

    # Check if profile exists
    if ((Test-Path $profilePath) -and -not $Force) {
        Write-Host "⚠️  PowerShell profile already exists at: $profilePath" -ForegroundColor Yellow
        $choice = Read-Host "Do you want to overwrite it? (y/N)"
        if ($choice -notmatch '^[Yy]') {
            Write-Host "❌ Profile setup cancelled." -ForegroundColor Red
            exit 0
        }
    }

    # Create profile content with current date
    $currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $finalContent = $ProfileContent.Replace("{0}", $currentDate)

    # Write profile
    $finalContent | Out-File -FilePath $profilePath -Encoding UTF8 -Force

    Write-Host "✅ PowerShell profile created successfully!" -ForegroundColor Green
    Write-Host "📍 Profile location: $profilePath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🔄 To reload the profile in current session, run:" -ForegroundColor Yellow
    Write-Host "   . `$PROFILE" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🚀 The profile will be automatically loaded in new PowerShell sessions." -ForegroundColor Green

} catch {
    Write-Host "❌ Failed to setup PowerShell profile: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
