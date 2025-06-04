#!/bin/bash
################################################
# This script reads fuzz queue text files from a given directory.
# Each text file contains multiple records separated by 
# "----------------------------------------". Each record includes:
#
#   [Checker] Source File: <source_file>
#   [Checker] Flags: <fuzz_flags>
#
# (Since the fixed flags are constant, they are provided manually.)
#
# The script uses a coverage-instrumented Clang to compile each
# source file, storing the generated .gcda files in a designated 
# directory (using GCOV_PREFIX). Then, it uses gfauto_cov_from_gcov 
# along with gfauto_cov_to_source to compute both function-level and
# line-level coverage. The coverage results for each fuzz queue file
# are stored in separate subdirectories.
#
# RUNNING:
#   ./33-gfauto.sh /path/to/fuzzQueueDir
#
# Example:
#   Files in fuzzQueueDir: m1-fuzz01-queue, m1-fuzz02-queue, etc.
################################################

# Parameter: Directory containing fuzz queue text files
fuzzQueueDir="$1"
if [ -z "$fuzzQueueDir" ]; then
  echo "Usage: $0 /path/to/fuzzQueueDir"
  exit 1
fi
working_folder=$2 # "/users/user42/coverage/llvm-clang-1"


# Constant variables (modify as needed)
itr=1
gfauto="/users/user42/graphicsfuzz/gfauto"    # gfauto directory
compiler="llvm"   # expecting LLVM (alternatively 'gcc' if needed)
old_version=0     # use 0 for new gfauto style

compiler_build="llvm-build"  # path to the compiler
configuration_location="$working_folder/compiler_test.in"  # configuration file containing the compiler command
compile_line_lib_default="-c -o /dev/null -fpermissive -w -Wno-implicit-function-declaration -Wno-return-type -Wno-builtin-redeclared -Wno-implicit-int -Wno-int-conversion -march=x86-64-v2 -I/usr/include -I/users/user42/llvmSS-include"

# Get compiler command from the configuration file (first line)
compilerInfo=$(head -1 "$configuration_location")
if [ -z "$compilerInfo" ]; then
  echo "Compiler info is not inside $configuration_location!"
  exit 1
fi

# Directory where the .gcda files will be collected
gcda_dir="$working_folder/coverage_gcda_files/application_run"
cov_dir="$working_folder/coverage_processed"

rm -rf "$cov_dir"
rm -rf "$gcda_dir"
mkdir -p "$gcda_dir"

current_folder=$(pwd)

# Process each fuzz queue text file
for queueFile in "$fuzzQueueDir"/*; do
  repetition=$(basename "$queueFile")     # e.g., m1-fuzz01-queue
  echo "=== PROCESSING: $repetition ==="
  
  # Create separate coverage result directories for this repetition:
  repetition_func_dir="$working_folder/coverage_processed/$repetition/function"
  repetition_line_dir="$working_folder/coverage_processed/$repetition/line"
  mkdir -p "$repetition_func_dir"
  mkdir -p "$repetition_line_dir"
  
  # Clean the GCDA directory for this repetition
  rm -rf "$gcda_dir"
  mkdir -p "$gcda_dir"

  awk -v RS="----------------------------------------" 'NF { 
  print $0 "\0"
  }' "$queueFile" | while IFS= read -r -d $'\0' record; do

   
    if [ -z "$record" ]; then
      continue
    fi

    # Remove any carriage returns (if needed)
    record_clean=$(echo "$record" | tr -d '\r')
    
    # Extract the source file, fixed flags, and fuzz flags from the record
    src_line=$(echo "$record_clean" | grep "\[Checker\] Source File:")
    flags_line=$(echo "$record_clean" | grep "\[Checker\] Flags:")

    # Skip record if no source file line is found
    if [ -z "$src_line" ]; then
      continue
    fi

    SOURCE_FILE=$(echo "$src_line" | sed 's/^.*\[Checker\] Source File:[[:space:]]*//')
    FUZZED_FLAGS=$(echo "$flags_line" | sed 's/^.*\[Checker\] Flags:[[:space:]]*//')

    echo "SOURCE FILE: $SOURCE_FILE"
    echo "FLAGS: $FUZZED_FLAGS"
    
    compiler_flag="$FUZZED_FLAGS"
    compiler_flag="$compiler_flag -lm"


    # Set GCOV_PREFIX so that .gcda files are written to gcda_dir
    export GCOV_PREFIX="$gcda_dir"

    # Execute the compile command with a CPU time limit of 500 seconds.
    # The command is: [compilerInfo] [compile_line_lib_default] [SOURCE_FILE] [compiler_flag]
    echo "--> Executing: (ulimit -St 500; $compilerInfo $compile_line_lib_default $SOURCE_FILE $compiler_flag)"
    (ulimit -St 500; $compilerInfo $compile_line_lib_default "$SOURCE_FILE" $compiler_flag) > basic_output.txt 2>&1

    unset GCOV_PREFIX
  done
  

  # After processing all records in the queue file, run gfauto to measure coverage.
  echo "--> Coverage measurement for $repetition started..."
  (
    source "$gfauto/.venv/bin/activate"
    
    # Function-level Coverage:
    cd "$repetition_func_dir"
    if [ "$old_version" == "1" ]; then
      gfauto_cov_from_gcov --out run_gcov2cov.cov "$working_folder/$compiler_build/" "$gcda_dir" --num_threads 20 --gcov_uses_json --gcov_functions >> gfauto.log 2>&1
    else
      echo "[FUNCTION] gfauto_cov_from_gcov --out run_gcov2cov.cov $working_folder/$compiler_build/ --gcov_prefix_dir $gcda_dir --num_threads 20 --gcov_uses_json --gcov_functions"
      gfauto_cov_from_gcov --out run_gcov2cov.cov "$working_folder/$compiler_build/" --gcov_prefix_dir "$gcda_dir" --num_threads 20 --gcov_uses_json --gcov_functions >> gfauto.log 2>&1
    fi
    gfauto_cov_to_source --coverage_out cov.out --cov run_gcov2cov.cov "$working_folder/$compiler_build/" >> gfauto.log 2>&1
    
    # Line-level Coverage:
    cd "$repetition_line_dir"
    if [ "$old_version" == "1" ]; then
      gfauto_cov_from_gcov --out run_gcov2cov.cov "$working_folder/$compiler_build/" "$gcda_dir" --num_threads 20 --gcov_uses_json >> gfauto.log 2>&1
    else
      echo "[LINE] gfauto_cov_from_gcov --out run_gcov2cov.cov $working_folder/$compiler_build/ --gcov_prefix_dir $gcda_dir --num_threads 20 --gcov_uses_json"
      gfauto_cov_from_gcov --out run_gcov2cov.cov "$working_folder/$compiler_build/" --gcov_prefix_dir "$gcda_dir" --num_threads 20 --gcov_uses_json >> gfauto.log 2>&1
    fi
    gfauto_cov_to_source --coverage_out cov.out --cov run_gcov2cov.cov "$working_folder/$compiler_build/" >> gfauto.log 2>&1

    ls -l
  )
  
  # Cleanup temporary files
  rm -f a.out basic_output.txt

  echo "=== Coverage measurement for $repetition finalized..."
  echo "    Function coverage found in: $repetition_func_dir"
  echo "    Line coverage found in:     $repetition_line_dir"
done

cd "$current_folder"
echo "ALL COVERAGE PROCESS DONE."
