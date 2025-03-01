# -------------------------------------------------------
# Step 1: Download & build LLVM 17 with AFL compiler
# -------------------------------------------------------
cd ~
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout release/17.x

# Create and enter a separate build directory
mkdir ~/build-test
cd ~/build-test

# Configure LLVM build to use AFL's clang-fast
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

# -------------------------------------------------------
# Step 2: Start Fuzzing
# -------------------------------------------------------
nano 24_fuzz.sh
run_AFL_conf_1.sh
multi_round_fuzz.sh
chmod +x 24_fuzz.sh
chmod +x multi_round_fuzz.sh
chmod +x run_AFL_conf_1.sh

#For Cloudlab m510
cd /sys/devices/system/cpu
sudo echo performance | sudo tee cpu*/cpufreq/scaling_governor
cd ~ 

screen -dmS fuzz_session_exp1_noDB ./multi_round_fuzz.sh /users/user42/llvmSS-reindex-cfiles /users/user42/output-fuzz exp1 /users/user42/build-test/bin/clang
# Check if it’s running: screen -ls
# Reattach if you want to see the console output: screen -r fuzz_session_exp1 / Return: Ctrl+A, then D
# To kill: screen -S fuzz_session_exp1 -X quit

#exp2 version
screen -dmS fuzz_session_exp2 ./multi_round_fuzz.sh /users/user42/input-seeds /users/user42/output-fuzz exp2 /users/user42/build-test/bin/clang-options

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Inside run_AFL_conf_1.sh
# AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_DEBUG_CHILD_OUTPUT=1 AFL_SHUFFLE_QUEUE=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
# afl-fuzz -i /users/user42/llvmSS-reindex-cfiles -o /users/user42/output-fuzz -m none -t 500 -T 12 -- /users/user42/build-test/bin/clang \
# -x c -c -O3 -fpermissive -w -Wno-implicit-function-declaration -Wno-implicit-int \
#-target x86_64-linux-gnu -march=native -I/usr/include -I/users/user42/llvmSS-include  @@
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------

# -------------------------------------------------------
# Step 3: tar exp1-AFL and exp1-Clang 
# -------------------------------------------------------
mkdir -p /users/user42/ISSTA_2025_Tool/exp1
git clone https://github.com/ayseirmak/ISSTA_2025_Tool.git
tar -czvf ISSTA_2025_Tool/exp1/exp1-AFL.tar.gz -C /users/user42 AFLplusplus
tar -czvf ISSTA_2025_Tool/exp1/exp1-Clang.tar.gz -C /users/user42 build-test


