#!/bin/bash
# Validate GitHub Actions workflow configuration

echo "🔍 Validating GitHub Actions workflows..."

# Check for correct secret references
echo "Checking secret references..."

# Check terraform-apply.yml
if grep -q "ARM_CLIENT_ID:" .github/workflows/terraform-apply.yml; then
    echo "✅ ARM_CLIENT_ID found in terraform-apply.yml"
else
    echo "❌ ARM_CLIENT_ID not found in terraform-apply.yml"
    exit 1
fi

if grep -q "secrets.ARM_CLIENT_ID" .github/workflows/terraform-apply.yml; then
    echo "✅ Correct ARM_CLIENT_ID secret reference in terraform-apply.yml"
else
    echo "❌ Incorrect ARM_CLIENT_ID secret reference in terraform-apply.yml"
    exit 1
fi

# Check terraform-destroy.yml
if grep -q "ARM_CLIENT_ID:" .github/workflows/terraform-destroy.yml; then
    echo "✅ ARM_CLIENT_ID found in terraform-destroy.yml"
else
    echo "❌ ARM_CLIENT_ID not found in terraform-destroy.yml"
    exit 1
fi

if grep -q "secrets.ARM_CLIENT_ID" .github/workflows/terraform-destroy.yml; then
    echo "✅ Correct ARM_CLIENT_ID secret reference in terraform-destroy.yml"
else
    echo "❌ Incorrect ARM_CLIENT_ID secret reference in terraform-destroy.yml"
    exit 1
fi

# Check for old AZURE_CREDENTIALS references
if grep -q "AZURE_CREDENTIALS" .github/workflows/terraform-apply.yml; then
    echo "❌ Found old AZURE_CREDENTIALS reference in terraform-apply.yml"
    exit 1
else
    echo "✅ No old AZURE_CREDENTIALS references in terraform-apply.yml"
fi

if grep -q "AZURE_CREDENTIALS" .github/workflows/terraform-destroy.yml; then
    echo "❌ Found old AZURE_CREDENTIALS reference in terraform-destroy.yml"
    exit 1
else
    echo "✅ No old AZURE_CREDENTIALS references in terraform-destroy.yml"
fi

# Check for double output references
if grep -q "steps.outputs.outputs.outputs_available" .github/workflows/terraform-apply.yml; then
    echo "❌ Found double output reference in terraform-apply.yml"
    exit 1
else
    echo "✅ No double output references in terraform-apply.yml"
fi

echo ""
echo "🎉 All workflow validations passed!"
echo ""
echo "Summary of changes made:"
echo "1. Updated secret references from AZURE_* to ARM_* format"
echo "2. Removed azure/login@v2 action in favor of ARM environment variables"
echo "3. Fixed double output references (steps.outputs.outputs.* -> steps.outputs.*)"
echo "4. Ensured consistent authentication method across workflows"
echo ""
echo "Next steps:"
echo "1. Ensure GitHub repository secrets are configured with ARM_* names"
echo "2. Test the workflow with a manual trigger"
echo "3. Verify Azure authentication works properly"
