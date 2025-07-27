#!/bin/bash

# Script to validate the requirements setup

echo "=== Validating Requirements Setup ==="
echo

# Check if requirements files exist
echo "Checking requirements files..."
files=(
    "requirements.txt"
    "requirements/base.txt"
    "requirements/dev.txt"
    "requirements/functions.txt"
    "functions/basic/requirements.txt"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

echo

# Test pip-tools compilation (if available)
if command -v pip-compile &> /dev/null; then
    echo "Testing requirements compilation..."
    pip-compile --dry-run requirements/base.txt > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Base requirements are valid"
    else
        echo "✗ Base requirements have issues"
    fi
else
    echo "ℹ pip-tools not available, skipping compilation test"
fi

echo

# Check for common dependency conflicts
echo "Checking for potential conflicts..."
python3 -c "
import sys
try:
    import pkg_resources
    # This will raise an exception if there are conflicts
    pkg_resources.require(open('requirements.txt').read().splitlines())
    print('✓ No obvious dependency conflicts detected')
except Exception as e:
    print(f'⚠ Potential conflict detected: {e}')
    sys.exit(1)
" 2>/dev/null || echo "ℹ Cannot check conflicts without installing packages"

echo
echo "=== Validation Complete ==="
