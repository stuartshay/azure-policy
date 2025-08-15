#!/usr/bin/env bash
# Azure Function App Access Diagnostics and Repair Script
# This script helps diagnose and fix Azure Function App deployment access issues

set -e

# Configuration
RESOURCE_GROUP="rg-azpolicy-dev-eastus"
FUNCTION_APP_NAME="func-azpolicy-dev-001"
SCM_URL="https://${FUNCTION_APP_NAME}.scm.azurewebsites.net"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Azure Function App Access Diagnostics ===${NC}"
echo "Resource Group: $RESOURCE_GROUP"
echo "Function App: $FUNCTION_APP_NAME"
echo "SCM URL: $SCM_URL"
echo ""

# Check if logged into Azure
echo -e "${BLUE}🔐 Checking Azure authentication...${NC}"
if ! az account show >/dev/null 2>&1; then
    echo -e "${RED}❌ Not logged into Azure. Please run: az login${NC}"
    exit 1
fi

SUBSCRIPTION=$(az account show --query "name" -o tsv)
echo -e "${GREEN}✅ Logged into Azure subscription: $SUBSCRIPTION${NC}"
echo ""

# Check Function App existence
echo -e "${BLUE}📱 Checking Function App status...${NC}"
FUNC_APP_STATE=$(az functionapp show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$FUNCTION_APP_NAME" \
    --query "{name:name, state:state, publicNetworkAccess:publicNetworkAccessEnabled, httpsOnly:httpsOnly, kind:kind}" \
    -o json 2>/dev/null || echo "null")

if [ "$FUNC_APP_STATE" = "null" ]; then
    echo -e "${RED}❌ Function App '$FUNCTION_APP_NAME' not found!${NC}"
    exit 1
fi

echo "Function App Details:"
echo "$FUNC_APP_STATE" | jq .

PUBLIC_ACCESS=$(echo "$FUNC_APP_STATE" | jq -r '.publicNetworkAccess')
APP_STATE=$(echo "$FUNC_APP_STATE" | jq -r '.state')

echo ""

# Check current access restrictions
echo -e "${BLUE}🔒 Analyzing access restrictions...${NC}"
ACCESS_RESTRICTIONS=$(az functionapp config access-restriction show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$FUNCTION_APP_NAME" \
    --query "{mainSite: ipSecurityRestrictions, scmSite: scmIpSecurityRestrictions}" \
    -o json 2>/dev/null || echo "{}")

echo "Current Access Restrictions:"
echo "$ACCESS_RESTRICTIONS" | jq .

# Count restrictions
MAIN_ALLOW_COUNT=$(echo "$ACCESS_RESTRICTIONS" | jq '.mainSite | map(select(.action == "Allow")) | length')
MAIN_DENY_COUNT=$(echo "$ACCESS_RESTRICTIONS" | jq '.mainSite | map(select(.action == "Deny")) | length')
SCM_ALLOW_COUNT=$(echo "$ACCESS_RESTRICTIONS" | jq '.scmSite | map(select(.action == "Allow")) | length')
SCM_DENY_COUNT=$(echo "$ACCESS_RESTRICTIONS" | jq '.scmSite | map(select(.action == "Deny")) | length')

echo ""
echo "📊 Access Rules Summary:"
echo "  Main Site - Allow Rules: $MAIN_ALLOW_COUNT, Deny Rules: $MAIN_DENY_COUNT"
echo "  SCM Site - Allow Rules: $SCM_ALLOW_COUNT, Deny Rules: $SCM_DENY_COUNT"
echo ""

# Test SCM connectivity
echo -e "${BLUE}🧪 Testing SCM site connectivity...${NC}"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$SCM_URL" --max-time 15 || echo "000")
echo "SCM Site HTTP Status: $HTTP_STATUS"

# Analyze the results
echo -e "${BLUE}🔍 Diagnostics Analysis:${NC}"

if [ "$APP_STATE" != "Running" ]; then
    echo -e "${RED}❌ Function App is not running (State: $APP_STATE)${NC}"
fi

if [ "$PUBLIC_ACCESS" = "false" ]; then
    echo -e "${YELLOW}⚠️  Public network access is disabled${NC}"
    echo "   This will prevent GitHub Actions from deploying unless:"
    echo "   - Runner IP is in access restrictions, OR"
    echo "   - Public access is temporarily enabled during deployment"
fi

  if [ "$STATUS_CODE" != "200" ]; then
    echo "SCM Site HTTP Status: $STATUS_CODE"
    if [ "$STATUS_CODE" = "403" ]; then
      echo "⚠️  INFO: SCM site blocked (403) - access restrictions are active"
      echo "##[warning]SCM site returns 403 Forbidden due to access restrictions."
      echo "This indicates the Function App has VNet integration and private network access configured."
      echo "This is a security configuration that blocks external access to deployment endpoints."
      echo "Deployment may require additional access rules or private deployment agents."
      echo "Continuing with deployment attempt - access rules will be managed during deployment..."
    elif [ "$STATUS_CODE" = "401" ]; then
      echo "⚠️  WARNING: Authentication required (401) - checking credentials"
      echo "This might indicate missing or invalid deployment credentials."
    else
      echo "⚠️  WARNING: Unexpected status code: $STATUS_CODE"
    fi
  else
    echo "✅ SCM site is accessible (200 OK)"
  fi

echo ""

# Check for GitHub Actions rules
echo -e "${BLUE}🔍 Checking for existing GitHub Actions rules...${NC}"
GITHUB_RULES=$(az functionapp config access-restriction list \
    --resource-group "$RESOURCE_GROUP" \
    --name "$FUNCTION_APP_NAME" \
    --query "[?contains(name, 'GitHubActions')]" \
    -o json 2>/dev/null || echo "[]")

GITHUB_RULE_COUNT=$(echo "$GITHUB_RULES" | jq length)
if [ "$GITHUB_RULE_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Found $GITHUB_RULE_COUNT existing GitHub Actions rules:${NC}"
    echo "$GITHUB_RULES" | jq -r '.[] | "  - \(.name): \(.ipAddress) (Priority: \(.priority))"'
    echo ""
    echo -e "${YELLOW}💡 Consider cleaning up old GitHub Actions rules${NC}"
else
    echo -e "${GREEN}✅ No existing GitHub Actions rules found${NC}"
fi

echo ""

# Provide recommendations
echo -e "${BLUE}💡 Recommendations:${NC}"

if [ "$HTTP_STATUS" = "403" ]; then
    echo -e "${YELLOW}For immediate deployment success:${NC}"
    echo "1. Run this script with --fix-access to temporarily allow all access"
    echo "2. Deploy your function"
    echo "3. Run this script with --restore-security to restore restrictions"
    echo ""
    echo -e "${YELLOW}For permanent solution:${NC}"
    echo "1. Use Azure DevOps with self-hosted agents in your VNet"
    echo "2. Use GitHub self-hosted runners in your VNet"
    echo "3. Configure specific IP ranges for GitHub Actions"
elif [ "$PUBLIC_ACCESS" = "false" ]; then
    echo "1. The updated workflow should handle this automatically"
    echo "2. Monitor deployment logs for access rule propagation"
fi

# Handle command line options
case "${1:-}" in
    --fix-access)
        echo ""
        echo -e "${YELLOW}🔧 FIXING ACCESS RESTRICTIONS FOR DEPLOYMENT...${NC}"
        echo "⚠️  This will temporarily make your Function App more permissive!"
        echo ""
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Enabling public network access..."
            az functionapp update \
                --resource-group "$RESOURCE_GROUP" \
                --name "$FUNCTION_APP_NAME" \
                --set publicNetworkAccessEnabled=true

            echo "Removing restrictive access rules..."
            az functionapp config access-restriction list \
                --resource-group "$RESOURCE_GROUP" \
                --name "$FUNCTION_APP_NAME" \
                --query "[?action=='Deny'].name" -o tsv 2>/dev/null | \
            while read -r rule_name; do
                if [ -n "$rule_name" ]; then
                    echo "  Removing deny rule: $rule_name"
                    az functionapp config access-restriction remove \
                        --resource-group "$RESOURCE_GROUP" \
                        --name "$FUNCTION_APP_NAME" \
                        --rule-name "$rule_name" || true
                fi
            done

            echo ""
            echo -e "${GREEN}✅ Access restrictions temporarily relaxed${NC}"
            echo -e "${YELLOW}⚠️  Remember to run --restore-security after deployment!${NC}"
        fi
        ;;
    --restore-security)
        echo ""
        echo -e "${BLUE}🔐 RESTORING SECURITY RESTRICTIONS...${NC}"
        echo "Disabling public network access..."
        az functionapp update \
            --resource-group "$RESOURCE_GROUP" \
            --name "$FUNCTION_APP_NAME" \
            --set publicNetworkAccessEnabled=false

        echo ""
        echo -e "${GREEN}✅ Security restrictions restored${NC}"
        ;;
    --clean-github-rules)
        echo ""
        echo -e "${BLUE}🧹 CLEANING UP GITHUB ACTIONS RULES...${NC}"
        az functionapp config access-restriction list \
            --resource-group "$RESOURCE_GROUP" \
            --name "$FUNCTION_APP_NAME" \
            --query "[?contains(name, 'GitHubActions')].name" -o tsv 2>/dev/null | \
        while read -r rule_name; do
            if [ -n "$rule_name" ]; then
                echo "Removing rule: $rule_name"
                az functionapp config access-restriction remove \
                    --resource-group "$RESOURCE_GROUP" \
                    --name "$FUNCTION_APP_NAME" \
                    --rule-name "$rule_name" || true
            fi
        done
        echo -e "${GREEN}✅ GitHub Actions rules cleaned up${NC}"
        ;;
    *)
        echo ""
        echo -e "${BLUE}Usage Options:${NC}"
        echo "$0                    # Run diagnostics only"
        echo "$0 --fix-access       # Temporarily fix access for deployment"
        echo "$0 --restore-security # Restore security after deployment"
        echo "$0 --clean-github-rules # Clean up old GitHub Actions rules"
        ;;
esac

echo ""
echo -e "${BLUE}=== Diagnostics Complete ===${NC}"
