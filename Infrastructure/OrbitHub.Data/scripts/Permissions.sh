#!/usr/bin/env bash
set -euo pipefail

# NOTE: No SQL tables for Permissions currently exist in OrbitToolDatabase/dbo.
# This script is a stub for future permissions tables.
# When the SQL tables are added, update --include-tables accordingly.

echo "WARNING: Permissions.sh — no Permissions tables found in OrbitToolDatabase/dbo. Skipping scaffold."
echo "Expected future tables: ResourcePermissions, RolePermissions, Roles, RuleSetsPermissions, ServiceAppPermissions,"
echo "  ServiceRequestFilesPermissions, ServiceTestCasesPermissions, ServiceTestSuitesPermissions, UserPermissions"
echo "Add those tables to OrbitToolDatabase/dbo/Tables/ first, then uncomment the scaffold block below."

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LINQ2DB_COMPONENT_PRJ_PATH="$SCRIPT_DIR/../../linq2db-doccomments"
# LINQ2DB_COMPONENT_PATH="$LINQ2DB_COMPONENT_PRJ_PATH/bin/Debug/net10.0/DocIntercept.dll"
# OUTPUT_DIR="../PermissionsManagement"
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
#   --include-tables ResourcePermissions,RolePermissions,Roles,RuleSetsPermissions,ServiceAppPermissions,ServiceRequestFilesPermissions,ServiceTestCasesPermissions,ServiceTestSuitesPermissions,UserPermissions \
#   --namespace OrbitHub.Data.PermissionsManagement \
#   --context-name PermissionsDbContext \
#   --add-typed-options-ctor \
#   --partial-entities \
#   --customize "$LINQ2DB_COMPONENT_PATH"
#
# dotnet "$LINQ2DB_COMPONENT_PATH" format "$OUTPUT_DIR"
# dotnet format whitespace ..
