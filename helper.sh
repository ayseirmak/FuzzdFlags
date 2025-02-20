AFL_DEBUG=1 AFL_DEBUG_CHILD_OUTPUT=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 afl-cmin -i /users/user42/llvmSS-before-Cmin -o /users/user42/output -m none -t 500 -T 12 -- /users/user42/build-test/bin/clang -O3 -o /dev/null @@

AFL_DEBUG=1 AFL_DEBUG_CHILD_OUTPUT=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 \
afl-cmin -i /users/user42/llvmSS-before-Cmin -o /users/user42/output \
-m none -t 500 -T 12 -- /users/user42/build-test/bin/clang \
-x c -c -O3 -o /dev/null -I/users/user42/input-include @@

AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 AFL_DEBUG_CHILD_OUTPUT=1 \
afl-cmin -i /users/user42/llvmSS-before-Cmin -o /users/user42/output-2 -m none -t 500 -T 12 \
-- /users/user42/build-test/bin/clang -x c -c -O3 -o /dev/null \
-I/usr/include -I/users/user42/input-include @@


ls -l /users/user42/output-2 | wc -l

cp /users/user42/input-include/*.h /users/user42/llvmSS-after-Cmin
clang: error: linker command failed with exit code 1 (use -v to see invocation)
/usr/bin/ld:/users/user42/output/.filelist.12.stdin: file format not recognized; treating as linker script
/usr/bin/ld:/users/user42/output/.filelist.12.stdin:1: syntax error
clang: error: linker command failed with exit code 1 (use -v to see invocation)

mkdir -p /users/user42/llvmSS-after-Cmin_headers
cp -r /users/user42/output-2/* /users/user42/llvmSS-after-Cmin_cfiles/
cp -r /users/user42/input-include/* /users/user42/llvmSS-after-Cmin_headers/

ls -l /users/user42/llvmSS-before-Cmin_cfiles 

tar -czvf /users/user42/llvmSS-after-Cmin.tar.gz -C /users/user42 llvmSS-after-Cmin_cfiles llvmSS-after-Cmin_headers

Token: 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
