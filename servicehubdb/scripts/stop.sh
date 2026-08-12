#!/bin/bash

CONTAINER_NAME="mssql-server"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Stopping SQL Server Container ===${NC}"

# Check if container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Container '${CONTAINER_NAME}' does not exist.${NC}"
    exit 1
fi

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}Stopping container...${NC}"
    docker stop ${CONTAINER_NAME}
    
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