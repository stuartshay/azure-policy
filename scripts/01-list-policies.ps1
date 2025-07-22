#!/usr/bin/env pwsh

<#
.SYNOPSIS
    List Azure Policies

.DESCRIPTION
    Lists built-in and custom Azure Policy definitions with focus on AzurePolicy resource group

.PARAMETER ResourceGroup
    The resource group to focus on for policy assignments and compliance (defaults to "AzurePolicy")

.EXAMPLE
    ./01-list-policies.ps1
    
.EXAMPLE
    ./01-list-policies.ps1 -ResourceGroup "MyResourceGroup"
#>

param(
    [string]$ResourceGroup = "AzurePolicy"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "=== Azure Policy Script ===" -ForegroundColor Cyan
Write-Host "Script: List Azure Policies" -ForegroundColor Cyan
Write-Host "Target Resource Group: $ResourceGroup" -ForegroundColor Yellow
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Verify resource group exists
try {
    $null = az group show --name $ResourceGroup 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Resource group not found"
    }
} catch {
    Write-Host "❌ Error: Resource group '$ResourceGroup' not found or not accessible" -ForegroundColor Red
    Write-Host "Available resource groups:" -ForegroundColor Yellow
    az group list --query "[].name" --output table
    exit 1
}

Write-Host "✅ Using resource group: $ResourceGroup" -ForegroundColor Green
Write-Host ""

# Policy Assignments for Resource Group
Write-Host "🎯 Policy Assignments for Resource Group: $ResourceGroup" -ForegroundColor Magenta
Write-Host "========================================================" -ForegroundColor Magenta

$assignmentsJson = az policy assignment list --resource-group $ResourceGroup --output json | ConvertFrom-Json

if ($assignmentsJson.Count -eq 0) {
    Write-Host "No policy assignments found for resource group '$ResourceGroup'." -ForegroundColor Yellow
} else {
    foreach ($assignment in $assignmentsJson) {
        $assignmentName = if ($assignment.displayName) { $assignment.displayName } else { $assignment.name }
        $policyName = ($assignment.policyDefinitionId -split "/")[-1]
        $enforcement = if ($assignment.enforcementMode) { $assignment.enforcementMode } else { "Default" }
        
        Write-Host "Assignment: $assignmentName" -ForegroundColor White
        Write-Host "Policy: $policyName" -ForegroundColor Gray
        Write-Host "Scope: $($assignment.scope)" -ForegroundColor Gray
        Write-Host "Enforcement: $enforcement" -ForegroundColor Gray
        Write-Host "---" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "📋 Listing Built-in Policy Definitions..." -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue

# Get first 10 built-in policies
$builtinPolicies = az policy definition list --query "[?policyType=='BuiltIn'] | [0:10].{Name:displayName, Category:metadata.category, Mode:mode}" --output json | ConvertFrom-Json

if ($builtinPolicies.Count -gt 0) {
    $builtinPolicies | Format-Table -Property Name, Category, Mode -AutoSize
} else {
    Write-Host "No built-in policies found." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Listing Custom Policy Definitions..." -ForegroundColor Blue
Write-Host "=======================================" -ForegroundColor Blue

$customPoliciesJson = az policy definition list --query "[?policyType=='Custom']" --output json | ConvertFrom-Json

if ($customPoliciesJson.Count -eq 0) {
    Write-Host "No custom policies found." -ForegroundColor Yellow
} else {
    foreach ($policy in $customPoliciesJson) {
        $category = if ($policy.metadata.category) { $policy.metadata.category } else { "N/A" }
        
        Write-Host "Name: $($policy.displayName)" -ForegroundColor White
        Write-Host "Category: $category" -ForegroundColor Gray
        Write-Host "Mode: $($policy.mode)" -ForegroundColor Gray
        Write-Host "---" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "📊 Policy Summary:" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green

# Get policy counts
$builtinCount = (az policy definition list --query "[?policyType=='BuiltIn'] | length(@)" --output tsv)
$customCount = (az policy definition list --query "[?policyType=='Custom'] | length(@)" --output tsv)
$assignmentCount = (az policy assignment list --resource-group $ResourceGroup --query "length(@)" --output tsv)

Write-Host "Built-in policies: $builtinCount" -ForegroundColor White
Write-Host "Custom policies: $customCount" -ForegroundColor White
Write-Host "Total policies: $([int]$builtinCount + [int]$customCount)" -ForegroundColor White
Write-Host "Assignments in '$ResourceGroup': $assignmentCount" -ForegroundColor White

# Show compliance state for the resource group
Write-Host ""
Write-Host "🏥 Compliance Status for Resource Group: $ResourceGroup" -ForegroundColor Red
Write-Host "=======================================================" -ForegroundColor Red

try {
    $complianceJson = az policy state list --resource-group $ResourceGroup --query "[].{Policy:policyDefinitionName,Resource:resourceId,State:complianceState}" --output json 2>$null | ConvertFrom-Json
    
    if ($LASTEXITCODE -eq 0 -and $complianceJson.Count -gt 0) {
        # Show first 20 compliance entries
        $displayCount = [Math]::Min(20, $complianceJson.Count)
        for ($i = 0; $i -lt $displayCount; $i++) {
            $compliance = $complianceJson[$i]
            $resourceName = ($compliance.Resource -split "/")[-1]
            
            Write-Host "Policy: $($compliance.Policy)" -ForegroundColor White
            Write-Host "Resource: $resourceName" -ForegroundColor Gray
            Write-Host "State: $($compliance.State)" -ForegroundColor $(if ($compliance.State -eq "Compliant") { "Green" } else { "Red" })
            Write-Host "---" -ForegroundColor DarkGray
        }
        
        # Summary of compliance states
        $compliant = ($complianceJson | Where-Object { $_.State -eq "Compliant" }).Count
        $nonCompliant = ($complianceJson | Where-Object { $_.State -eq "NonCompliant" }).Count
        
        Write-Host ""
        Write-Host "Compliance Summary:" -ForegroundColor Yellow
        Write-Host "- Compliant: $compliant" -ForegroundColor Green
        Write-Host "- Non-compliant: $nonCompliant" -ForegroundColor Red
    } else {
        Write-Host "No compliance data available or insufficient permissions." -ForegroundColor Yellow
    }
} catch {
    Write-Host "No compliance data available or insufficient permissions." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "💡 Next steps:" -ForegroundColor Cyan
Write-Host "- Run ./02-show-policy-details.ps1 to examine specific policies" -ForegroundColor Gray
Write-Host "- Run ./03-list-assignments.ps1 to see detailed policy assignments" -ForegroundColor Gray
Write-Host "- Use './01-list-policies.ps1 -ResourceGroup <name>' to check other resource groups" -ForegroundColor Gray
Write-Host "- Check compliance: az policy state list --resource-group $ResourceGroup" -ForegroundColor Gray
