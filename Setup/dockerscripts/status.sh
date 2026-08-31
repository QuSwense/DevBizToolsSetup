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
if [ -z "${MSSQL_SA_USER:-}" ] || [ -z "${MSSQL_SA_PASSWORD:-}" ]; then
    echo -e "${RED}Error: SQL Server credentials are not configured.${NC}"
    exit 1
fi

if [ -z "${MSSQL_DATABASE_NAME:-}" ]; then
    echo -e "${RED}Error: Database name is not configured.${NC}"
    exit 1
fi

echo -e "${YELLOW}=== SQL Server Status ===${NC}"
echo ""

# Check container
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    CONTAINER_EXISTS=true
else
    CONTAINER_EXISTS=false
fi

if [ "$CONTAINER_EXISTS" = false ]; then
    echo -e "${RED}Container '${CONTAINER_NAME}' does not exist.${NC}"
    echo "Run ./start.sh to create and start it."
    exit 1
fi

# Container status
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "Container Status: ${GREEN}Running${NC}"
else
    echo -e "Container Status: ${RED}Stopped${NC}"
    echo "Run ./start.sh to start it."
    exit 0
fi

# Check data directory
if [ -d "$DATA_DIR" ]; then
    echo -e "Data Directory: ${GREEN}Exists${NC}"
    echo "  Path: $DATA_DIR"

    if [ -d "$DATA_DIR/data" ]; then
        MDF_COUNT=$(find "$DATA_DIR/data" -name "*.mdf" 2>/dev/null | wc -l | tr -d ' ')

        if [ "$MDF_COUNT" -gt 0 ]; then
            echo -e "Database Files: ${GREEN}${MDF_COUNT} .mdf files found${NC}"
            echo ""
            echo -e "${YELLOW}Databases found:${NC}"

            ls -1 "$DATA_DIR/data/"*.mdf 2>/dev/null |
                sed 's/.*\///' |
                sed 's/\.mdf$//' |
                while read db; do
                    if [ "$db" = "master" ] || \
                       [ "$db" = "model" ] || \
                       [ "$db" = "msdbdata" ] || \
                       [ "$db" = "tempdb" ]; then
                        echo "  - $db (system)"
                    elif [ "$db" = "model_msdbdata" ] || \
                         [ "$db" = "model_replicatedmaster" ]; then
                        echo "  - $db (system)"
                    else
                        echo "  - $db (user)"
                    fi
                done
        else
            echo -e "Database Files: ${YELLOW}No .mdf files found${NC}"
        fi
    fi

    if [ -d "$DATA_DIR/backup" ]; then
        BAK_COUNT=$(find "$DATA_DIR/backup" -name "*.bak" 2>/dev/null | wc -l | tr -d ' ')

        if [ "$BAK_COUNT" -gt 0 ]; then
            echo -e "Backup Files: ${GREEN}${BAK_COUNT} .bak files found${NC}"
            echo "  Location: ${DATA_DIR}/backup/"
        else
            echo -e "Backup Files: ${YELLOW}None found${NC}"
        fi
    fi

    DATA_SIZE=$(du -sh "$DATA_DIR" 2>/dev/null | cut -f1)
    echo -e "Total Data Size: ${GREEN}${DATA_SIZE:-0B}${NC}"
else
    echo -e "Data Directory: ${RED}Does not exist${NC}"
fi

echo ""

# Test database connection
echo -e "${YELLOW}=== Database Connection Test ===${NC}"

DB_EXISTS=$(docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd \
    -S localhost \
    -U "${MSSQL_SA_USER}" \
    -P "${MSSQL_SA_PASSWORD}" \
    -C \
    -d master \
    -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name='${MSSQL_DATABASE_NAME}';" \
    -h -1 2>/dev/null | tr -d '[:space:]')

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "Database '${MSSQL_DATABASE_NAME}': ${GREEN}Exists${NC}"

    echo -e "${YELLOW}Testing connection...${NC}"

    RESULT=$(docker exec "${CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost \
        -U "${MSSQL_SA_USER}" \
        -P "${MSSQL_SA_PASSWORD}" \
        -C \
        -d "${MSSQL_DATABASE_NAME}" \
        -Q "SET NOCOUNT ON; SELECT DB_NAME() AS DatabaseName, GETDATE() AS ServerTime;" \
        -h -1 2>/dev/null)

    if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
        echo -e "${GREEN}Connection successful!${NC}"
        echo ""
        echo "$RESULT"
    else
        echo -e "${RED}Connection failed. Database may be in recovery.${NC}"
    fi

elif [ "$DB_EXISTS" = "0" ]; then
    echo -e "Database '${MSSQL_DATABASE_NAME}': ${YELLOW}Does not exist${NC}"
    echo "Run ./start.sh to create it automatically."

else
    echo -e "Database check: ${RED}Failed - SQL Server may not be ready${NC}"
fi

echo ""
echo -e "${YELLOW}=== Recent Container Logs ===${NC}"
docker logs "${CONTAINER_NAME}" --tail 8 2>/dev/null |
    grep -v "spid" |
    head -5 ||
    echo -e "${YELLOW}No recent logs${NC}"
