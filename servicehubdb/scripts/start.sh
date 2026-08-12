#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
CONTAINER_NAME="mssql-server"
CUSTOM_IMAGE="servicehub-sql:latest"
DATA_DIR="${PROJECT_ROOT}/data"

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)  echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

OS=$(detect_os)

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== SQL Server Container Manager ===${NC}"
echo -e "OS: ${OS}"
echo -e "Data Directory: ${DATA_DIR}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker Desktop.${NC}"
    exit 1
fi

# Create data directory
mkdir -p "$DATA_DIR"

# Build custom image if missing on macOS
if [[ "$OS" == "macos" ]]; then
    if ! docker image inspect ${CUSTOM_IMAGE} > /dev/null 2>&1; then
        echo -e "${YELLOW}Building custom image ${CUSTOM_IMAGE}...${NC}"
        if [ -f "${PROJECT_ROOT}/docker-image/Dockerfile" ]; then
            docker build -t ${CUSTOM_IMAGE} "${PROJECT_ROOT}/docker-image/"
            echo -e "${GREEN}Image built successfully!${NC}"
        else
            echo -e "${RED}Dockerfile not found. Using azure-sql-edge.${NC}"
            CUSTOM_IMAGE="mcr.microsoft.com/azure-sql-edge"
        fi
    fi
fi

# Determine image to use
if [[ "$OS" == "macos" ]]; then
    DOCKER_IMAGE="${CUSTOM_IMAGE}"
else
    DOCKER_IMAGE="mcr.microsoft.com/mssql/server:2022-latest"
fi

# Check if container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    CONTAINER_EXISTS=true
else
    CONTAINER_EXISTS=false
fi

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    CONTAINER_RUNNING=true
else
    CONTAINER_RUNNING=false
fi

# Function to check if servicehub exists
check_servicehub() {
    docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "root@1234" -C -d master \
        -Q "SELECT COUNT(*) FROM sys.databases WHERE name='servicehub';" \
        -h -1 2>/dev/null | tr -d ' '
}

if [ "$CONTAINER_EXISTS" = true ] && [ "$CONTAINER_RUNNING" = true ]; then
    echo -e "${GREEN}Container is already running.${NC}"
    docker ps --filter "name=${CONTAINER_NAME}"
    
elif [ "$CONTAINER_EXISTS" = true ] && [ "$CONTAINER_RUNNING" = false ]; then
    echo -e "${YELLOW}Starting existing container...${NC}"
    docker start ${CONTAINER_NAME}
    echo -e "${YELLOW}Waiting for SQL Server to start...${NC}"
    sleep 15
    
else
    echo -e "${YELLOW}Creating new container...${NC}"
    
    # Platform flag for non-macOS
    PLATFORM_FLAG=""
    if [[ "$OS" != "macos" ]]; then
        PLATFORM_FLAG="--platform linux/amd64"
    fi
    
    # Azure SQL Edge needs SYS_PTRACE on macOS
    CAP_FLAG=""
    if [[ "$OS" == "macos" ]]; then
        CAP_FLAG="--cap-add SYS_PTRACE"
    fi
    
    docker run ${PLATFORM_FLAG} ${CAP_FLAG} \
        -e "ACCEPT_EULA=1" \
        -e "MSSQL_SA_PASSWORD=root@1234" \
        -p 1433:1433 \
        --name ${CONTAINER_NAME} \
        --hostname ${CONTAINER_NAME} \
        -v ${DATA_DIR}:/var/opt/mssql \
        -d \
        ${DOCKER_IMAGE}
    
    echo -e "${YELLOW}Waiting for SQL Server to initialize...${NC}"
    sleep 20
fi

# Check if servicehub database exists
echo -e "${YELLOW}Checking servicehub database...${NC}"
DB_COUNT=$(check_servicehub)

if [ "$DB_COUNT" = "0" ]; then
    echo -e "${YELLOW}Creating servicehub database...${NC}"
    docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "root@1234" -C -d master \
        -Q "CREATE DATABASE servicehub;"
    echo -e "${GREEN}Database 'servicehub' created.${NC}"
elif [ "$DB_COUNT" = "1" ]; then
    echo -e "${GREEN}Database 'servicehub' already exists.${NC}"
else
    echo -e "${RED}Could not check database. SQL Server may not be ready.${NC}"
fi

# Show status
echo ""
echo -e "${GREEN}=== Container Status ===${NC}"
docker ps --filter "name=${CONTAINER_NAME}"

echo ""
echo -e "${GREEN}=== Data Directory ===${NC}"
echo "Data: ${DATA_DIR}"
echo ""
echo "Inside this folder you'll find:"
echo "  data/     - Database files (.mdf, .ldf)"
echo "  log/      - SQL Server logs"
echo "  backup/   - Backup files (.bak)"

echo ""
echo -e "${GREEN}=== Connection Info ===${NC}"
echo "Server: localhost,1433"
echo "Username: sa"
echo "Password: root@1234"
echo "Database: servicehub"