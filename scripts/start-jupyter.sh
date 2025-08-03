#!/bin/bash

# Start Jupyter Lab for Azure Policy Project
# This script starts Jupyter Lab with the project's virtual environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Jupyter Lab for Azure Policy Project${NC}"
echo -e "${BLUE}================================================${NC}"

# Check if we're in the project directory
if [ ! -f "requirements.txt" ] || [ ! -d "notebooks" ]; then
    echo -e "${RED}❌ Error: Please run this script from the azure-policy project root directory${NC}"
    exit 1
fi

# Check if virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
    echo -e "${YELLOW}⚠️  Virtual environment not detected. Attempting to activate...${NC}"
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
        echo -e "${GREEN}✅ Virtual environment activated${NC}"
    else
        echo -e "${RED}❌ Virtual environment not found. Please run 'python -m venv .venv' first${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Virtual environment is active: $VIRTUAL_ENV${NC}"
fi

# Check if Jupyter is installed
if ! command -v jupyter &> /dev/null; then
    echo -e "${RED}❌ Jupyter not found. Installing requirements...${NC}"
    pip install -r requirements.txt
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Please ensure your Azure credentials are configured.${NC}"
    echo -e "${YELLOW}   You can copy .env.template to .env and fill in your values.${NC}"
fi

echo -e "${GREEN}📊 Starting Jupyter Lab...${NC}"
echo -e "${BLUE}💡 Tips:${NC}"
echo -e "   • Open notebooks/environment_validation.ipynb to validate your Azure environment"
echo -e "   • Use Ctrl+C to stop Jupyter Lab"
echo -e "   • Jupyter Lab will open in your default browser"
echo ""

# Start Jupyter Lab
# --ip=0.0.0.0 allows access from any IP (useful for remote development)
# --no-browser prevents auto-opening browser (useful for remote/headless environments)
# --allow-root allows running as root (sometimes needed in containers)
jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --notebook-dir=. \
    --ServerApp.token='' \
    --ServerApp.password='' \
    --ServerApp.allow_origin='*' \
    --ServerApp.disable_check_xsrf=True
