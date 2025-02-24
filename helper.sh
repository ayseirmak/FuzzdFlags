which clang
ls /usr/bin/clang*
export CC=/usr/bin/clang-14
export CXX=/usr/bin/clang++-14


AFL_DEBUG=1 AFL_DEBUG_CHILD_OUTPUT=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 afl-cmin -i /users/user42/llvmSS-before-Cmin -o /users/user42/output -m none -t 500 -T 12 -- /users/user42/build-test/bin/clang -O3 -o /dev/null @@

AFL_DEBUG=1 AFL_DEBUG_CHILD_OUTPUT=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 \
afl-cmin -i /users/user42/llvmSS-before-Cmin -o /users/user42/output \
-m none -t 500 -T 12 -- /users/user42/build-test/bin/clang \
-x c -c -O3 -o /dev/null -I/users/user42/input-include @@

AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 AFL_DEBUG_CHILD_OUTPUT=1 \
afl-cmin -i /users/user42/llvmSS-before-Cmin -o /users/user42/output-2 -m none -t 500 -T 12 \
-- /users/user42/build-test/bin/clang -x c -c -O3 -o /dev/null \
-I/usr/include -I/users/user42/input-include @@


ls -l /users/user42/output-Cmin2 | wc -l

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
cat ~/.bash_history

AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 AFL_DEBUG_CHILD_OUTPUT=1 afl-cmin -i /users/user42/llvmSS-before-Cmin -o /users/user42/output-Cmin \
-m none -t 500 -T 12 -- /users/user42/build-test/bin/clang -x c -c -O3 \
-include stdlib.h -fpermissive -w -Wno-implicit-function-declaration -Wno-implicit-int  -target x86_64-linux-gnu -march=native \
-I/usr/include -I/users/user42/input-include -I/usr/include/x86_64-linux-gnu/ @@ -o /dev/null 2>&1 | tee /users/user42/afl-cmin-errors.log

#Extra
#-maltivec -mabi=altivec (PPC or ABI) -Wno-return-type -Wno-builtin-redeclared -Wno-int-conversion (-I/usr/include/x86_64-linux-gnu) (-include stdlib.h)

#Cmin-Ver2
AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 AFL_DEBUG_CHILD_OUTPUT=1 afl-cmin -i /users/user42/llvmSS-before-Cmin -o /users/user42/output-Cmin2 \
-m none -t 500 -T 12 -- /users/user42/build-test/bin/clang -x c -c -O3 \
-fpermissive -w -Wno-implicit-function-declaration -Wno-implicit-int -Wno-return-type -Wno-builtin-redeclared -Wno-int-conversion  -target x86_64-linux-gnu -march=native \
-I/usr/include -I/users/user42/input-include @@ -o /dev/null 2>&1 | tee /users/user42/afl-cmin-errors2.log

# Fixed flags
-x c -c -fpermissive -w -Wno-implicit-function-declaration -Wno-implicit-int -Wno-return-type -Wno-builtin-redeclared -Wno-int-conversion -target x86_64-linux-gnu -march=native -I/usr/include -I/users/user42/input-include
./build-test/bin/clang output-Cmin2/hello.c -x c -c -fpermissive -w -Wno-implicit-function-declaration -Wno-implicit-int -Wno-return-type -Wno-builtin-redeclared -Wno-int-conversion -target x86_64-linux-gnu -march=native -I/usr/include -I/users/user42/input-include -O3
./build-test/bin/clang-options --filebin seed2.bin --checker

AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_DEBUG_CHILD_OUTPUT=1 AFL_SHUFFLE_QUEUE=1 AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \ 
afl-fuzz -i /users/user42/input-seeds -m none -t 2000 -T 10 -o /users/user42/output-afl \ -- /users/user42/build-test/bin/clang-options --filebin @@

./24_fuzz.sh /users/user42/input_seeds /users/user42/output-fuzz 1 exp2 /users/user42/build-test/bin/clang-options






