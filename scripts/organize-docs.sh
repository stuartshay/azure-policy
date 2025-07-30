#!/bin/bash

# Script: Organize Documentation
# Description: Moves markdown files to the docs/ folder according to project standards
# Usage: ./scripts/organize-docs.sh [--dry-run]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DRY_RUN=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dry-run]"
            echo ""
            echo "Options:"
            echo "  --dry-run    Show what would be moved without actually moving files"
            echo "  -h, --help   Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}📚 Azure Policy Documentation Organizer${NC}"
echo "========================================"
echo ""

# Ensure we're in the project root
if [[ ! -f "README.md" ]] || [[ ! -d ".git" ]]; then
    echo -e "${RED}❌ This script must be run from the project root directory${NC}"
    exit 1
fi

# Create docs directory if it doesn't exist
if [[ ! -d "docs" ]]; then
    echo -e "${YELLOW}📁 Creating docs/ directory${NC}"
    if [[ "$DRY_RUN" == "false" ]]; then
        mkdir -p docs
    fi
fi

# Find markdown files that need to be moved
echo -e "${BLUE}🔍 Scanning for markdown files...${NC}"

# Files that should stay in root
ROOT_EXCEPTIONS=("README.md" "CHANGELOG.md" "CONTRIBUTING.md" "LICENSE.md" "CODE_OF_CONDUCT.md")

# Find all .md files not in docs/, excluding root exceptions and special directories
MISPLACED_FILES=()
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    # Skip if it's in docs/ already
    if [[ "$file" == ./docs/* ]]; then
        continue
    fi
    # Skip if it's a root exception
    is_exception=false
    for exception in "${ROOT_EXCEPTIONS[@]}"; do
        if [[ "$filename" == "$exception" ]]; then
            is_exception=true
            break
        fi
    done
    if [[ "$is_exception" == "true" ]]; then
        continue
    fi
    # Skip special directories and common exclusions
    if [[ "$file" == ./.git/* ]] || \
       [[ "$file" == ./node_modules/* ]] || \
       [[ "$file" == ./.venv/* ]] || \
       [[ "$file" == ./*/venv/* ]] || \
       [[ "$file" == ./.cline/* ]] || \
       [[ "$file" == ./.github/copilot_instructions.md ]] || \
       [[ "$file" == ./.github/chatmodes/* ]] || \
       [[ "$file" == ./*/site-packages/* ]] || \
       [[ "$file" == ./*/.venv/* ]]; then
        continue
    fi
    MISPLACED_FILES+=("$file")
done < <(find . -name "*.md" -type f -print0)

if [[ ${#MISPLACED_FILES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✅ All markdown files are already properly organized!${NC}"
    echo ""
    echo -e "${BLUE}📋 Current documentation structure:${NC}"
    if [[ -d "docs" ]]; then
        find docs -name "*.md" -type f | sort | sed 's/^/  /'
    else
        echo "  No documentation found in docs/ folder"
    fi
    exit 0
fi

echo -e "${YELLOW}📋 Found ${#MISPLACED_FILES[@]} markdown file(s) to organize:${NC}"
for file in "${MISPLACED_FILES[@]}"; do
    echo "  $file"
done
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}🔄 DRY RUN - Would perform these actions:${NC}"
else
    echo -e "${BLUE}🔄 Moving files to docs/ folder:${NC}"
fi

MOVED_COUNT=0
for file in "${MISPLACED_FILES[@]}"; do
    filename=$(basename "$file")
    target="docs/$filename"

    # Check if target already exists
    if [[ -f "$target" ]]; then
        echo -e "${YELLOW}⚠️  Skipping $file - docs/$filename already exists${NC}"
        continue
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${GREEN}  Would move: $file → $target${NC}"
    else
        echo -e "${GREEN}  Moving: $file → $target${NC}"
        mv "$file" "$target"
    fi

    ((MOVED_COUNT++))
done

echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${BLUE}📊 DRY RUN SUMMARY:${NC}"
    echo -e "  Would move: $MOVED_COUNT file(s)"
    echo -e "  Would skip: $((${#MISPLACED_FILES[@]} - MOVED_COUNT)) file(s) (conflicts)"
    echo ""
    echo -e "${YELLOW}💡 Run without --dry-run to actually move the files${NC}"
else
    echo -e "${BLUE}📊 SUMMARY:${NC}"
    echo -e "  Moved: $MOVED_COUNT file(s)"
    echo -e "  Skipped: $((${#MISPLACED_FILES[@]} - MOVED_COUNT)) file(s) (conflicts)"

    if [[ $MOVED_COUNT -gt 0 ]]; then
        echo ""
        echo -e "${GREEN}✅ Documentation organized successfully!${NC}"
        echo ""
        echo -e "${BLUE}📋 Updated documentation structure:${NC}"
        find docs -name "*.md" -type f | sort | sed 's/^/  /'
        echo ""
        echo -e "${YELLOW}💡 Don't forget to:${NC}"
        echo "  1. Update any links that reference the moved files"
        echo "  2. Commit the changes: git add docs/ && git commit -m 'docs: organize markdown files'"
        echo "  3. Update docs/README.md index if needed"
    fi
fi

echo ""
echo -e "${BLUE}📚 Documentation Standards:${NC}"
echo "  • All .md files (except root-level exceptions) belong in docs/"
echo "  • Root exceptions: ${ROOT_EXCEPTIONS[*]}"
echo "  • Maintains clean repository structure"
echo "  • Enforced by pre-commit hooks and CI/CD"
