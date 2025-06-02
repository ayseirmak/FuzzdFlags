#!/bin/bash
working_folder=$1       ## base folder
TMP_SOURCE_FOLDER=$2    ## Input from 0- script
i=$3         		## Which copy?

### Create a working folder with LLVM source
rm -rf $workingColder/llvm-clang-$i               		## Remove the old version
mkdir $working_folder/llvm-clang-$i                		## Create a new version
cp -rf $TMP_SOURCE_FOLDER/* $working_folder/llvm-clang-$i	## Copy the data from the temp download folder

### Update clang settings
cd $working_folder/llvm-clang-$i
echo $working_folder/llvm-clang-$i"/llvm-install/usr/local/bin/clang" > ./compiler_test.in

timeB=$(date +"%T")
echo ">> Start Script with GCC-11 <$timeB>"

## Save information regarding the version and how we compile it
mkdir compilation_info
echo " - date: $(date '+%Y-%m-%d at %H:%M.%S')" > $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt
echo " - host name $(hostname -f)" >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt
echo " - current path: $(pwd)" >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt
echo " - current path: $(pwd)" >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt
gcc-11 --version >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt; g++-11 --version >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt; gcov-11 --version >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt; cpp-11 --version >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt; /usr/bin/cc --version >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt; /usr/bin/c++ --version >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt 

### LLVM PART: with instrumentation
# Setting the env. + cov.
echo "Start build in: $working_folder"
{
	mkdir llvm-build llvm-install
	cd ./llvm-build

	set CFLAGS='--coverage -ftest-coverage -fprofile-arcs -fno-inline'
	set CXXFLAGS='--coverage -ftest-coverage -fprofile-arcs -fno-inline'
	set LDFLAGS='-lgcov --coverage -ftest-coverage -fprofile-arcs'
	set CXX=g++-11
	set CC=gcc-11

	# Cmake and build of LLVM
	timeS=$(date +"%T")
	echo "Configuration: cmake -G Ninja -Wall ../llvm-project/llvm/  <$timeS>" >> $working_folder/llvm-clang-$i/compilation_info/llvm-version.txt

	cmake -G Ninja -Wall ../llvm-project/llvm/ -DLLVM_ENABLE_PROJECTS='clang;compiler-rt' -DLLVM_USE_SANITIZER="" -DCMAKE_C_COMPILER=gcc-11 -DCMAKE_CXX_COMPILER=g++-11 -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_INCLUDE_TESTS="OFF" -DLLVM_INCLUDE_DOCS="OFF" -DLLVM_INCLUDE_BENCHMARKS="OFF" -DLLVM_BUILD_EXAMPLES="OFF" -DLLVM_BUILD_TESTS="OFF" -DLLVM_BUILD_DOCS="OFF" -DCMAKE_C_FLAGS="--coverage" -DCMAKE_CXX_FLAGS="--coverage" -DCMAKE_EXE_LINKER_FLAGS="--coverage" -Wno-dev > $working_folder/llvm-clang-$i/compilation_info/config_output.txt 2>&1

	# Build the compiler
	timeB=$(date +"%T")
	echo ">> Build LLVM with ninja to ./llvm-build <$timeB>"
	ninja > $working_folder/llvm-clang-$i/compilation_info/build_output.txt 2>&1
	ninja check-clang >> $working_folder/llvm-clang-$i/compilation_info/build_output.txt 2>&1
	grep "FAILED:" $working_folder/llvm-clang-$i/compilation_info/build_output.txt

	# Install compiler locally
	timeI=$(date +"%T")
	echo ">> Install LLVM locally with ninja to ./llvm-install <$timeI>"
	DESTDIR=../llvm-install ninja install -k 10 > $working_folder/llvm-clang-$i/compilation_info/install_output.txt 2>&1
	grep "FAILED:" $working_folder/llvm-clang-$i/compilation_info/install_output.txt

	# Cleaning after build
	unset CFLAGS
	unset CXXFLAGS
	unset LDFLAGS
	unset CXX
	unset CC
}
timeEND=$(date +"%T")
cd $working_folder
tar -czvf llvm-clang-$i.tar.gz llvm-clang-$i/ >> $working_folder/llvm-clang-$i/compilation_info/install_output.txt 2>&1
echo ">> Create .tar of LLVM local installation <$timeEND>"