#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Deploy Function App HTTPS-Only Policy

.DESCRIPTION
    Creates and deploys the Azure Policy that enforces HTTPS-only for Azure Function Apps

.PARAMETER ResourceGroup
    Optional resource group to assign the policy to. If not specified, assigns to the current subscription.

.PARAMETER Effect
    The policy effect to use. Valid values: Audit, Deny, Disabled. Default: Deny

.EXAMPLE
    ./deploy-function-https-policy.ps1
    
.EXAMPLE
    ./deploy-function-https-policy.ps1 -ResourceGroup "AzurePolicy" -Effect "Audit"
#>

param(
    [string]$ResourceGroup,
    [ValidateSet("Audit", "Deny", "Disabled")]
    [string]$Effect = "Deny"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "=== Azure Function HTTPS-Only Policy Deployment ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# Policy details
$policyName = "enforce-function-app-https-only"
$displayName = "Function Apps should only be accessible over HTTPS"
$description = "This policy ensures that Azure Function Apps are only accessible over HTTPS, not HTTP. This policy always uses the Deny effect to block non-compliant resources."
$policyFilePath = "../policies/enforce-function-app-https-only.json"

# Check if policy file exists
if (-not (Test-Path $policyFilePath)) {
    Write-Host "❌ Policy file not found: $policyFilePath" -ForegroundColor Red
    exit 1
}

Write-Host "🔍 Policy Details:" -ForegroundColor Blue
Write-Host "Name: $policyName" -ForegroundColor White
Write-Host "Display Name: $displayName" -ForegroundColor White
Write-Host "Effect: Deny (Hardcoded)" -ForegroundColor Red
Write-Host "File: $policyFilePath" -ForegroundColor Gray
Write-Host ""

# Create the policy definition
Write-Host "🚀 Creating policy definition..." -ForegroundColor Blue

try {
    $policyDefinition = az policy definition create `
        --name $policyName `
        --display-name $displayName `
        --description $description `
        --rules $policyFilePath `
        --mode "Indexed" `
        --output json | ConvertFrom-Json
    
    Write-Host "✅ Policy definition created successfully!" -ForegroundColor Green
    Write-Host "Policy ID: $($policyDefinition.id)" -ForegroundColor Gray
} catch {
    # Check if policy already exists
    $existingPolicy = az policy definition show --name $policyName 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "ℹ️  Policy definition already exists, updating..." -ForegroundColor Yellow
        
        $policyDefinition = az policy definition update `
            --name $policyName `
            --display-name $displayName `
            --description $description `
            --rules $policyFilePath `
            --output json | ConvertFrom-Json
        
        Write-Host "✅ Policy definition updated successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to create policy definition: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Create policy assignment
Write-Host ""
Write-Host "📋 Creating policy assignment..." -ForegroundColor Blue

$assignmentName = "assign-function-https-only"
$assignmentDisplayName = "Assign Function App HTTPS-Only Policy"

# Determine scope
$scope = if ($ResourceGroup) {
    $rgInfo = az group show --name $ResourceGroup --query id --output tsv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Resource group '$ResourceGroup' not found!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Scope: Resource Group '$ResourceGroup'" -ForegroundColor Yellow
    $rgInfo
} else {
    $subscriptionId = az account show --query id --output tsv
    Write-Host "Scope: Current Subscription" -ForegroundColor Yellow
    "/subscriptions/$subscriptionId"
}

try {
    # Since the policy has no parameters, create assignment without parameters
    $assignment = az policy assignment create `
        --name $assignmentName `
        --display-name $assignmentDisplayName `
        --policy $policyDefinition.name `
        --scope $scope `
        --output json | ConvertFrom-Json
    
    Write-Host "✅ Policy assignment created successfully!" -ForegroundColor Green
    Write-Host "Assignment ID: $($assignment.id)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Failed to create policy assignment: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "💡 You may need to check permissions or if assignment already exists" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📊 Policy Summary:" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host "✅ Policy Name: $policyName" -ForegroundColor White
Write-Host "✅ Effect: Deny (Hardcoded)" -ForegroundColor Red
Write-Host "✅ Scope: $(if ($ResourceGroup) { "Resource Group '$ResourceGroup'" } else { "Subscription" })" -ForegroundColor White
Write-Host ""

Write-Host "🔒 What this policy does:" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host "• Targets: Azure Function Apps (Microsoft.Web/sites with kind 'functionapp*')" -ForegroundColor White
Write-Host "• Requirement: HTTPS-only must be enabled (httpsOnly = true)" -ForegroundColor White
Write-Host "• Effect: Deny - Blocks creation/update of non-HTTPS Function Apps" -ForegroundColor Red

Write-Host ""
Write-Host "🧪 Testing the Policy:" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow
Write-Host "1. Try creating a Function App without HTTPS-only:" -ForegroundColor Gray
Write-Host "   az functionapp create --name myapp --resource-group $($ResourceGroup ?? 'mygroup') --storage-account mystorage --consumption-plan-location eastus" -ForegroundColor DarkGray
Write-Host ""
Write-Host "2. Create a compliant Function App:" -ForegroundColor Gray
Write-Host "   az functionapp create --name myapp --resource-group $($ResourceGroup ?? 'mygroup') --storage-account mystorage --consumption-plan-location eastus" -ForegroundColor DarkGray
Write-Host "   az functionapp update --name myapp --resource-group $($ResourceGroup ?? 'mygroup') --set httpsOnly=true" -ForegroundColor DarkGray

Write-Host ""
Write-Host "💡 Next steps:" -ForegroundColor Yellow
Write-Host "- Check compliance: ./05-compliance-report.ps1$(if ($ResourceGroup) { " -ResourceGroup '$ResourceGroup'" })" -ForegroundColor Gray
Write-Host "- View policy details: ./02-show-policy-details.ps1 '$displayName'" -ForegroundColor Gray
Write-Host "- Test with Function App creation to verify enforcement" -ForegroundColor Gray
Write-Host "- Monitor compliance in Azure portal" -ForegroundColor Gray

Write-Host ""
Write-Host "📚 Security Benefits:" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host "✅ Encrypts data in transit" -ForegroundColor White
Write-Host "✅ Prevents man-in-the-middle attacks" -ForegroundColor White
Write-Host "✅ Ensures secure API communication" -ForegroundColor White
Write-Host "✅ Meets compliance requirements" -ForegroundColor White
Write-Host "✅ Protects sensitive function data" -ForegroundColor White
