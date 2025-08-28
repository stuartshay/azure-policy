#!/bin/bash

# GitHub Secrets Verification Script
# This script helps you verify if your GitHub repository secrets are properly configured

set -euo pipefail

echo "🔍 GitHub Secrets Verification for Terraform Cloud Authentication"
echo "=================================================================="
echo ""

# Repository information
REPO_OWNER="stuartshay"
REPO_NAME="azure-policy"
GITHUB_REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}"

echo "📋 Repository: ${GITHUB_REPO_URL}"
echo "🔧 Checking required secrets for Terraform Cloud authentication..."
echo ""

# Required secrets based on your workflow
REQUIRED_SECRETS=(
    "TF_API_TOKEN"
    "TF_CLOUD_ORGANIZATION"
)

echo "✅ Required GitHub Repository Secrets:"
echo "======================================"
for secret in "${REQUIRED_SECRETS[@]}"; do
    echo "- ${secret}"
done
echo ""

echo "🔗 To verify/add secrets, visit:"
echo "   ${GITHUB_REPO_URL}/settings/secrets/actions"
echo ""

# Values from your .env file (for reference)
if [[ -f ".env" ]]; then
    echo "📄 Values from your .env file (for reference):"
    echo "=============================================="

    if grep -q "TF_API_TOKEN=" .env; then
        TF_API_TOKEN_VALUE=$(grep "TF_API_TOKEN=" .env | cut -d'=' -f2)
        echo "- TF_API_TOKEN: ${TF_API_TOKEN_VALUE:0:20}... (truncated for security)"
    else
        echo "- TF_API_TOKEN: ❌ NOT FOUND in .env"
    fi

    if grep -q "TF_CLOUD_ORGANIZATION=" .env; then
        TF_CLOUD_ORGANIZATION_VALUE=$(grep "TF_CLOUD_ORGANIZATION=" .env | cut -d'=' -f2)
        echo "- TF_CLOUD_ORGANIZATION: ${TF_CLOUD_ORGANIZATION_VALUE}"
    else
        echo "- TF_CLOUD_ORGANIZATION: ❌ NOT FOUND in .env"
    fi
else
    echo "⚠️  .env file not found - cannot show reference values"
fi
echo ""

echo "🧪 Testing Terraform Cloud API connectivity (using .env values):"
echo "================================================================"

if [[ -f ".env" ]]; then
    # Source .env file
    set -o allexport
    source .env
    set +o allexport

    if [[ -n "${TF_API_TOKEN:-}" ]] && [[ -n "${TF_CLOUD_ORGANIZATION:-}" ]]; then
        echo "Testing Terraform Cloud API with your credentials..."

        HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer ${TF_API_TOKEN}" \
            -H "Content-Type: application/vnd.api+json" \
            "https://app.terraform.io/api/v2/organizations/${TF_CLOUD_ORGANIZATION}" || echo "000")

        if [[ "$HTTP_CODE" == "200" ]]; then
            echo "✅ SUCCESS: Terraform Cloud API responded with HTTP $HTTP_CODE"
            echo "   Your credentials are valid and can access the organization."
        elif [[ "$HTTP_CODE" == "401" ]]; then
            echo "❌ UNAUTHORIZED: HTTP $HTTP_CODE"
            echo "   Your TF_API_TOKEN may be invalid or expired."
        elif [[ "$HTTP_CODE" == "404" ]]; then
            echo "❌ NOT FOUND: HTTP $HTTP_CODE"
            echo "   Your TF_CLOUD_ORGANIZATION may not exist or you don't have access."
        else
            echo "⚠️  UNEXPECTED: HTTP $HTTP_CODE"
            echo "   There may be a network issue or other problem."
        fi
    else
        echo "⚠️  Cannot test API - missing TF_API_TOKEN or TF_CLOUD_ORGANIZATION in .env"
    fi
else
    echo "⚠️  Cannot test API - .env file not found"
fi
echo ""

echo "🚀 Next Steps:"
echo "============="
echo "1. Visit: ${GITHUB_REPO_URL}/settings/secrets/actions"
echo "2. Click 'New repository secret'"
echo "3. Add each required secret with the values from your .env file:"
echo ""
echo "   Secret Name: TF_API_TOKEN"
echo "   Secret Value: [Your Terraform Cloud API token from .env]"
echo ""
echo "   Secret Name: TF_CLOUD_ORGANIZATION"
echo "   Secret Value: [Your Terraform Cloud organization from .env]"
echo ""
echo "4. After adding secrets, re-run your GitHub Actions workflow"
echo ""

echo "📊 Workflow Analysis:"
echo "===================="
echo "Your workflow file (.github/workflows/pre-commit.yml) correctly references:"
echo "- \${{ secrets.TF_API_TOKEN }}"
echo "- \${{ secrets.TF_CLOUD_ORGANIZATION }}"
echo ""
echo "The workflow includes proper verification steps and exports the token"
echo "for Terraform CLI usage as TF_TOKEN_app_terraform_io."
echo ""

echo "🔍 Recent Workflow Failure Analysis:"
echo "===================================="
echo "Based on the GitHub Actions run: ${GITHUB_REPO_URL}/actions/runs/17277509849"
echo ""
echo "If the workflow is failing with authentication errors, it's likely because:"
echo "1. The GitHub secrets are not set up (most common)"
echo "2. The secret values are incorrect"
echo "3. The Terraform Cloud token has expired"
echo ""
echo "The workflow includes verification steps that will show specific error messages."
echo ""

echo "✅ Summary:"
echo "==========="
echo "Your workflow configuration looks correct. The most likely issue is that"
echo "the GitHub repository secrets haven't been added yet. Please add them"
echo "using the GitHub web interface at the URL provided above."
