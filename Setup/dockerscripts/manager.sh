#!/bin/bash

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load global configuration
CONFIG_FILE="${SCRIPT_DIR}/globals.sh"
    
# shellcheck disable=SC1090
source "$CONFIG_FILE"

clear
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   SQL Server Container Manager        ${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Project: ${PROJECT_ROOT}"
echo ""

echo -e "${YELLOW}Available Commands:${NC}"
echo "1. Start Container"
echo "2. Stop Container"
echo "3. Container Status"
echo "4. Exit"
echo ""

read -p "Choose option [1-4]: " choice

case $choice in
    1)
        ${SCRIPT_DIR}/start.sh
        ;;
    2)
        ${SCRIPT_DIR}/stop.sh
        ;;
    3)
        ${SCRIPT_DIR}/status.sh
        ;;
    4)
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option.${NC}"
        ;;
esac

echo ""
read -p "Press Enter to continue..."
${SCRIPT_DIR}/manager.sh