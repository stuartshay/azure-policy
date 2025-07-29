#!/bin/bash

# Simple syntax checker for install.sh
echo "Checking syntax of install.sh..."

if bash -n install.sh; then
    echo "✓ Syntax is valid!"
    exit 0
else
    echo "✗ Syntax errors found!"
    exit 1
fi
