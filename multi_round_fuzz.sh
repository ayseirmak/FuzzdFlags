#!/bin/bash

# This script will run 24_fuzz.sh five times in a row (5 rounds).
# Usage:
#   ./multi_round_fuzz.sh <input_folder> <output_folder> <configuration> <target>
#
# Where:
#   <input_folder>  = e.g. /users/user42/input-seeds
#   <output_folder> = e.g. /users/user42/output-afl
#   <configuration> = any custom tag you use for the fuzz run
#   <target>        = clang or clang-options (whatever your 24_fuzz.sh expects)
#

# Number of rounds
NUM_ROUNDS=8

INPUT="$1"
OUTPUT="$2"
CONFIG="$3"
TARGET="$4"

if [ $# -lt 4 ]; then
    echo "Usage: $0 <input_folder> <output_folder> <configuration> <target>"
    exit 1
fi

for (( i=2; i<=$NUM_ROUNDS; i++ ))
do
  echo "=== Starting Round $i of $NUM_ROUNDS ==="
  # Call your existing 24_fuzz.sh script
  # Arguments to 24_fuzz.sh are: input output round configuration target
  ./24_fuzz.sh "$INPUT" "$OUTPUT" "$i" "$CONFIG" "$TARGET"

  echo "=== Finished Round $i ==="
  echo
done

echo "All $NUM_ROUNDS rounds completed."

