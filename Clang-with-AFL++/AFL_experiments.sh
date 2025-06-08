### Experiment1  MAP_SIZE_POW2=23 AFL_MAP_SIZE=$((1<<23))  PCGUARD fuzzing
git clone https://github.com/AFLplusplus/AFLplusplus
cd AFLplusplus
AFL++ include/config.h MAP_SIZE_POW2=16 ~> MAP_SIZE_POW2=23
make distrib
sudo make install

cd ~
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout release/17.x
cd /users/user42/llvm-project/clang/tools
mkdir -p clang-options && cd clang-options
wget https://raw.githubusercontent.com/ayseirmak/FuzzdFlags/refs/heads/main/1-LLVMSS-dataset/2-fuzzdflags-options/CMakeLists.txt
wget https://raw.githubusercontent.com/ayseirmak/FuzzdFlags/refs/heads/main/1-LLVMSS-dataset/2-fuzzdflags-options/ClangOptions.cpp
nano ../CMakeLists.txt # After add_clang_subdirectory(clang-scan-deps) Add add_clang_subdirectory(clang-options)
 
# Create and enter a separate build directory
mkdir ~/build-alone
cd ~/build-alone
export AFL_MAP_SIZE=$((1<<23))
LD=/usr/local/bin/afl-clang-fast++ cmake -G Ninja -Wall ../llvm-project/llvm/ \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DLLVM_USE_SANITIZER=OFF \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_C_COMPILER=/usr/local/bin/afl-clang-fast \
  -DCMAKE_CXX_COMPILER=/usr/local/bin/afl-clang-fast++ \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_C_FLAGS="-pthread -L/usr/lib/x86_64-linux-gnu" \
  -DCMAKE_CXX_FLAGS="-pthread -L/usr/lib/x86_64-linux-gnu" \
  -DCMAKE_EXE_LINKER_FLAGS="-L/usr/lib/x86_64-linux-gnu" \
  -DLLVM_BUILD_DOCS="OFF"

# Build only clang 
ninja clang
ninja clang-options

## Experiment2 - MAP_SIZE_POW2=23 AFL_MAP_SIZE=$((1<<23)) AFL_LLVM_NGRAM_SIZE=8 NGRAM fuzzing
git clone https://github.com/AFLplusplus/AFLplusplus
cd AFLplusplus
AFL++ include/config.h MAP_SIZE_POW2=16 ~> MAP_SIZE_POW2=23
make distrib
sudo make install

cd ~
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout release/17.x
cd /users/user42/llvm-project/clang/tools
mkdir -p clang-options && cd clang-options
wget https://raw.githubusercontent.com/ayseirmak/FuzzdFlags/refs/heads/main/1-LLVMSS-dataset/2-fuzzdflags-options/CMakeLists.txt
wget https://raw.githubusercontent.com/ayseirmak/FuzzdFlags/refs/heads/main/1-LLVMSS-dataset/2-fuzzdflags-options/ClangOptions.cpp
nano ../CMakeLists.txt # After add_clang_subdirectory(clang-scan-deps) Add add_clang_subdirectory(clang-options)
 
# Create and enter a separate build directory
mkdir ~/build-ngram
cd ~/build-ngram
export AFL_MAP_SIZE=$((1<<23))
export AFL_LLVM_NGRAM_SIZE=8 
LD=/usr/local/bin/afl-clang-fast++ cmake -G Ninja -Wall ../llvm-project/llvm/ \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DLLVM_USE_SANITIZER=OFF \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_C_COMPILER=/usr/local/bin/afl-clang-fast \
  -DCMAKE_CXX_COMPILER=/usr/local/bin/afl-clang-fast++ \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_C_FLAGS="-pthread -L/usr/lib/x86_64-linux-gnu" \
  -DCMAKE_CXX_FLAGS="-pthread -L/usr/lib/x86_64-linux-gnu" \
  -DCMAKE_EXE_LINKER_FLAGS="-L/usr/lib/x86_64-linux-gnu" \
  -DLLVM_BUILD_DOCS="OFF"
  
# Build only clang 
ninja clang
ninja clang-options


### Experiment3 - LTO
# Create and enter a separate build directory
mkdir ~/build
cd ~/build

