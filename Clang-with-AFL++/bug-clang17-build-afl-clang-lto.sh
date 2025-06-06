
# -------------------------------------------------------
# Step 4: Download & install LLVM 14 (for system clang)
# -------------------------------------------------------
sudo bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
sudo apt-get install -y clang-14 lldb-14 lld-14
sudo ln -s /usr/bin/llvm-config-14 /usr/bin/llvm-config
su - user42
export LLVM_CONFIG=/usr/bin/llvm-config

git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout release/17.x
cd /users/user42/llvm-project/clang/tools
mkdir -p clang-options && cd clang-options
wget https://raw.githubusercontent.com/ayseirmak/FuzzdFlags/refs/heads/main/1-LLVMSS-dataset/2-fuzzdflags-options/CMakeLists.txt
wget https://raw.githubusercontent.com/ayseirmak/FuzzdFlags/refs/heads/main/1-LLVMSS-dataset/2-fuzzdflags-options/ClangOptions.cpp
nano ../CMakeLists.txt
cd ~

wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v5.0/exp22-input-seeds-30.tar.gz &&     tar -zxvf exp22-input-seeds-30.tar.gz
cd AFLplusplus/
MAP_SIZE_POW2=23 make distrib
sudo make install

cd ~

mkdir build
cd build
export AFL_MAP_SIZE=8388608
LD=/usr/local/bin/afl-clang-lto++ CC=afl-clang-lto CXX=afl-clang-lto++ RANLIB=llvm-ranlib-14 AR=llvm-ar-14 AS=llvm-as-14 cmake -G Ninja -Wall ../llvm-project/llvm/ \
  -DLLVM_ENABLE_PROJECTS="clang" \
  -DLLVM_USE_SANITIZER=OFF \
  -DCMAKE_BUILD_TYPE="Release" \
  -DCMAKE_C_COMPILER=/usr/local/bin/afl-clang-lto \
  -DCMAKE_CXX_COMPILER=/usr/local/bin/afl-clang-lto++ \
  -DBUILD_SHARED_LIBS=OFF \
  -DLLVM_TARGETS_TO_BUILD="X86" \
  -DCMAKE_C_FLAGS="-pthread -L/usr/lib/x86_64-linux-gnu" \
  -DCMAKE_CXX_FLAGS="-pthread -L/usr/lib/x86_64-linux-gnu" \
  -DCMAKE_EXE_LINKER_FLAGS="-L/usr/lib/x86_64-linux-gnu" \
  -DLLVM_BUILD_DOCS="OFF"

ninja clang clang-options

[472/2687] Building IntrinsicsLoongArch.h...
FAILED: include/llvm/IR/IntrinsicsLoongArch.h /users/user42/build/include/llvm/IR/IntrinsicsLoongArch.h 
cd /users/user42/build && /users/user42/build/bin/llvm-min-tblgen -gen-intrinsic-enums -intrinsic-prefix=loongarch -I /users/user42/llvm-project/llvm/include/llvm/IR -I/users/user42/build/include -I/users/user42/llvm-project/llvm/include /users/user42/llvm-project/llvm/include/llvm/IR/Intrinsics.td --write-if-changed -o include/llvm/IR/IntrinsicsLoongArch.h -d include/llvm/IR/IntrinsicsLoongArch.h.d
PLEASE submit a bug report to https://github.com/llvm/llvm-project/issues/ and include the crash backtrace.
Stack dump:
0.      Program arguments: /users/user42/build/bin/llvm-min-tblgen -gen-intrinsic-enums -intrinsic-prefix=loongarch -I /users/user42/llvm-project/llvm/include/llvm/IR -I/users/user42/build/include -I/users/user42/llvm-project/llvm/include /users/user42/llvm-project/llvm/include/llvm/IR/Intrinsics.td --write-if-changed -o include/llvm/IR/IntrinsicsLoongArch.h -d include/llvm/IR/IntrinsicsLoongArch.h.d
Stack dump without symbol names (ensure you have llvm-symbolizer in your PATH or set the environment var `LLVM_SYMBOLIZER_PATH` to point to it):
0  llvm-min-tblgen 0x0000555bed04ab0a
1  llvm-min-tblgen 0x0000555bed04a5cb
2  libc.so.6       0x00007eff65600520
3  llvm-min-tblgen 0x0000555bed01844c
4  llvm-min-tblgen 0x0000555becfbd132
5  llvm-min-tblgen 0x0000555becfb902e
6  llvm-min-tblgen 0x0000555becfdc620
7  libc.so.6       0x00007eff655e7d90
8  libc.so.6       0x00007eff655e7e40 __libc_start_main + 128
9  llvm-min-tblgen 0x0000555becf83d25
Segmentation fault
