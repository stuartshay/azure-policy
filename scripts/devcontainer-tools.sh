#!/bin/bash

# DevContainer Tools Summary
# This script provides an overview of all available DevContainer testing and debugging tools

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_tool() {
    echo -e "${GREEN}$1${NC}"
    echo -e "  ${CYAN}$2${NC}"
    echo -e "  Usage: ${YELLOW}$3${NC}"
    echo ""
}

print_header "Azure Policy DevContainer Tools"

echo -e "This project includes comprehensive tools for building, testing, and debugging"
echo -e "the DevContainer environment. All scripts are located in the ${YELLOW}scripts/${NC} directory."
echo ""

print_header "Main Testing Tools"

print_tool \
    "./scripts/test-devcontainer.sh" \
    "Complete DevContainer build and test suite with comprehensive validation" \
    "./scripts/test-devcontainer.sh [--help|--cleanup-only|--keep|--no-build|--build-only]"

print_tool \
    "./scripts/quick-rebuild-devcontainer.sh" \
    "Fast rebuild for iterative development with basic connectivity tests" \
    "./scripts/quick-rebuild-devcontainer.sh [--help|--fast|--test-only|--clean]"

print_tool \
    "./scripts/debug-devcontainer.sh" \
    "Comprehensive diagnostic and debugging tool for troubleshooting issues" \
    "./scripts/debug-devcontainer.sh [--help|--logs|--status|--network|--files|--exec|--all]"

print_header "Supporting Tools"

print_tool \
    "./scripts/validate-requirements.sh" \
    "Validate Python requirements setup and check for dependency conflicts" \
    "./scripts/validate-requirements.sh"

print_tool \
    "./scripts/devcontainer-tools.sh" \
    "This help script - shows overview of all available DevContainer tools" \
    "./scripts/devcontainer-tools.sh"

print_header "Quick Start Examples"

echo -e "${YELLOW}# First time setup - build and test everything${NC}"
echo -e "./scripts/test-devcontainer.sh"
echo ""

echo -e "${YELLOW}# Quick development iteration${NC}"
echo -e "./scripts/quick-rebuild-devcontainer.sh"
echo ""

echo -e "${YELLOW}# Troubleshooting issues${NC}"
echo -e "./scripts/debug-devcontainer.sh --all"
echo ""

echo -e "${YELLOW}# Clean up everything${NC}"
echo -e "./scripts/test-devcontainer.sh --cleanup-only"
echo ""

print_header "Documentation"

echo -e "📖 ${CYAN}DEVCONTAINER_TESTING.md${NC} - Comprehensive testing and troubleshooting guide"
echo -e "📖 ${CYAN}README.md${NC} - Main project documentation"
echo -e "📖 ${CYAN}DEVCONTAINER_FIXES.md${NC} - Summary of fixes applied to DevContainer setup"
echo ""

print_header "Common Workflows"

echo -e "${YELLOW}Development Workflow:${NC}"
echo -e "1. Make changes to DevContainer configuration"
echo -e "2. ${CYAN}./scripts/quick-rebuild-devcontainer.sh${NC}"
echo -e "3. ${CYAN}./scripts/quick-rebuild-devcontainer.sh --test-only${NC}"
echo ""

echo -e "${YELLOW}Troubleshooting Workflow:${NC}"
echo -e "1. ${CYAN}./scripts/debug-devcontainer.sh --status${NC}"
echo -e "2. ${CYAN}./scripts/debug-devcontainer.sh --logs${NC}"
echo -e "3. ${CYAN}./scripts/debug-devcontainer.sh --network${NC}"
echo -e "4. ${CYAN}./scripts/debug-devcontainer.sh --files${NC}"
echo ""

echo -e "${YELLOW}Clean Environment Workflow:${NC}"
echo -e "1. ${CYAN}./scripts/test-devcontainer.sh --cleanup-only${NC}"
echo -e "2. ${CYAN}./scripts/quick-rebuild-devcontainer.sh --clean${NC}"
echo -e "3. ${CYAN}./scripts/test-devcontainer.sh${NC}"
echo ""

print_header "Support"

echo -e "If you encounter issues:"
echo -e "1. Run: ${CYAN}./scripts/debug-devcontainer.sh --all${NC}"
echo -e "2. Check: ${CYAN}devcontainer-test.log${NC}"
echo -e "3. Review: ${CYAN}DEVCONTAINER_TESTING.md${NC}"
echo ""

echo -e "For detailed help on any script, use the ${YELLOW}--help${NC} flag."
echo ""
