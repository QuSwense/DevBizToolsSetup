#!/bin/bash
#===============================================================================
# OrbitTool Database Management Script
#
# Provides a menu-driven interface to execute SQL scripts against the OrbitTool
# database. Supports schema reset, seed data management, and column descriptions.
#
# Usage:
#   ./OrbitTool_SQLCMD.sh
#
# Prerequisites:
#   - sqlcmd must be installed and available in PATH
#   - Docker container with SQL Server must be running on localhost:1433
#   - SA password must be set via SQLCMDPASSWORD env var or script default
#===============================================================================

set -euo pipefail

# ---- Configuration ----
SERVER='localhost,1433'
USER='sa'
DATABASE='OrbitTool'
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default password - override via SQLCMDPASSWORD environment variable
: "${SQLCMDPASSWORD:=root@1234}"
export SQLCMDPASSWORD

# ---- Helper Functions ----

run_sqlcmd() {
    local db="$1"
    local script="$2"
    local script_path="$SCRIPT_DIR/$script"

    if [ ! -f "$script_path" ]; then
        echo "ERROR: Script not found: $script_path"
        return 1
    fi

    echo "Executing: $script against [$db]..."
    sqlcmd \
        -S "$SERVER" \
        -U "$USER" \
        -C \
        -d "$db" \
        -b \
        -i "$script_path"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "  [OK] $script completed successfully."
    else
        echo "  [FAIL] $script exited with code $exit_code."
    fi
    return $exit_code
}

run_sqlcmd_pwd() {
    local db="$1"
    local script="$2"
    local script_path="$SCRIPT_DIR/$script"

    if [ ! -f "$script_path" ]; then
        echo "ERROR: Script not found: $script_path"
        return 1
    fi

    echo "Executing: $script against [$db]..."
    SQLCMDPASSWORD="$SQLCMDPASSWORD" sqlcmd \
        -S "$SERVER" \
        -U "$USER" \
        -C \
        -d "$db" \
        -b \
        -i "$script_path"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "  [OK] $script completed successfully."
    else
        echo "  [FAIL] $script exited with code $exit_code."
    fi
    return $exit_code
}

# ---- Menu Actions ----

reset_and_recreate() {
    echo ""
    echo "--- Reset and Recreate Schema ---"
    echo "This will DROP and RECREATE all tables, views, and stored procedures."
    echo "WARNING: All existing data will be LOST!"
    read -r -p "Are you sure? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        return
    fi
    run_sqlcmd "master" "OrbitTool_ResetAndRecreate.sql"
}

reset_and_recreate_with_descriptions() {
    echo ""
    echo "--- Reset and Recreate Schema (with Column Descriptions) ---"
    echo "This will DROP and RECREATE all tables, views, and stored procedures,"
    echo "then apply MS_Description extended properties to all columns."
    echo "WARNING: All existing data will be LOST!"
    read -r -p "Are you sure? (y/N): confirm"
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        return
    fi
    run_sqlcmd "master" "OrbitTool_ResetAndRecreate.sql"
    echo ""
    run_sqlcmd "$DATABASE" "ApplyColumnDescriptions.sql"
}

apply_column_descriptions() {
    echo ""
    echo "--- Apply Column Descriptions ---"
    echo "This applies MS_Description extended properties to all table columns."
    echo "Does NOT modify schema or data."
    run_sqlcmd "$DATABASE" "ApplyColumnDescriptions.sql"
}

run_seeds() {
    echo ""
    echo "--- Insert Seed Data ---"
    echo "This will insert seed/reference data into all tables in FK-safe order."
    echo "Existing data with matching keys will be skipped (idempotent inserts)."
    read -r -p "Continue? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        return
    fi
    run_sqlcmd "$DATABASE" "RunSeeds.sql"
}

clear_data() {
    echo ""
    echo "--- Clear All Table Data ---"
    echo "This will DELETE all rows from all tables in FK-safe order."
    echo "WARNING: ALL data will be permanently removed!"
    read -r -p "Are you sure? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        return
    fi
    read -r -p "Type 'CONFIRM' to proceed: " confirm2
    if [[ "$confirm2" != "CONFIRM" ]]; then
        echo "Cancelled."
        return
    fi
    run_sqlcmd "$DATABASE" "ClearSeeds.sql"
}

clear_and_reinsert() {
    echo ""
    echo "--- Clear All Data and Re-insert Seeds ---"
    echo "This will DELETE all rows, then re-insert all seed data."
    echo "WARNING: ALL existing data will be permanently lost!"
    read -r -p "Are you sure? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        return
    fi
    read -r -p "Type 'CONFIRM' to proceed: " confirm2
    if [[ "$confirm2" != "CONFIRM" ]]; then
        echo "Cancelled."
        return
    fi
    run_sqlcmd "$DATABASE" "ClearSeeds.sql"
    echo ""
    run_sqlcmd "$DATABASE" "RunSeeds.sql"
}

# ---- Main Menu ----

show_menu() {
    clear
    echo "=============================================="
    echo "  OrbitTool Database Management"
    echo "  Server: $SERVER  Database: $DATABASE"
    echo "=============================================="
    echo ""
    echo "  1) Reset and Recreate Schema"
    echo "  2) Reset and Recreate Schema (with Column Descriptions)"
    echo "  3) Apply Column Descriptions only"
    echo "  4) Insert Seed Data (RunSeeds)"
    echo "  5) Clear All Table Data (ClearSeeds)"
    echo "  6) Clear Data + Re-insert Seeds"
    echo ""
    echo "  Q) Quit"
    echo ""
    echo "----------------------------------------------"
    echo "  Scripts directory: $SCRIPT_DIR"
    echo "----------------------------------------------"
    echo ""
}

while true; do
    show_menu
    read -r -p "Select an option [1-6, Q]: " choice
    case "$choice" in
        1) reset_and_recreate ;;
        2) reset_and_recreate_with_descriptions ;;
        3) apply_column_descriptions ;;
        4) run_seeds ;;
        5) clear_data ;;
        6) clear_and_reinsert ;;
        q|Q) echo "Goodbye."; exit 0 ;;
        *) echo "Invalid option. Press Enter to continue..."; read -r ;;
    esac
    echo ""
    echo "Press Enter to return to the menu..."
    read -r
done