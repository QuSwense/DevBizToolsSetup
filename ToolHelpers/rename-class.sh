#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <OldClassName> <NewClassName>"
  exit 1
fi

OLD_NAME="$1"
NEW_NAME="$2"

echo "=== 1. Checking occurrences before replacement ==="
grep -rnw --exclude-dir={bin,obj,.git} . -e "$OLD_NAME" || { echo "No references found to $OLD_NAME!"; }

echo "=== 2. Replacing references inside files ==="
# -exec perl directly edits each file without subshell piping issues
find . -type f -name "*.cs" \
  -not -path "*/bin/*" \
  -not -path "*/obj/*" \
  -not -path "*/.git/*" \
  -exec perl -pi -e "s/\b${OLD_NAME}\b/${NEW_NAME}/g" {} +

echo "=== 3. Renaming the physical file(s) ==="
find . -type f -name "${OLD_NAME}.cs" \
  -not -path "*/bin/*" \
  -not -path "*/obj/*" \
  -not -path "*/.git/*" | while IFS= read -r file; do
    dir=$(dirname "$file")
    new_file="${dir}/${NEW_NAME}.cs"
    
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git mv "$file" "$new_file"
    else
      mv "$file" "$new_file"
    fi
    echo "Renamed: $file -> $new_file"
done

echo "=== 4. Checking remaining occurrences ==="
REMAINING=$(grep -rnw --exclude-dir={bin,obj,.git} . -e "$OLD_NAME" | wc -l || true)
if [ "$REMAINING" -eq 0 ]; then
  echo "All occurrences of '$OLD_NAME' were successfully replaced!"
else
  echo "Warning: $REMAINING occurrences of '$OLD_NAME' still remain:"
  grep -rnw --exclude-dir={bin,obj,.git} . -e "$OLD_NAME"
fi

# echo "=== 5. Verifying solution build ==="
# dotnet build