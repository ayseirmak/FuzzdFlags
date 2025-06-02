#!/usr/bin/env bash
fuzzDir="$1"
if [ -z "$fuzzDir" ]; then
  echo "Usage: $0 /path/to/fuzzDir"
  exit 1
fi
working_folder=$2 # "/users/user42/coverage/llvm-clang-1"
opt=$3 # "-O2"
# Constant variables (modify as needed)
itr=1
gfauto="/users/user42/graphicsfuzz/gfauto"    # gfauto directory
compiler="llvm"   # expecting LLVM (alternatively 'gcc' if needed)
old_version=0     # use 0 for new gfauto style

compiler_build="llvm-build"  # path to the compiler
configuration_location="$working_folder/compiler_test.in"  # configuration file containing the compiler command
compile_line_lib_default="-c -fpermissive -w -Wno-implicit-function-declaration -Wno-return-type -Wno-builtin-redeclared -Wno-implicit-int -Wno-int-conversion -march=x86-64-v2 -I/usr/include -I/users/user42/llvmSS-include"

# Get compiler command from the configuration file (first line)
compilerInfo=$(head -1 "$configuration_location")
if [ -z "$compilerInfo" ]; then
  echo "Compiler info is not inside $configuration_location!"
  exit 1
fi

# Directory where the .gcda files will be collected
gcda_dir="$working_folder/coverage_gcda_files/application_run"
rm -rf "$gcda_dir"
mkdir -p "$gcda_dir"

current_folder=$(pwd)

# Process each fuzz queue file
for queueFolder in "$fuzzDir"/fuzz*; do  
  repetition=$(basename "$queueFolder")     # e.g., fuzz01
  echo "=== PROCESSING: $repetition ==="
  
  # Create separate coverage result directories for this repetition:
  repetition_func_dir="$working_folder/coverage_processed/$repetition/function"
  repetition_line_dir="$working_folder/coverage_processed/$repetition/line"
  mkdir -p "$repetition_func_dir"
  mkdir -p "$repetition_line_dir"
  
  # Clean the GCDA directory for this repetition
  rm -rf "$gcda_dir"
  mkdir -p "$gcda_dir"

  for testcaseFile in "$queueFolder"/default/queue/*; do
    compiler_flag=""$opt" -lm"
    export GCOV_PREFIX="$gcda_dir"
    ## Compile the test-case
	if [[ "$testcaseFile" == *".c" ]] ; then
		echo "--> PERFORMING (*.c)  <(ulimit -St 500; ${compilerInfo} $testcaseFile $compiler_flag) > basic_output_line.txt 2>&1>"
		(ulimit -St 500; ${compilerInfo} ${compile_line_lib_default} $testcaseFile $compiler_flag) > "basic_output_line.txt" 2>&1
	else
		echo "--> PERFORMING (missing *.c) <(ulimit -St 500; ${compilerInfo} $testcaseFile $compiler_flag) > basic_output_line.txt 2>&1>"
		mv "$testcaseFile" "$testcaseFile".c
		(ulimit -St 500; ${compilerInfo} ${compile_line_lib_default} $testcaseFile.c $compiler_flag) > "basic_output_line.txt" 2>&1
	fi
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
