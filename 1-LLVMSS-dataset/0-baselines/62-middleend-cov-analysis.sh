#!/usr/bin/env bash

working_folder=$1
LOGFILE="middleend_coverage_analysis.log"

# Redirect all standard output and error to the log file.
exec > "$working_folder/$LOGFILE" 2>&1

echo "===== STARTING SCRIPT at $(date) ====="

CSV_FILE="$working_folder/table__all_1_0.csv"

declare -a GROUP_PATTERNS=(
  "clang/lib/Analysis/"
  "llvm/lib/Analysis/"
  "llvm/lib/BinaryFormat/"
  "llvm/lib/DebugInfo/"
  "llvm/lib/IR/"
  "llvm/lib/IRReader/"
  "llvm/lib/Object/"
  "llvm/lib/ObjectYAML/"
  "llvm/lib/Passes/"
  "llvm/lib/Support/"
  "llvm/lib/Transforms/"
)

TMP_CSV=$(mktemp -p "$working_folder" tmp.XXXXXX)

tail -n +2 "$CSV_FILE" > "$TMP_CSV"

for pattern in "${GROUP_PATTERNS[@]}"; do
  group_rows=$(grep "$pattern" "$TMP_CSV" || true)
  if [[ -z "$group_rows" ]]; then
    continue  
  fi

  group_sum=$(echo "$group_rows" | cut -d',' -f3 | awk '{ s += $1 } END { print s }')
  echo "$pattern $group_sum"
  echo "$group_rows" | while IFS= read -r line; do
      file_path=$(echo "$line" | cut -d',' -f1)
      coverage=$(echo "$line" | cut -d',' -f3)
      if [ "$coverage" != "0" ]; then
          file_name=$(basename "$file_path")
          echo "  $file_name $coverage"
      fi
  done
  echo ""
done
rm "$TMP_CSV"
echo "===== FINISHED SCRIPT at $(date) ====="

