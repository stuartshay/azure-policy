#!/bin/bash

# Script: Create Custom Policy
# Description: Creates a custom Azure Policy definition with examples
# Usage: ./07-create-custom-policy.sh

echo "=== Azure Policy Learning Script ==="
echo "Script: Create Custom Policy"
echo "Date: $(date)"
echo ""

# Create policies directory if it doesn't exist
POLICIES_DIR="../policies"
mkdir -p "$POLICIES_DIR"

echo "🔧 Creating Custom Azure Policy"
echo "==============================="
echo ""

echo "📝 Policy Template Examples:"
echo "1) Require specific tags on resource groups"
echo "2) Enforce naming convention for storage accounts"
echo "3) Audit resources without backup enabled"
echo "4) Deny creation of expensive VM sizes"
echo "5) Enforce HTTPS-only for Azure Function Apps"
echo "6) Custom policy (manual definition)"
echo ""
read -p "Choose a template (1-6): " TEMPLATE_CHOICE

case $TEMPLATE_CHOICE in
    1)
        POLICY_NAME="require-rg-environment-tag"
        DISPLAY_NAME="Require Environment tag on Resource Groups"
        DESCRIPTION="This policy requires that resource groups have an Environment tag with allowed values"
        
        cat > "$POLICIES_DIR/${POLICY_NAME}.json" << 'EOF'
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Resources/resourceGroups"
        },
        {
          "anyOf": [
            {
              "field": "tags['Environment']",
              "exists": false
            },
            {
              "field": "tags['Environment']",
              "notIn": "[parameters('allowedEnvironments')]"
            }
          ]
        }
      ]
    },
    "then": {
      "effect": "[parameters('effect')]"
    }
  },
  "parameters": {
    "allowedEnvironments": {
      "type": "Array",
      "metadata": {
        "displayName": "Allowed Environment Values",
        "description": "List of allowed values for the Environment tag"
      },
      "defaultValue": ["Development", "Staging", "Production"],
      "allowedValues": ["Development", "Staging", "Production", "Testing", "Demo"]
    },
    "effect": {
      "type": "String",
      "metadata": {
        "displayName": "Effect",
        "description": "The effect determines what happens when the policy rule is evaluated to match"
      },
      "defaultValue": "Audit",
      "allowedValues": ["Audit", "Deny", "Disabled"]
    }
  }
}
EOF
        ;;
    2)
        POLICY_NAME="enforce-storage-naming-convention"
        DISPLAY_NAME="Enforce Storage Account Naming Convention"
        DESCRIPTION="Storage accounts must follow naming convention: [env][purpose]st[random]"
        
        cat > "$POLICIES_DIR/${POLICY_NAME}.json" << 'EOF'
{
  "mode": "Indexed",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Storage/storageAccounts"
        },
        {
          "not": {
            "field": "name",
            "match": "[parameters('namePattern')]"
          }
        }
      ]
    },
    "then": {
      "effect": "[parameters('effect')]"
    }
  },
  "parameters": {
    "namePattern": {
      "type": "String",
      "metadata": {
        "displayName": "Name Pattern",
        "description": "Pattern that storage account names must match"
      },
      "defaultValue": "???*st*"
    },
    "effect": {
      "type": "String",
      "metadata": {
        "displayName": "Effect",
        "description": "The effect determines what happens when the policy rule is evaluated to match"
      },
      "defaultValue": "Deny",
      "allowedValues": ["Audit", "Deny", "Disabled"]
    }
  }
}
EOF
        ;;
    3)
        POLICY_NAME="audit-vm-backup-enabled"
        DISPLAY_NAME="Audit VMs without backup enabled"
        DESCRIPTION="Audits virtual machines that don't have backup protection enabled"
        
        cat > "$POLICIES_DIR/${POLICY_NAME}.json" << 'EOF'
{
  "mode": "Indexed",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Compute/virtualMachines"
        },
        {
          "field": "Microsoft.Compute/virtualMachines/storageProfile.osDisk.osType",
          "exists": true
        }
      ]
    },
    "then": {
      "effect": "AuditIfNotExists",
      "details": {
        "type": "Microsoft.RecoveryServices/backupprotecteditems",
        "existenceCondition": {
          "allOf": [
            {
              "field": "name",
              "like": "*"
            }
          ]
        }
      }
    }
  }
}
EOF
        ;;
    4)
        POLICY_NAME="deny-expensive-vm-sizes"
        DISPLAY_NAME="Deny expensive VM sizes"
        DESCRIPTION="Prevents creation of VMs with expensive size SKUs"
        
        cat > "$POLICIES_DIR/${POLICY_NAME}.json" << 'EOF'
{
  "mode": "Indexed",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Compute/virtualMachines"
        },
        {
          "field": "Microsoft.Compute/virtualMachines/sku.name",
          "in": "[parameters('restrictedSizes')]"
        }
      ]
    },
    "then": {
      "effect": "[parameters('effect')]"
    }
  },
  "parameters": {
    "restrictedSizes": {
      "type": "Array",
      "metadata": {
        "displayName": "Restricted VM Sizes",
        "description": "List of VM sizes that are not allowed"
      },
      "defaultValue": [
        "Standard_E64s_v3",
        "Standard_E64_v3",
        "Standard_F72s_v2",
        "Standard_G5",
        "Standard_GS5",
        "Standard_M128s",
        "Standard_M128ms"
      ]
    },
    "effect": {
      "type": "String",
      "metadata": {
        "displayName": "Effect",
        "description": "The effect determines what happens when the policy rule is evaluated to match"
      },
      "defaultValue": "Deny",
      "allowedValues": ["Audit", "Deny", "Disabled"]
    }
  }
}
EOF
        ;;
    5)
        POLICY_NAME="enforce-function-app-https-only"
        DISPLAY_NAME="Function Apps should only be accessible over HTTPS"
        DESCRIPTION="This policy ensures that Azure Function Apps are only accessible over HTTPS, not HTTP"
        
        cat > "$POLICIES_DIR/${POLICY_NAME}.json" << 'EOF'
{
  "mode": "Indexed",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Web/sites"
        },
        {
          "field": "kind",
          "like": "functionapp*"
        },
        {
          "anyOf": [
            {
              "field": "Microsoft.Web/sites/httpsOnly",
              "exists": false
            },
            {
              "field": "Microsoft.Web/sites/httpsOnly",
              "equals": false
            }
          ]
        }
      ]
    },
    "then": {
      "effect": "Deny"
    }
  },
  "parameters": {}
}
EOF
        ;;
    6)
        echo ""
        read -p "Enter policy name (lowercase, no spaces): " POLICY_NAME
        read -p "Enter display name: " DISPLAY_NAME
        read -p "Enter description: " DESCRIPTION
        
        cat > "$POLICIES_DIR/${POLICY_NAME}.json" << 'EOF'
{
  "mode": "All",
  "policyRule": {
    "if": {
      "field": "type",
      "equals": "Microsoft.Resources/resourceGroups"
    },
    "then": {
      "effect": "Audit"
    }
  },
  "parameters": {}
}
EOF
        echo ""
        echo "📝 Basic policy template created. Edit $POLICIES_DIR/${POLICY_NAME}.json to customize."
        ;;
    *)
        echo "❌ Invalid choice!"
        exit 1
        ;;
