#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load SQL Server configuration
CONFIG_FILE="${SCRIPT_DIR}/globals.sh"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: ${CONFIG_FILE}"
    exit 1
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"

echo -e "${YELLOW}=== Stopping SQL Server Container ===${NC}"

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Container '${CONTAINER_NAME}' does not exist.${NC}"
    exit 1
fi

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}Stopping container...${NC}"
    docker stop "${CONTAINER_NAME}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Container stopped.${NC}"
    else
        echo -e "${RED}Failed to stop container.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Container is already stopped.${NC}"
fi

echo ""
echo -e "${GREEN}Data is preserved in:${NC}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
echo "  ${PROJECT_ROOT}/data/"
echo ""
echo "To start again: ./start.sh"