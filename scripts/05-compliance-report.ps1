#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Compliance Report

.DESCRIPTION
    Shows compliance status for Azure Policy assignments

.PARAMETER OutputDirectory
    Optional directory to save the compliance report to a file. Directory will be created if it doesn't exist.

.PARAMETER ResourceGroup
    Optional resource group to filter compliance results. If not specified, shows subscription-wide compliance.

.EXAMPLE
    ./05-compliance-report.ps1
    
.EXAMPLE
    ./05-compliance-report.ps1 -OutputDirectory "./reports"
    
.EXAMPLE
    ./05-compliance-report.ps1 -ResourceGroup "AzurePolicy" -OutputDirectory "./reports"
    
.EXAMPLE
    ./05-compliance-report.ps1 -ResourceGroup "AzurePolicy"
#>

param(
    [string]$OutputDirectory,
    [string]$ResourceGroup
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
    $scopePrefix = if ($ResourceGroup) { "${ResourceGroup}_" } else { "subscription_" }
    $outputFilePath = Join-Path $OutputDirectory "${scopePrefix}compliance-report_$timestamp.txt"
    
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

Write-Output "=== Azure Policy Learning Script ===" "Cyan"
Write-Output "Script: Compliance Report" "Cyan"
Write-Output "Date: $(Get-Date)" "Gray"
if ($ResourceGroup) {
    Write-Output "Scope: Resource Group '$ResourceGroup'" "Yellow"
} else {
    Write-Output "Scope: Current Subscription" "Yellow"
}
Write-Output ""

Write-Output "📊 Policy Compliance Report" "Magenta"
Write-Output "============================" "Magenta"

# Get compliance states
Write-Output "🔍 Gathering compliance data..." "Blue"

try {
    $complianceCommand = if ($ResourceGroup) {
        "az policy state list --resource-group `"$ResourceGroup`" --output json"
    } else {
        "az policy state list --output json"
    }
    
    $complianceData = Invoke-Expression $complianceCommand 2>$null | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0 -or $complianceData.Count -eq 0) {
        Write-Output "⚠️  No compliance data available yet." "Yellow"
        Write-Output ""
        Write-Output "💡 This could mean:" "Yellow"
        Write-Output "   • No policy assignments exist" "Gray"
        Write-Output "   • Policy evaluation hasn't completed yet (can take up to 30 minutes)" "Gray"
        Write-Output "   • No resources exist in the assigned scope" "Gray"
        if ($ResourceGroup) {
            Write-Output "   • Resource group '$ResourceGroup' doesn't exist or has no policies" "Gray"
        }
        Write-Output ""
        Write-Output "🕐 Policy evaluation timeline:" "Cyan"
        Write-Output "   • New assignments: ~30 minutes for first evaluation" "Gray"
        Write-Output "   • Existing assignments: Every 24 hours" "Gray"
        Write-Output "   • On-demand: Can be triggered manually" "Gray"
        Write-Output ""
        Write-Output "💡 Next steps:" "Yellow"
        Write-Output "- Wait for policy evaluation to complete" "Gray"
        Write-Output "- Create some test resources to evaluate" "Gray"
        Write-Output "- Run ./03-list-assignments.ps1 to verify assignments exist" "Gray"
        
        if ($outputToFile) {
            Write-Output ""
            Write-Output "✅ Report has been saved to: $outputFilePath" "Green"
        }
        exit 0
    }
} catch {
    Write-Output "❌ Error retrieving compliance data: $($_.Exception.Message)" "Red"
    exit 1
}

# Overall compliance summary
Write-Output ""
Write-Output "📈 Overall Compliance Summary:" "Green"
Write-Output "==============================" "Green"

$complianceGroups = $complianceData | Group-Object complianceState
foreach ($group in $complianceGroups) {
    $state = $group.Name
    $count = $group.Count
    $color = switch ($state) {
        "Compliant" { "Green" }
        "NonCompliant" { "Red" }
        "Conflict" { "Yellow" }
        default { "Gray" }
    }
    Write-Output "${state}: $count" $color
}

# Calculate overall compliance percentage
$totalResources = $complianceData.Count
$compliantResources = ($complianceData | Where-Object { $_.complianceState -eq "Compliant" }).Count
$compliancePercentage = if ($totalResources -gt 0) { [math]::Round(($compliantResources / $totalResources) * 100, 2) } else { 0 }

Write-Output ""
Write-Output "Overall Compliance Rate: $compliancePercentage% ($compliantResources/$totalResources)" "Cyan"

# Compliance by policy
Write-Output ""
Write-Output "📋 Compliance by Policy Assignment:" "Blue"
Write-Output "====================================" "Blue"

$policyGroups = $complianceData | Group-Object policyAssignmentName
foreach ($policyGroup in $policyGroups) {
    $assignment = $policyGroup.Name
    $resources = $policyGroup.Group
    $compliant = ($resources | Where-Object { $_.complianceState -eq "Compliant" }).Count
    $nonCompliant = ($resources | Where-Object { $_.complianceState -eq "NonCompliant" }).Count
    $total = $resources.Count
    $rate = if ($total -gt 0) { [math]::Floor(($compliant / $total) * 100) } else { 0 }
    
    Write-Output ""
    Write-Output "Assignment: $assignment" "White"
    Write-Output "  Compliant: $compliant" "Green"
    Write-Output "  Non-Compliant: $nonCompliant" "Red"
    Write-Output "  Total Resources: $total" "Gray"
    Write-Output "  Compliance Rate: $rate%" "Cyan"
}

# Non-compliant resources details
Write-Output ""
Write-Output "❌ Non-Compliant Resources:" "Red"
Write-Output "===========================" "Red"

$nonCompliantResources = $complianceData | Where-Object { $_.complianceState -eq "NonCompliant" }

if ($nonCompliantResources.Count -eq 0) {
    Write-Output "🎉 All resources are compliant!" "Green"
} else {
    foreach ($resource in $nonCompliantResources) {
        $resourceName = ($resource.resourceId -split "/")[-1]
        $reason = if ($resource.complianceReasonCode) { $resource.complianceReasonCode } else { "N/A" }
        
        Write-Output ""
        Write-Output "Resource: $resourceName" "White"
        Write-Output "Type: $($resource.resourceType)" "Gray"
        Write-Output "Policy: $($resource.policyAssignmentName)" "Gray"
        Write-Output "Reason: $reason" "Gray"
        Write-Output "Location: $($resource.resourceLocation)" "Gray"
    }
}

# Policy effects summary
Write-Output ""
Write-Output "⚖️  Policy Effects in Use:" "Magenta"
Write-Output "==========================" "Magenta"

try {
    $assignmentsCommand = if ($ResourceGroup) {
        "az policy assignment list --resource-group `"$ResourceGroup`" --output json"
    } else {
        "az policy assignment list --output json"
    }
    
    $assignments = Invoke-Expression $assignmentsCommand | ConvertFrom-Json
    
    foreach ($assignment in $assignments) {
        $assignmentName = if ($assignment.displayName) { $assignment.displayName } else { $assignment.name }
        $effect = if ($assignment.policyDefinitionId -match "policyDefinitions") {
            ($assignment.policyDefinitionId -split "/")[-1]
        } else {
            "Custom/Initiative"
        }
        
        Write-Output ""
        Write-Output "Assignment: $assignmentName" "White"
        Write-Output "Effect: $effect" "Gray"
    }
} catch {
    Write-Output "Could not retrieve policy assignments for effects analysis." "Yellow"
}

# Resource type breakdown
Write-Output ""
Write-Output "📊 Compliance by Resource Type:" "Blue"
Write-Output "===============================" "Blue"

$resourceTypeGroups = $complianceData | Group-Object resourceType
foreach ($typeGroup in $resourceTypeGroups) {
    $resType = $typeGroup.Name
    $typeResources = $typeGroup.Group
    $typeCompliant = ($typeResources | Where-Object { $_.complianceState -eq "Compliant" }).Count
    $typeTotal = $typeResources.Count
    $typeRate = if ($typeTotal -gt 0) { [math]::Round(($typeCompliant / $typeTotal) * 100, 1) } else { 0 }
    
    Write-Output "${resType}: $typeCompliant/$typeTotal ($typeRate%)" "White"
}

Write-Output ""
Write-Output "💡 Understanding Compliance States:" "Yellow"
Write-Output "====================================" "Yellow"
Write-Output "✅ Compliant: Resource follows the policy rule" "Green"
Write-Output "❌ NonCompliant: Resource violates the policy rule" "Red"
Write-Output "⚠️  Conflict: Multiple policies with conflicting requirements" "Yellow"
Write-Output "❓ Unknown: Policy evaluation hasn't completed or failed" "Gray"

Write-Output ""
Write-Output "💡 Next steps:" "Yellow"
Write-Output "- Run ./06-list-initiatives.ps1 to explore policy initiatives" "Gray"
Write-Output "- Run ./07-create-custom-policy.ps1 to create your own policy" "Gray"
Write-Output "- Use ./08-remediation.ps1 to fix non-compliant resources" "Gray"
if (-not $ResourceGroup) {
    Write-Output "- Use -ResourceGroup parameter to focus on specific resource group" "Gray"
}

# Show file output confirmation
if ($outputToFile) {
    Write-Output ""
    Write-Output "✅ Compliance report has been saved to: $outputFilePath" "Green"
    Write-Output "📁 File size: $((Get-Item $outputFilePath).Length) bytes" "Gray"
}
