#!/usr/bin/env bash
set -euo pipefail

fileO="$1"
file1="$2"

file1_ln=$(wc -l <"$file1")
file1_cov_any=$(awk '$2>0 {c++} END{print c+0}' "$file1")

echo ">> $fileO,$file1_ln,$file1_cov_any"
