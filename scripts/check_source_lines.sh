#!/usr/bin/env bash
# Enforce the 100-line limit on ALL Swift source files in the app target.
# Long files hide too many responsibilities: Views only render, logic belongs in
# ViewModels / Stores / Services / parsers. Over the limit → extract a helper or
# split the file. Generated files are exempt (mechanically produced, not edited).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

MAX=100
FAILED=0
echo "Checking Swift source files for line count > $MAX..."

while IFS= read -r file; do
  case "$file" in
    *.generated.swift) continue ;;   # mechanically generated, not hand-edited
  esac
  LINES=$(wc -l < "$file" | tr -d ' ')
  if [ "$LINES" -gt "$MAX" ]; then
    echo "❌ ${file#./}: $LINES lines (max $MAX)"
    FAILED=1
  fi
done < <(find Telly -name "*.swift")

if [ "$FAILED" -eq 1 ]; then
  echo ""
  echo "Source files must be ≤ $MAX lines. Extract logic into a helper, a"
  echo "ViewModel/Store/Service, or split large views into subview files."
  echo "Never raise the limit — fix the code, not the gate."
  exit 1
fi
echo "✅ All source files ≤ $MAX lines"
