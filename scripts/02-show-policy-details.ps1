#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Show Policy Details

.DESCRIPTION
    Shows detailed information about a specific Azure Policy

.PARAMETER PolicyName
    The name or partial name of the policy to search for

.PARAMETER OutputDirectory
    Optional directory to save the policy details to a file. Directory will be created if it doesn't exist.

.EXAMPLE
    ./02-show-policy-details.ps1
    
.EXAMPLE
    ./02-show-policy-details.ps1 -PolicyName "Allowed locations"
    
.EXAMPLE
    ./02-show-policy-details.ps1 "Require a tag"
    
.EXAMPLE
    ./02-show-policy-details.ps1 -PolicyName "Allowed locations" -OutputDirectory "./output"
    
.EXAMPLE
    ./02-show-policy-details.ps1 "Require a tag" -OutputDirectory "/tmp/policy-reports"
#>

param(
    [string]$PolicyName,
    [string]$OutputDirectory
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Initialize output variables
$outputToFile = $false
$outputFilePath = ""

# Check if output directory is specified
if (-not [string]::IsNullOrEmpty($OutputDirectory)) {
    $outputToFile = $true
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputDirectory)) {
        try {
            New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
            Write-Host "✅ Created output directory: $OutputDirectory" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to create output directory: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
    }
    
    # Prepare output file path
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $safeFileName = if ($PolicyName) { 
        ($PolicyName -replace '[^\w\-_]', '_') + "_$timestamp.txt" 
    } else { 
        "policy-details_$timestamp.txt" 
    }
    $outputFilePath = Join-Path $OutputDirectory $safeFileName
    
    Write-Host "📁 Output will be saved to: $outputFilePath" -ForegroundColor Yellow
}

# Function to write output to both console and file
function Write-Output {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
    
    if ($outputToFile) {
        # Remove ANSI color codes for file output and write to file
        $cleanMessage = $Message -replace '\x1b\[[0-9;]*m', ''
        Add-Content -Path $outputFilePath -Value $cleanMessage
    }
}

Write-Output "=== Azure Policy Script ===" "Cyan"
Write-Output "Script: Show Policy Details" "Cyan"
Write-Output "Date: $(Get-Date)" "Gray"
Write-Output ""

# If no policy name provided, show some popular examples
if ([string]::IsNullOrEmpty($PolicyName)) {
    Write-Output "🔍 Usage: $($MyInvocation.MyCommand.Name) [PolicyName] [-OutputDirectory <path>]" "Yellow"
    Write-Output ""
    Write-Output "📝 Popular Built-in Policies to explore:" "Blue"
    Write-Output "========================================" "Blue"
    Write-Output "• Allowed locations" "White"
    Write-Output "• Require a tag on resources" "White"
    Write-Output "• Not allowed resource types" "White"
    Write-Output "• Allowed virtual machine size SKUs" "White"
    Write-Output "• Audit VMs that do not use managed disks" "White"
    Write-Output "• Deploy Log Analytics agent for Linux VMs" "White"
    Write-Output ""
    Write-Output "Example: $($MyInvocation.MyCommand.Name) -PolicyName 'Allowed locations'" "Green"
    Write-Output "Example: $($MyInvocation.MyCommand.Name) 'Allowed locations' -OutputDirectory './reports'" "Green"
    exit 1
}

Write-Output "🔍 Searching for policy: '$PolicyName'" "Yellow"
Write-Output ""

# Search for the policy
try {
    $policyJson = az policy definition list --query "[?contains(displayName, '$PolicyName')]" --output json | ConvertFrom-Json
    
    if ($policyJson.Count -eq 0) {
        Write-Output "❌ No policy found with name containing '$PolicyName'" "Red"
        Write-Output ""
        Write-Output "💡 Try searching with partial names or check available policies with:" "Yellow"
        Write-Output "   ./01-list-policies.ps1" "Gray"
        exit 1
    }
} catch {
    Write-Output "❌ Error searching for policies: $($_.Exception.Message)" "Red"
    exit 1
}

# Show policy details for each found policy
foreach ($policy in $policyJson) {
    Write-Output ""
    Write-Output "📋 Policy Details:" "Magenta"
    Write-Output "==================" "Magenta"
    Write-Output "Name: $($policy.displayName)" "White"
    
    $description = if ($policy.description) { $policy.description } else { "N/A" }
    Write-Output "Description: $description" "Gray"
    
    $category = if ($policy.metadata.category) { $policy.metadata.category } else { "N/A" }
    Write-Output "Category: $category" "Gray"
    Write-Output "Mode: $($policy.mode)" "Gray"
    Write-Output "Type: $($policy.policyType)" "Gray"
    Write-Output "ID: $($policy.id)" "DarkGray"
    
    Write-Output ""
    Write-Output "📜 Policy Rule:" "Blue"
    Write-Output "===============" "Blue"
    
    # Format and display the policy rule JSON
    try {
        $policyRuleFormatted = $policy.policyRule | ConvertTo-Json -Depth 10 -Compress:$false
        Write-Output $policyRuleFormatted "White"
    } catch {
        Write-Output "$($policy.policyRule)" "White"
    }
    
    Write-Output ""
    Write-Output "⚙️  Parameters:" "Green"
    Write-Output "===============" "Green"
    
    if ($policy.parameters) {
        try {
            $parametersFormatted = $policy.parameters | ConvertTo-Json -Depth 10 -Compress:$false
            Write-Output $parametersFormatted "White"
        } catch {
            Write-Output "$($policy.parameters)" "White"
        }
    } else {
        Write-Output "No parameters" "Gray"
    }
    
    Write-Output ""
    Write-Output "🏷️  Metadata:" "Cyan"
    Write-Output "=============" "Cyan"
    
    if ($policy.metadata) {
        try {
            $metadataFormatted = $policy.metadata | ConvertTo-Json -Depth 10 -Compress:$false
            Write-Output $metadataFormatted "White"
        } catch {
            Write-Output "$($policy.metadata)" "White"
        }
    } else {
        Write-Output "No metadata" "Gray"
    }
    
    # If multiple policies found, add separator
    if ($policyJson.Count -gt 1) {
        Write-Output ""
        Write-Output "$(("=" * 80))" "DarkGray"
    }
}

Write-Output ""
Write-Output "💡 Next steps:" "Yellow"
Write-Output "- Run ./03-list-assignments.ps1 to see policy assignments" "Gray"
Write-Output "- Run ./04-create-assignment.ps1 to create a new assignment" "Gray"

# Show summary if multiple policies found
if ($policyJson.Count -gt 1) {
    Write-Output ""
    Write-Output "📊 Search Summary:" "Green"
    Write-Output "Found $($policyJson.Count) policies matching '$PolicyName'" "White"
}

# Show file output confirmation
if ($outputToFile) {
    Write-Output ""
    Write-Output "✅ Policy details have been saved to: $outputFilePath" "Green"
    Write-Output "📁 File size: $((Get-Item $outputFilePath).Length) bytes" "Gray"
}