# Configure LLVM build to use AFL's clang-fast
LD=/usr/local/bin/afl-clang-lto++ CC=afl-clang-lto CXX=afl-clang-lto++ RANLIB=llvm-ranlib-14 AR=llvm-ar-14 AS=llvm-as-14 cmake -G Ninja -Wall ../llvm-project/llvm/ \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_C_COMPILER=/usr/local/bin/afl-clang-lto \
  -DCMAKE_CXX_COMPILER=/usr/local/bin/afl-clang-lto++ \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_C_FLAGS="-pthread -L/usr/lib/x86_64-linux-gnu" \
  -DCMAKE_CXX_FLAGS="-pthread -L/usr/lib/x86_64-linux-gnu" \
  -DCMAKE_EXE_LINKER_FLAGS="-L/usr/lib/x86_64-linux-gnu" \
  -DLLVM_BUILD_DOCS="OFF"


### Comparison of exp1 and exp2 
mkdir -p prog
cp -r build-alone prog
cp -r build-ngram prog
cp -r input-seeds(30seed) prog
mkdir -p prog/sync_dir

############  Terminal 1  →  MASTER (PCGUARD)  ############
AFL_USE_ASAN=0 AFL_SHUFFLE_QUEUE=1 AFL_NO_AFFINITY=1 \
AFL_SKIP_CPUFREQ=1 AFL_AUTORESUME=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \ 
afl-fuzz -i /users/user42/prog/input-seeds -o /users/user42/prog/sync_dir \
        -M pcguard_master -m none -t 500 -T 10 \
        -- /users/user42/prog/build-alone/bin/clang-options --filebin @@

############  Terminal 2  →  SLAVE  (N-gram 8) ############
AFL_USE_ASAN=0 AFL_SHUFFLE_QUEUE=1 AFL_NO_AFFINITY=1 \
AFL_SKIP_CPUFREQ=1 AFL_AUTORESUME=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \ 
afl-fuzz -i /users/user42/prog/input-seeds -o /users/user42/prog/sync_dir \
        -S ngram_slave  -m none -t 500 -T 10 \
        -- /users/user42/prog/build-ngram/bin/clang-options --filebin @@

### After 6 Hours exp1 and exp2 
afl-whatsup -d prog/sync_dir
/usr/local/bin/afl-whatsup status check tool for afl-fuzz by Michal Zalewski

Individual fuzzers
==================

>>> 10 instance: ngram_slave (0 days, 6 hrs) fuzzer PID: 3694353 <<<

  slow execution, 8 execs/sec
  last_find       : 54 seconds
  last_crash      : none seen yet
  last_hang       : none seen yet
  cycles_wo_finds : 0
  coverage        : 26.89%
  cpu usage 17.1%, memory usage 5.4%
  cycles 1, lifetime speed 8 execs/sec, items 6186/12102 (51%)
  pending 6261/12090, coverage 26.89%, no crashes yet

>>> 10 instance: pcguard_master (0 days, 6 hrs) fuzzer PID: 3694223 <<<

  slow execution, 10 execs/sec
  last_find       : 1 minutes, 31 seconds
  last_crash      : none seen yet
  last_hang       : none seen yet
  cycles_wo_finds : 0
  coverage        : 25.23%
  cpu usage 0.7%, memory usage 0.0%
  cycles 1, lifetime speed 10 execs/sec, items 1115/6897 (16%)
  pending 1299/6739, coverage 25.23%, no crashes yet

Summary stats
=============

        Fuzzers alive : 2
       Total run time : 12 hours, 50 minutes
          Total execs : 424 thousands
     Cumulative speed : 18 execs/sec
  Total average speed : 9 execs/sec
Current average speed : 26 execs/sec
        Pending items : 7560 faves, 18829 total
   Pending per fuzzer : 3780 faves, 9414 total (on average)
     Coverage reached : 26.89%
        Crashes saved : 0
          Hangs saved : 0
 Cycles without finds : 0/0
   Time without finds : 54 seconds

sudo apt install gnuplot
afl-plot /users/user42/prog/sync_dir/ngram_slave/ /users/user42/prog/plot-ngram
afl-plot /users/user42/prog/sync_dir/pcguard_master/ /users/user42/prog/plot-pcguard


