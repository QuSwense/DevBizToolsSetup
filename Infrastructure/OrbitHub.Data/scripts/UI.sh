#!/usr/bin/env bash
set -euo pipefail

# NOTE: No SQL tables for UI management currently exist in OrbitToolDatabase/dbo.
# This script is a stub for future UI tables.
# When the SQL tables are added, update --include-tables accordingly.

echo "WARNING: UI.sh — no UI tables (UIPages, UIActions, PermissionToUIPageMapping) found in OrbitToolDatabase/dbo. Skipping scaffold."
echo "Add those tables to OrbitToolDatabase/dbo/Tables/ first, then uncomment the scaffold block below."

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LINQ2DB_COMPONENT_PRJ_PATH="$SCRIPT_DIR/../../linq2db-doccomments"
# LINQ2DB_COMPONENT_PATH="$LINQ2DB_COMPONENT_PRJ_PATH/bin/Debug/net10.0/DocIntercept.dll"
# OUTPUT_DIR="../UIManagement"
#
# APPSETTINGS_DEV="$(cd "$SCRIPT_DIR/../../.." && pwd)/WebApp/OrbitHub.Web/appsettings.Development.json"
#
# dotnet build "$LINQ2DB_COMPONENT_PRJ_PATH/DocIntercept.csproj" -v q -nologo
#
# CONNECTION_STRING="$(dotnet "$LINQ2DB_COMPONENT_PATH" connection-string "$APPSETTINGS_DEV")"
#
# dotnet linq2db scaffold \
#   --provider SQLServer \
#   --connection "$CONNECTION_STRING" \
#   --output "$OUTPUT_DIR" \
#   --overwrite \
#   --objects table,foreign-key \
#   --include-tables UIPages,UIActions,PermissionToUIPageMapping \
#   --namespace OrbitHub.Data.UIManagement \
#   --context-name UiDbContext \
#   --add-typed-options-ctor \
#   --partial-entities \
#   --customize "$LINQ2DB_COMPONENT_PATH"
#
# dotnet "$LINQ2DB_COMPONENT_PATH" format "$OUTPUT_DIR"
# dotnet format whitespace ..
