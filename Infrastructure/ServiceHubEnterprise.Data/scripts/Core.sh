#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="../CoreManagement"

# Step 1: Execute scaffolding using CLI parameters
dotnet linq2db scaffold \
  --provider SQLServer \
  --connection "Data Source=localhost,1433;Initial Catalog=OrbitTool;User ID=sa;Password=root@1234;Encrypt=True;TrustServerCertificate=True;Command Timeout=30" \
  --output "$OUTPUT_DIR" \
  --overwrite \
  --include-tables GlobalSettings,UserSettings \
  --namespace ServiceHubEnterprise.Data.CoreManagement \
  --context-name CoreDbContext \
  --add-typed-options-ctor \
  --partial-entities

# Step 2: Split scaffolder's aligned "[Column(...)] public ... { get; set; }" one-liners
# into separate attribute/property lines, and convert to a file-scoped namespace
# (dotnet format's IDE0161 analyzer is unreliable to invoke here, so both are done directly)
python3 "$SCRIPT_DIR/format-entities.py" "$OUTPUT_DIR"

# Step 3: Normalize whitespace/indentation after the line splitting
dotnet format whitespace ..