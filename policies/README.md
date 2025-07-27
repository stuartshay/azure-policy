# Custom Azure Policy Definitions

This directory contains custom Azure Policy definitions for organizational governance.

## Policies

### 1. Storage Account Naming Convention (`storage-naming-convention.json`)

**Purpose**: Enforces naming standards for storage accounts

**Rule**: Storage accounts must follow the pattern `st*[a-z0-9]*`

- Must start with "st"
- Followed by any characters
- Must be lowercase alphanumeric

**Examples**:

- ✅ Compliant: `stdevapp001`, `stproddata123`
- ❌ Non-compliant: `mystorageaccount`, `StorageAccount1`

**Parameters**:

- `namePattern`: Customizable naming pattern (default: `st*[a-z0-9]*`)
- `effect`: Audit, Deny, or Disabled (default: Audit)

### 2. Resource Group Naming Convention (`resource-group-naming.json`)

**Purpose**: Enforces naming standards for resource groups

**Rule**: Resource groups must follow one of these patterns:

- `rg-*-*` (standard format: rg-purpose-environment)
- `dev-*` (development resources)
- `prod-*` (production resources)
- `test-*` (testing resources)

**Examples**:

- ✅ Compliant: `rg-webapp-dev`, `dev-testing`, `prod-database`
- ❌ Non-compliant: `MyResourceGroup`, `AzurePolicy`

**Parameters**:

- `effect`: Audit, Deny, or Disabled (default: Audit)

## Usage

1. **Create Policy Definition**:

   ```bash
   az policy definition create \
     --name "custom-storage-naming" \
     --display-name "Custom Storage Account Naming Convention" \
     --description "Enforces storage account naming standards" \
     --rules storage-naming-convention.json \
     --mode Indexed
   ```

2. **Create Policy Assignment**:

   ```bash
   az policy assignment create \
     --name "storage-naming-assignment" \
     --policy "custom-storage-naming" \
     --scope "/subscriptions/{subscription-id}/resourceGroups/{resource-group}" \
     --enforcement-mode "DoNotEnforce"
   ```

## Best Practices

- Start with `Audit` effect to understand impact
- Test in development environments first
- Use `DoNotEnforce` mode initially for learning
- Switch to `Deny` effect only after validation
- Document naming conventions clearly
- Train teams on policy requirements

## Customization

You can modify these policies by:

- Changing the `namePattern` parameter
- Adding new allowed naming patterns
- Adjusting the policy effects
- Adding additional validation rules
