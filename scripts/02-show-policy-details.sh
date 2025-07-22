#!/bin/bash

# Script: Show Policy Details
# Description: Shows detailed information about a specific Azure Policy
# Usage: ./02-show-policy-details.sh [policy-name] [output-directory]

# Function to write output to both console and file
write_output() {
    local message="$1"
    echo "$message"
    
    if [ "$OUTPUT_TO_FILE" = true ]; then
        echo "$message" >> "$OUTPUT_FILE_PATH"
    fi
}

echo "=== Azure Policy Script ==="
echo "Script: Show Policy Details"
echo "Date: $(date)"
echo ""

# Parse command line arguments
POLICY_NAME="$1"
OUTPUT_DIRECTORY="$2"
OUTPUT_TO_FILE=false
OUTPUT_FILE_PATH=""

# Check if output directory is specified
if [ -n "$OUTPUT_DIRECTORY" ]; then
    OUTPUT_TO_FILE=true
    
    # Create output directory if it doesn't exist
    if [ ! -d "$OUTPUT_DIRECTORY" ]; then
        if mkdir -p "$OUTPUT_DIRECTORY" 2>/dev/null; then
            echo "✅ Created output directory: $OUTPUT_DIRECTORY"
        else
            echo "❌ Failed to create output directory: $OUTPUT_DIRECTORY"
            exit 1
        fi
    fi
    
    # Prepare output file path
    TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
    if [ -n "$POLICY_NAME" ]; then
        SAFE_FILENAME=$(echo "$POLICY_NAME" | sed 's/[^a-zA-Z0-9_-]/_/g')
        OUTPUT_FILE_PATH="$OUTPUT_DIRECTORY/${SAFE_FILENAME}_${TIMESTAMP}.txt"
    else
        OUTPUT_FILE_PATH="$OUTPUT_DIRECTORY/policy-details_${TIMESTAMP}.txt"
    fi
    
    echo "📁 Output will be saved to: $OUTPUT_FILE_PATH"
    
    # Initialize the output file with header
    {
        echo "=== Azure Policy Script ==="
        echo "Script: Show Policy Details"
        echo "Date: $(date)"
        echo ""
    } > "$OUTPUT_FILE_PATH"
fi

# If no policy name provided, show some popular examples
if [ $# -eq 0 ]; then
    write_output "🔍 Usage: $0 [policy-name] [output-directory]"
    write_output ""
    write_output "📝 Popular Built-in Policies to explore:"
    write_output "========================================"
    write_output "• Allowed locations"
    write_output "• Require a tag on resources"
    write_output "• Not allowed resource types"
    write_output "• Allowed virtual machine size SKUs"
    write_output "• Audit VMs that do not use managed disks"
    write_output "• Deploy Log Analytics agent for Linux VMs"
    write_output ""
    write_output "Examples:"
    write_output "  $0 'Allowed locations'"
    write_output "  $0 'Allowed locations' './reports'"
    write_output "  $0 'Require a tag' '/tmp/policy-reports'"
    exit 1
fi

write_output "🔍 Searching for policy: '$POLICY_NAME'"
write_output ""

# Search for the policy
POLICY_JSON=$(az policy definition list --query "[?contains(displayName, '$POLICY_NAME')]" --output json)

if [ "$(echo $POLICY_JSON | jq length)" -eq 0 ]; then
    write_output "❌ No policy found with name containing '$POLICY_NAME'"
    write_output ""
    write_output "💡 Try searching with partial names or check available policies with:"
    write_output "   ./01-list-policies.sh"
    exit 1
fi

# Show policy details
POLICY_COUNT=$(echo $POLICY_JSON | jq length)

echo $POLICY_JSON | jq -r '.[] | "
📋 Policy Details:
==================
Name: \(.displayName)
Description: \(.description // "N/A")
Category: \(.metadata.category // "N/A")
Mode: \(.mode)
Type: \(.policyType)
ID: \(.id)

📜 Policy Rule:
===============
\(.policyRule | tostring)

⚙️  Parameters:
===============
\(if .parameters then (.parameters | tostring) else "No parameters" end)

🏷️  Metadata:
=============
\(.metadata | tostring)
"' | while IFS= read -r line; do
    write_output "$line"
done

# Add separator if multiple policies found
if [ "$POLICY_COUNT" -gt 1 ]; then
    write_output ""
    write_output "$(printf '=%.0s' {1..80})"
fi

write_output ""
write_output "💡 Next steps:"
write_output "- Run ./03-list-assignments.sh to see policy assignments"
write_output "- Run ./04-create-assignment.sh to create a new assignment"

# Show summary if multiple policies found
if [ "$POLICY_COUNT" -gt 1 ]; then
    write_output ""
    write_output "📊 Search Summary:"
    write_output "Found $POLICY_COUNT policies matching '$POLICY_NAME'"
fi

# Show file output confirmation
if [ "$OUTPUT_TO_FILE" = true ]; then
    FILE_SIZE=$(stat -c%s "$OUTPUT_FILE_PATH" 2>/dev/null || stat -f%z "$OUTPUT_FILE_PATH" 2>/dev/null || echo "unknown")
    write_output ""
    write_output "✅ Policy details have been saved to: $OUTPUT_FILE_PATH"
    write_output "📁 File size: $FILE_SIZE bytes"
fi
