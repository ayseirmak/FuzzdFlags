#!/usr/bin/env bash

# Set location to record the data
working_folder=$1 # "/users/user42/coverage/llvm-clang-1"
testcaseDir=$2
itr=0
compilerInfo=$3 # "/users/user42/coverage/llvm-clang-1/llvm-install/usr/local/bin/clang"
opt=$4 # "-O2"
old_version=0
compiler_build="llvm-build"
gfauto="/users/user42/graphicsfuzz/gfauto"

# Directory where the .gcda files will be collected
gcda_dir="$working_folder/coverage_gcda_files/application_run"
cov_dir="$working_folder/coverage_processed"
rm -rf "$gcda_dir"
rm -rf "$cov_dir"
mkdir -p "$gcda_dir"


time2=$(date +"%T")
echo "--> COMPILING "$testcaseDir" ITERATION "$itr" with compiler info. "$compilerInfo" ("$time2")"

# Run compiler and save coverage data
export GCOV_PREFIX=$working_folder/coverage_gcda_files/application_run
compile_line_lib_default="-c -fpermissive -w -Wno-implicit-function-declaration -Wno-return-type -Wno-builtin-redeclared -Wno-implicit-int -Wno-int-conversion -march=x86-64-v2 -I/usr/include -I/users/user42/llvmSS-include"
echo "Folder: $testcaseDir"
for testcaseFile in $testcaseDir/* ; do
	compiler_flag="$opt"
	is_math=`grep "math.h" $testcaseFile | wc -l`
	if [[ $is_math -gt 0 ]]; then
		compiler_flag=""$opt" -lm"
	fi
	
	## Compile the test-case
	if [[ "$testcaseFile" == *".c" ]] ; then
		echo "--> PERFORMING (*.c)  <(ulimit -St 500; ${compilerInfo} $testcaseFile $compiler_flag) > basic_output_baseline.txt 2>&1>"
		(ulimit -St 500; ${compilerInfo} ${compile_line_lib_default} $testcaseFile $compiler_flag) > "basic_output_baseline.txt" 2>&1
	else
		echo "--> PERFORMING (missing *.c) <(ulimit -St 500; ${compilerInfo} $testcaseFile $compiler_flag) > basic_output_baseline.txt 2>&1>"
		mv "$testcaseFile" "$testcaseFile".c
		(ulimit -St 500; ${compilerInfo} ${compile_line_lib_default} $testcaseFile.c $compiler_flag) > "basic_output_baseline.txt" 2>&1
	fi
done
unset GCOV_PREFIX

## Measure Coverage
time3=$(date +"%T")
echo "--> MEASURING COVERAGE... ("$time3")"
mkdir -p $cov_dir/x-$itr
mkdir -p $cov_dir/x-line-$itr
(
	source $gfauto/.venv/bin/activate
	
	## Function coverage
	cd $cov_dir/x-$itr
	if [ "$old_version" == "1" ]; then
		gfauto_cov_from_gcov --out run_gcov2cov.cov $working_folder/$compiler_build/ $working_folder/coverage_gcda_files/application_run/ --num_threads 20 --gcov_uses_json --gcov_functions >> gfauto.log 2>&1
	else
		echo "gfauto_cov_from_gcov --out run_gcov2cov.cov $working_folder/$compiler_build/ --gcov_prefix_dir $working_folder/coverage_gcda_files/application_run/ --num_threads 20 --gcov_uses_json --gcov_functions >> gfauto.log 2>&1"
		gfauto_cov_from_gcov --out run_gcov2cov.cov $working_folder/$compiler_build/ --gcov_prefix_dir $working_folder/coverage_gcda_files/application_run/ --num_threads 20 --gcov_uses_json --gcov_functions >> gfauto.log 2>&1
	fi
        gfauto_cov_to_source --coverage_out cov.out --cov run_gcov2cov.cov $working_folder/$compiler_build/ >> gfauto.log 2>&1
        
        ## Line coverage
        cd $cov_dir/x-line-$itr
        if [ "$old_version" == "1" ]; then
        	gfauto_cov_from_gcov --out run_gcov2cov.cov $working_folder/$compiler_build/ $working_folder/coverage_gcda_files/application_run/ --num_threads 20 --gcov_uses_json >> gfauto.log 2>&1
        else
		echo "gfauto_cov_from_gcov --out run_gcov2cov.cov $working_folder/$compiler_build/ --gcov_prefix_dir $working_folder/coverage_gcda_files/application_run/ --num_threads 20 --gcov_uses_json >> gfauto.log 2>&1"
        	gfauto_cov_from_gcov --out run_gcov2cov.cov $working_folder/$compiler_build/ --gcov_prefix_dir $working_folder/coverage_gcda_files/application_run/ --num_threads 20 --gcov_uses_json >> gfauto.log 2>&1
        fi
        gfauto_cov_to_source --coverage_out cov.out --cov run_gcov2cov.cov $working_folder/$compiler_build/ >> gfauto.log 2>&1
        ls -l
)
