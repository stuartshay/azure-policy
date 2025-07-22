#!/usr/bin/env pwsh

<#
.SYNOPSIS
    List Policy Assignments

.DESCRIPTION
    Lists all Azure Policy assignments in the current subscription

.PARAMETER OutputDirectory
    Optional directory to save the assignment details to a file. Directory will be created if it doesn't exist.

.EXAMPLE
    ./03-list-assignments.ps1
    
.EXAMPLE
    ./03-list-assignments.ps1 -OutputDirectory "./reports"
    
.EXAMPLE
    ./03-list-assignments.ps1 -OutputDirectory "/tmp/policy-reports"
#>

param(
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
    $outputFilePath = Join-Path $OutputDirectory "policy-assignments_$timestamp.txt"
    
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
Write-Output "Script: List Policy Assignments" "Cyan"
Write-Output "Date: $(Get-Date)" "Gray"
Write-Output ""

Write-Output "🎯 Current Subscription:" "Blue"
Write-Output "========================" "Blue"

try {
    $subscriptionInfo = az account show --query "{Name:name, ID:id, Tenant:tenantId}" --output json | ConvertFrom-Json
    Write-Output "Name: $($subscriptionInfo.Name)" "White"
    Write-Output "ID: $($subscriptionInfo.ID)" "Gray"
    Write-Output "Tenant: $($subscriptionInfo.Tenant)" "Gray"
} catch {
    Write-Output "❌ Error getting subscription information: $($_.Exception.Message)" "Red"
    exit 1
}

Write-Output ""
Write-Output "📋 Policy Assignments:" "Magenta"
Write-Output "======================" "Magenta"

try {
    $assignmentsJson = az policy assignment list --output json | ConvertFrom-Json
    
    if ($assignmentsJson.Count -eq 0) {
        Write-Output "No policy assignments found in the current subscription." "Yellow"
        Write-Output ""
        Write-Output "💡 This could mean:" "Yellow"
        Write-Output "   • No policies have been assigned yet" "Gray"
        Write-Output "   • You might need to check at different scopes (management group, resource group)" "Gray"
        Write-Output "   • You might not have sufficient permissions to view assignments" "Gray"
    } else {
        foreach ($assignment in $assignmentsJson) {
            $assignmentName = if ($assignment.displayName) { $assignment.displayName } else { $assignment.name }
            $policyName = ($assignment.policyDefinitionId -split "/")[-1]
            $enforcement = if ($assignment.enforcementMode) { $assignment.enforcementMode } else { "Default" }
            $created = if ($assignment.metadata.createdOn) { $assignment.metadata.createdOn } else { "N/A" }
            
            Write-Output ""
            Write-Output "Name: $assignmentName" "White"
            Write-Output "Policy: $policyName" "Gray"
            Write-Output "Scope: $($assignment.scope)" "Gray"
            Write-Output "Enforcement: $enforcement" "Gray"
            Write-Output "Created: $created" "Gray"
            Write-Output "---" "DarkGray"
        }
    }
} catch {
    Write-Output "❌ Error retrieving policy assignments: $($_.Exception.Message)" "Red"
    exit 1
}

Write-Output ""
Write-Output "📊 Assignment Summary:" "Green"
Write-Output "=====================" "Green"

$assignmentCount = $assignmentsJson.Count
Write-Output "Total assignments: $assignmentCount" "White"

if ($assignmentCount -gt 0) {
    Write-Output ""
    Write-Output "🔍 Assignments by Enforcement Mode:" "Blue"
    
    # Group by enforcement mode
    $enforcementGroups = $assignmentsJson | Group-Object { 
        if ($_.enforcementMode) { $_.enforcementMode } else { "Default" }
    }
    
    foreach ($group in $enforcementGroups) {
        Write-Output "$($group.Name): $($group.Count)" "White"
    }
    
    # Additional statistics
    Write-Output ""
    Write-Output "📈 Additional Statistics:" "Cyan"
    
    # Count by scope type
    $scopeStats = @{}
    foreach ($assignment in $assignmentsJson) {
        $scopeParts = $assignment.scope -split "/"
        if ($scopeParts.Count -ge 3) {
            $scopeType = switch ($scopeParts[3]) {
                "subscriptions" { "Subscription" }
                "resourceGroups" { "Resource Group" }
                "managementGroups" { "Management Group" }
                default { "Other" }
            }
            if ($scopeStats.ContainsKey($scopeType)) {
                $scopeStats[$scopeType]++
            } else {
                $scopeStats[$scopeType] = 1
            }
        }
    }
    
    Write-Output "Assignments by Scope:" "Gray"
    foreach ($scope in $scopeStats.GetEnumerator()) {
        Write-Output "- $($scope.Key): $($scope.Value)" "Gray"
    }
}

Write-Output ""
Write-Output "💡 Next steps:" "Yellow"
Write-Output "- Run ./04-create-assignment.ps1 to create a new policy assignment" "Gray"
Write-Output "- Run ./05-compliance-report.ps1 to check compliance status" "Gray"
Write-Output "- Run ./06-list-initiatives.ps1 to see policy initiatives" "Gray"

# Show file output confirmation
if ($outputToFile) {
    Write-Output ""
    Write-Output "✅ Policy assignments have been saved to: $outputFilePath" "Green"
    Write-Output "📁 File size: $((Get-Item $outputFilePath).Length) bytes" "Gray"
}