esac

echo ""
echo "📁 Policy file created: $POLICIES_DIR/${POLICY_NAME}.json"

# Create the policy definition in Azure
echo ""
echo "🚀 Creating policy definition in Azure..."
if az policy definition create \
    --name "$POLICY_NAME" \
    --display-name "$DISPLAY_NAME" \
    --description "$DESCRIPTION" \
    --rules "$POLICIES_DIR/${POLICY_NAME}.json" \
    --mode All \
    --output table; then
    
    echo ""
    echo "✅ Custom policy created successfully!"
    echo ""
    echo "📋 Policy Details:"
    echo "Name: $POLICY_NAME"
    echo "Display Name: $DISPLAY_NAME"
    echo "Description: $DESCRIPTION"
    echo "File: $POLICIES_DIR/${POLICY_NAME}.json"
    
    echo ""
    echo "💡 Next steps:"
    echo "1. Review the policy file: cat $POLICIES_DIR/${POLICY_NAME}.json"
    echo "2. Test the policy: ./04-create-assignment.sh"
    echo "3. View policy details: ./02-show-policy-details.sh '$DISPLAY_NAME'"
    echo "4. Create more policies or modify existing ones"
    
else
    echo ""
    echo "❌ Failed to create policy definition!"
    echo "💡 Check the policy syntax and your permissions"
fi

echo ""
echo "📚 Policy Development Resources:"
echo "==============================="
echo "• Azure Policy definition structure: https://docs.microsoft.com/azure/governance/policy/concepts/definition-structure"
echo "• Policy effects: https://docs.microsoft.com/azure/governance/policy/concepts/effects"
echo "• Policy functions: https://docs.microsoft.com/azure/governance/policy/reference/policy-functions"
echo "• Field reference: https://docs.microsoft.com/azure/governance/policy/reference/aliases"
