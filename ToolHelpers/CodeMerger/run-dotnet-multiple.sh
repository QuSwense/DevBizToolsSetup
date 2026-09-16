#!/bin/bash

# -------------------------------
# DYNAMIC BASE PATHS
# This script lives in <repo-root>/ToolHelpers/CodeMerger, so the repo root
# is two levels up from the script's location.
# -------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_PATH="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MERGED_ROOT="${SCRIPT_DIR}/MergedCode"

# -------------------------------
# LIST OF SOURCE PROJECT FOLDERS (Relative paths)
# -------------------------------
SOURCE_FOLDERS=(
    "Backend/PdfProcessorLibrary/OrbitHub.PdfProcessor"
    "Backend/PdfProcessorLibrary/PdfProcessor.TestRunner"
    "Backend/SoapEngineLibrary/OrbitHub.SoapEngine"
    "Backend/RuleEngineLibrary/OrbitHub.RuleEngine"
    "WebApp/OrbitHub.Web"
)

# -------------------------------
# LIST OF SQL SCRIPT FOLDERS (Relative paths)
# 👉 Update these paths to where your .sql scripts live
# -------------------------------
SQL_SOURCE_FOLDERS=(
    "OrbitToolDatabase/dbo"
    "OrbitToolDatabase/dbo/Tables"
    "OrbitToolDatabase/dbo/StoredProcedures"
    "OrbitToolDatabase/dbo/Views"
)

# -------------------------------
# FUNCTIONS
# -------------------------------
run_dotnet_for() {
    local src_path="$1"
    local src_full="${BASE_PATH}/${src_path}"
    local folder_name="$(basename "$src_full")"
    local out_dir="$MERGED_ROOT/$folder_name"
    local out_file="$out_dir/${folder_name}.cs"

    mkdir -p "$out_dir"

    echo "======================================"
    echo "Processing: $src_path"
    echo "Full Path:  $src_full"
    echo "Output:     $out_file"
    echo "--------------------------------------"

    dotnet run -- "$src_full" "$out_file"

    if [ $? -eq 0 ]; then
        echo "✅ Success for $src_path"
    else
        echo "❌ Failed for $src_path"
    fi
    echo ""
}

run_sql_for() {
    local src_path="$1"
    local src_full="${BASE_PATH}/${src_path}"
    local folder_name="$(basename "$src_full")"
    local out_dir="$MERGED_ROOT/$folder_name"
    local out_file="$out_dir/${folder_name}.sql"

    mkdir -p "$out_dir"

    echo "======================================"
    echo "Minifying SQL: $src_path"
    echo "Full Path:     $src_full"
    echo "Output Dir:    $out_dir"
    echo "--------------------------------------"

    dotnet run -- sql "$src_full" "$out_file"

    if [ $? -eq 0 ]; then
        echo "✅ Success for $src_path"
    else
        echo "❌ Failed for $src_path"
    fi
    echo ""
}

# -------------------------------
# MAIN LOOP
# -------------------------------
if ! command -v dotnet &> /dev/null; then
    echo "Error: 'dotnet' command not found. Please install .NET SDK."
    exit 1
fi

echo "Processing projects in: $BASE_PATH"
echo "Output directory: $MERGED_ROOT"
echo ""

for folder in "${SOURCE_FOLDERS[@]}"; do
    run_dotnet_for "$folder"
done

for folder in "${SQL_SOURCE_FOLDERS[@]}"; do
    run_sql_for "$folder"
done

echo "All done."