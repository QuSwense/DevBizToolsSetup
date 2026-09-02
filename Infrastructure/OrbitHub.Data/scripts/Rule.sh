#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINQ2DB_COMPONENT_PRJ_PATH="$SCRIPT_DIR/../../linq2db-doccomments"
LINQ2DB_COMPONENT_PATH="$LINQ2DB_COMPONENT_PRJ_PATH/bin/Debug/net10.0/DocIntercept.dll"
OUTPUT_DIR="../RuleManagement"

# Read the default connection string from WebApp appsettings.Development.json
# (ConnectionStrings:DefaultConnection) so scaffolding targets the same DB as the app.
APPSETTINGS_DEV="$(cd "$SCRIPT_DIR/../../.." && pwd)/WebApp/OrbitHub.Web/appsettings.Development.json"

# Step 0: Build the MS_Description -> <summary> doc-comment interceptor + formatter CLI
# (see linq2db-doccomments/DescriptionInterceptors.cs and linq2db-doccomments/Formatting/*)
dotnet build "$LINQ2DB_COMPONENT_PRJ_PATH/DocIntercept.csproj" -v q -nologo

CONNECTION_STRING="$(dotnet "$LINQ2DB_COMPONENT_PATH" connection-string "$APPSETTINGS_DEV")"

# Step 1: Execute scaffolding using CLI parameters
dotnet linq2db scaffold \
  --provider SQLServer \
  --connection "$CONNECTION_STRING" \
  --output "$OUTPUT_DIR" \
  --overwrite \
  --objects table,foreign-key \
  --include-tables RuleContextObjects,RuleSets,RuleSetContextObjectLinks,RuleExecutionLogs \
  --namespace OrbitHub.Data.RuleManagement \
  --context-name RuleDbContext \
  --add-typed-options-ctor \
  --partial-entities \
  --customize "$LINQ2DB_COMPONENT_PATH"

# Step 2: Post-process scaffold output (replaces format-entities.py): splits
# "[Column(...)] public ..." one-liners, squeezes alignment padding, converts to
# a file-scoped namespace and adds blank lines between members. Rules are
# configured by Formatting/ScaffoldFormatOptions + DocIntercept.settings.json.
dotnet "$LINQ2DB_COMPONENT_PATH" format "$OUTPUT_DIR"

# Step 3: Normalize whitespace/indentation after the line splitting
dotnet format whitespace ..