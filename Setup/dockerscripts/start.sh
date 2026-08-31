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

# Validate required configuration without displaying credentials
if [ -z "${MSSQL_SA_USER:-}" ]; then
    echo "Error: SQL Server user is not configured."
    exit 1
fi

if [ -z "${MSSQL_SA_PASSWORD:-}" ]; then
    echo "Error: SQL Server password is not configured."
    exit 1
fi

if [ -z "${MSSQL_DATABASE_NAME:-}" ]; then
    echo "Error: Database name is not configured."
    exit 1
fi

echo -e "${YELLOW}=== SQL Server Container Manager ===${NC}"
echo -e "OS: ${OS}"
echo -e "Data Directory: ${DATA_DIR}"
echo -e "Database: ${MSSQL_DATABASE_NAME}"
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
    if ! docker image inspect "${CUSTOM_IMAGE}" > /dev/null 2>&1; then
        echo -e "${YELLOW}Building custom image ${CUSTOM_IMAGE}...${NC}"

        if [ -f "${PROJECT_ROOT}/docker-image/Dockerfile" ]; then
            docker build -t "${CUSTOM_IMAGE}" "${PROJECT_ROOT}/docker-image/"

            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Image built successfully!${NC}"
            else
                echo -e "${RED}Failed to build custom image.${NC}"
                exit 1
            fi
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

# Check whether the configured database exists
check_database() {
    docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U "${MSSQL_SA_USER}" \
        -P "${MSSQL_SA_PASSWORD}" \
        -C \
        -d master \
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name='${MSSQL_DATABASE_NAME}';" \
        -h -1 2>/dev/null | tr -d '[:space:]'
}

if [ "$CONTAINER_EXISTS" = true ] && [ "$CONTAINER_RUNNING" = true ]; then
    echo -e "${GREEN}Container is already running.${NC}"
    docker ps --filter "name=${CONTAINER_NAME}"

elif [ "$CONTAINER_EXISTS" = true ] && [ "$CONTAINER_RUNNING" = false ]; then
    echo -e "${YELLOW}Starting existing container...${NC}"
    docker start "${CONTAINER_NAME}"

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to start existing container.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Waiting for SQL Server to start...${NC}"
    sleep 15

else
    echo -e "${YELLOW}Creating new container...${NC}"

    PLATFORM_FLAG=""
    if [[ "$OS" != "macos" ]]; then
        PLATFORM_FLAG="--platform linux/amd64"
    fi

    CAP_FLAG=""
    if [[ "$OS" == "macos" ]]; then
        CAP_FLAG="--cap-add SYS_PTRACE"
    fi

    docker run ${PLATFORM_FLAG} ${CAP_FLAG} \
        -e "ACCEPT_EULA=1" \
        -e "MSSQL_SA_USER=${MSSQL_SA_USER}" \
        -e "MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD}" \
        -e "MSSQL_DATABASE_NAME=${MSSQL_DATABASE_NAME}" \
        -p 1433:1433 \
        --name "${CONTAINER_NAME}" \
        --hostname "${CONTAINER_NAME}" \
        -v "${DATA_DIR}:/var/opt/mssql" \
        -d \
        "${DOCKER_IMAGE}"

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create container.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Waiting for SQL Server to initialize...${NC}"
    sleep 20
fi

# Check if database exists
echo -e "${YELLOW}Checking ${MSSQL_DATABASE_NAME} database...${NC}"
DB_COUNT=$(check_database)

if [ "$DB_COUNT" = "0" ]; then
    echo -e "${YELLOW}Creating ${MSSQL_DATABASE_NAME} database...${NC}"

    docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U "${MSSQL_SA_USER}" \
        -P "${MSSQL_SA_PASSWORD}" \
        -C \
        -d master \
        -Q "CREATE DATABASE [${MSSQL_DATABASE_NAME}];"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Database '${MSSQL_DATABASE_NAME}' created.${NC}"
    else
        echo -e "${RED}Failed to create database '${MSSQL_DATABASE_NAME}'.${NC}"
        exit 1
    fi

elif [ "$DB_COUNT" = "1" ]; then
    echo -e "${GREEN}Database '${MSSQL_DATABASE_NAME}' already exists.${NC}"

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
echo "Database: ${MSSQL_DATABASE_NAME}"
