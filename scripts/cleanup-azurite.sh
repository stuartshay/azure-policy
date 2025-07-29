#!/bin/bash

# Cleanup Azurite Data Script
# This script removes all Azurite storage emulator data to reset the local storage state

set -e

echo "🗄️  Azurite Storage Cleanup"
echo "=========================="
echo ""

# Check if we're in the right directory
if [ ! -d "azurite-data" ]; then
    echo "❌ Error: azurite-data directory not found"
    echo "   Please run this script from the repository root directory"
    exit 1
fi

echo "📍 Current directory: $(pwd)"
echo ""

# Check if Azurite is running
echo "🔍 Checking if Azurite is running..."
if pgrep -f azurite > /dev/null; then
    echo "⚠️  Azurite appears to be running. Please stop it before cleanup."
    echo "   You can stop it by:"
    echo "   - Closing the terminal where azurite is running"
    echo "   - Or using: pkill -f azurite"
    echo ""
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleanup cancelled."
        exit 0
    fi
fi

echo "🧹 Cleaning up Azurite data..."

# Count files before cleanup
file_count=$(find azurite-data -type f ! -name "README.md" | wc -l)

if [ "$file_count" -eq 0 ]; then
    echo "✅ No Azurite data files found to clean up"
else
    echo "   Found $file_count files to remove"

    # Remove all files except README.md
    find azurite-data -type f ! -name "README.md" -delete

    # Remove any empty directories
    find azurite-data -type d -empty -delete 2>/dev/null || true

    echo "✅ Removed $file_count files"
fi

# Also clean up any Azurite files in the root directory (legacy)
echo ""
echo "🧹 Cleaning up legacy Azurite files in root directory..."
legacy_files=("__azurite_db_blob__.json" "__azurite_db_blob_extent__.json" "__blobstorage__")
removed_count=0

for file in "${legacy_files[@]}"; do
    if [ -e "$file" ]; then
        rm -rf "$file"
        echo "   Removed: $file"
        ((removed_count++))
    fi
done

if [ "$removed_count" -eq 0 ]; then
    echo "✅ No legacy files found to clean up"
else
    echo "✅ Removed $removed_count legacy files"
fi

echo ""
echo "🎯 Cleanup Complete!"
echo ""
echo "📋 What was cleaned:"
echo "   • Azurite database files (__azurite_db_blob*.json)"
echo "   • Blob storage data (__blobstorage__ directory)"
echo "   • Debug logs (debug.log)"
echo "   • Any legacy files in the root directory"
echo ""
echo "📌 Note: The azurite-data/README.md file was preserved"
echo ""
echo "🚀 To start fresh:"
echo "   1. Start Azurite: Run the 'Start Azurite' VS Code task"
echo "   2. Or manually: azurite --silent --location ./azurite-data --debug ./azurite-data/debug.log"
echo ""
