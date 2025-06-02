#!/bin/bash
# decrypt_queue.sh
#
# Usage:
#   ./decrypt_queue.sh <queue_directory> <output_file.txt>
#
# This script iterates over the AFL queue files (mutated binary seed files),
# runs clang-options with --filebin and --checker to extract the decrypted content,
# and appends the output to a single text file.

# Check for correct usage
if [ $# -ne 2 ]; then
    echo "Usage: $0 <queue_directory> <output_file.txt>"
    exit 1
fi

QUEUE_DIR="$1"
OUTPUT_FILE="$2"

# Verify the queue directory exists
if [ ! -d "$QUEUE_DIR" ]; then
    echo "Error: Queue directory '$QUEUE_DIR' does not exist."
    exit 1
fi

# Clear the output file (or create it if it doesn't exist)
> "$OUTPUT_FILE"

echo "Processing AFL queue files in '$QUEUE_DIR'..." | tee -a "$OUTPUT_FILE"

# Iterate over all files in the queue directory
for file in "$QUEUE_DIR"/*; do
    if [ -f "$file" ]; then
        echo "----------------------------------------" | tee -a "$OUTPUT_FILE"
        echo "File: $file" | tee -a "$OUTPUT_FILE"
        # Run clang-options to "decrypt" the binary file.
        # This should print the fixed flags, mutated flags, and source info.
        result=$(~/build/bin/clang-options --filebin "$file" --checker)
        echo "$result" | tee -a "$OUTPUT_FILE"
    fi
done

echo "Decryption complete. Results saved in '$OUTPUT_FILE'."
