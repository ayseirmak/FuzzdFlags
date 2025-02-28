# -------------------------------------------------------
# Step 1: Run Cmin on llvmSS-before-cmin-cfiles
# -------------------------------------------------------
AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 AFL_DEBUG_CHILD_OUTPUT=1 afl-cmin -i /users/user42/llvmSS-before-Cmin-cfiles -o /users/user42/output-Cmin2 -m none -t 500 -T 12 -- /users/user42/build-test/bin/clang -x c -c -O3 -fpermissive -w -Wno-implicit-function-declaration -Wno-implicit-int -Wno-return-type -Wno-builtin-redeclared -Wno-int-conversion  -target x86_64-linux-gnu -march=native -I/usr/include -I/users/user42/llvmSS-include @@  -o /dev/null 2>&1 | tee /users/user42/afl-cmin-errors.log
