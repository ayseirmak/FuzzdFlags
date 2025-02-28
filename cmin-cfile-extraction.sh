
# -------------------------------------------------------
# Step 1: Download llvm-test suit 
# -------------------------------------------------------
git clone https://github.com/llvm/llvm-test-suite.git

# -------------------------------------------------------
# Step 2: Extract cfiles and includes 
# -------------------------------------------------------
cd llvm-test-suite/SingleSource 
mkdir -p ~/llvmSS-before-Cmin-cfiles
mkdir -p ~/llvmSS-include
find . -type f -name "*.c" | sort | awk '{print "cp "$0" ~/llvmSS-before-Cmin-cfiles/test_"(NR-1)".c"}' | bash
find . -type f -name "*.h" -exec cp {} ~/llvmSS-include
cp -r ./Regression/C/gcc-c-torture/execute/builtins/lib ~/llvmSS-include

# -------------------------------------------------------
# Step 3: Run Cmin on llvmSS-before-cmin-cfiles
# -------------------------------------------------------
cd ~
AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 AFL_DEBUG_CHILD_OUTPUT=1 \ 
afl-cmin -i /users/user42/llvmSS-before-Cmin-cfiles -o /users/user42/llvmSS-after-Cmin-cfiles \
-m none -t 500 -T 12 -- /users/user42/build-test/bin/clang -x c -c -O3 -fpermissive \
-w -Wno-implicit-function-declaration -Wno-implicit-int -Wno-return-type -Wno-builtin-redeclared -Wno-int-conversion  \
-target x86_64-linux-gnu -march=native -I/usr/include -I/users/user42/llvmSS-include @@  -o /dev/null 2>&1 | tee /users/user42/afl-cmin-errors.log

# Across 2113 files cmin minimized these to 1768 files

# -------------------------------------------------------
# Step 4: Reindexing on llvmSS-after-Cmin-cfiles
# -------------------------------------------------------
mkdir -p ~/llvmSS-reindex-cfiles
cd llvmSS-after-Cmin-cfiles
find . -type f -name "*.c" | sort | awk '{print "cp "$0" ~/llvmSS-reindex-cfiles/test_"(NR-1)".c"}' | bash
cd ~

# -------------------------------------------------------
# Step 5: Tar output files and push Github
# -------------------------------------------------------
mkdir -p /users/user42/ISSTA_2025_Tool/cmin-input-output
git clone https://github.com/ayseirmak/ISSTA_2025_Tool.git
tar -czvf ISSTA_2025_Tool/cmin-input-output/llvmSS-after-Cmin.tar.gz -C /users/user42 llvmSS-after-Cmin-cfiles llvmSS-include
tar -czvf ISSTA_2025_Tool/cmin-input-output/llvmSS-reindex-after-Cmin.tar.gz -C /users/user42 llvmSS-reindex-cfiles llvmSS-include


