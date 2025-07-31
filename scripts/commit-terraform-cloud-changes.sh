#!/bin/bash
# Commit Terraform Cloud Configuration Changes

echo "🚀 Committing Terraform Cloud configuration changes..."

# Add all changed files
git add .

# Commit with descriptive message
git commit -m "feat: Configure Terraform Cloud for CI/CD

- Update terraform backend to use Terraform Cloud
- Modify GitHub Actions workflows for Terraform Cloud integration
- Remove local backend and environment variable complexity
- Add TF_API_TOKEN authentication
- Simplify workflow by removing manual environment variable setting

This resolves the GitHub Actions authentication failures by:
1. Using Terraform Cloud for state management
2. Centralized credential management
3. Proper workspace-based environment separation

Fixes: GitHub Actions run #16612091439"

echo "✅ Changes committed successfully!"

echo ""
echo "📋 Next steps to complete the setup:"
echo ""
echo "1. 🌐 Create Terraform Cloud account at app.terraform.io"
echo "2. 🏗️  Create organization: stuartshay-azure-policy"
echo "3. 📁 Create workspaces:"
echo "   - azure-policy-dev"
echo "   - azure-policy-staging"
echo "   - azure-policy-prod"
echo "4. 🔑 Add Azure credentials as environment variables in each workspace"
echo "5. 🎫 Generate API token and add TF_API_TOKEN to GitHub repository secrets"
echo "6. ✅ Test the workflow with manual trigger"
echo ""
echo "📖 See docs/TERRAFORM_CLOUD_SETUP.md for detailed instructions"
