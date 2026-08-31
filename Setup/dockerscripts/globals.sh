#!/bin/bash

# SQL Server configuration
# Keep this file private and do not commit it to source control.

MSSQL_SA_USER="sa"
MSSQL_SA_PASSWORD="root@1234"

# Database name
MSSQL_DATABASE_NAME="OrbitTool"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTAINER_BASE_NAME="orbit-tool-mssql"
CONTAINER_NAME="${CONTAINER_BASE_NAME}-server"
CUSTOM_IMAGE="${CONTAINER_BASE_NAME}:latest"
DATA_DIR="${PROJECT_ROOT}/data"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)  echo "macos" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

OS=$(detect_os)