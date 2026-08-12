#!/bin/bash

CONTAINER_NAME="mssql-server"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== SQL Server Status ===${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="${PROJECT_ROOT}/data"

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
    
    # Check for database files
    if [ -d "$DATA_DIR/data" ]; then
        MDF_COUNT=$(find "$DATA_DIR/data" -name "*.mdf" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$MDF_COUNT" -gt 0 ]; then
            echo -e "Database Files: ${GREEN}${MDF_COUNT} .mdf files found${NC}"
            echo ""
            echo -e "${YELLOW}Databases found:${NC}"
            ls -1 "$DATA_DIR/data/"*.mdf 2>/dev/null | sed 's/.*\///' | sed 's/\.mdf$//' | while read db; do
                if [ "$db" = "master" ] || [ "$db" = "model" ] || [ "$db" = "msdbdata" ] || [ "$db" = "tempdb" ]; then
                    echo "  - $db (system)"
                elif [ "$db" = "model_msdbdata" ] || [ "$db" = "model_replicatedmaster" ]; then
                    echo "  - $db (system)"
                else
                    echo "  - $db (user)"
                fi
            done
        else
            echo -e "Database Files: ${YELLOW}No .mdf files found${NC}"
        fi
    fi
    
    # Check backup directory
    if [ -d "$DATA_DIR/backup" ]; then
        BAK_COUNT=$(find "$DATA_DIR/backup" -name "*.bak" 2>/dev/null | wc -l | tr -d ' ')
        if [ "$BAK_COUNT" -gt 0 ]; then
            echo -e "Backup Files: ${GREEN}${BAK_COUNT} .bak files found${NC}"
            echo "  Location: ${DATA_DIR}/backup/"
        else
            echo -e "Backup Files: ${YELLOW}None found${NC}"
        fi
    fi
    
    # Show total size
    DATA_SIZE=$(du -sh "$DATA_DIR" 2>/dev/null | cut -f1)
    echo -e "Total Data Size: ${GREEN}${DATA_SIZE:-0B}${NC}"
else
    echo -e "Data Directory: ${RED}Does not exist${NC}"
fi

echo ""

# Test database connection
echo -e "${YELLOW}=== Database Connection Test ===${NC}"

# Check if servicehub exists - redirect stderr to null to avoid errors
DB_EXISTS=$(docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "root@1234" -C -d master \
    -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name='servicehub';" \
    -h -1 2>/dev/null | tr -d '[:space:]')

# Debug: show what was returned (remove this line after testing)
# echo "DEBUG: DB_EXISTS='$DB_EXISTS'"

if [ "$DB_EXISTS" = "1" ]; then
    echo -e "Database 'servicehub': ${GREEN}Exists${NC}"
    
    # Now test connection
    echo -e "${YELLOW}Testing connection...${NC}"
    RESULT=$(docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "root@1234" -C -d servicehub \
        -Q "SET NOCOUNT ON; SELECT DB_NAME() AS Database, GETDATE() AS ServerTime;" \
        -h -1 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
        echo -e "${GREEN}✓ Connection successful!${NC}"
        echo ""
        echo "$RESULT"
    else
        echo -e "${RED}✗ Connection failed. Database may be in recovery.${NC}"
    fi
elif [ "$DB_EXISTS" = "0" ]; then
    echo -e "Database 'servicehub': ${YELLOW}Does not exist${NC}"
    echo "Run ./start.sh to create it automatically."
else
    echo -e "Database check: ${RED}Failed - SQL Server may not be ready${NC}"
    echo -e "${YELLOW}Try running: docker exec ${CONTAINER_NAME} /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'root@1234' -C -d master -Q 'SELECT name FROM sys.databases;'${NC}"
fi

echo ""
echo -e "${YELLOW}=== Recent Container Logs ===${NC}"
docker logs ${CONTAINER_NAME} --tail 8 2>/dev/null | grep -v "spid" | head -5 || echo -e "${YELLOW}No recent logs${NC}"