wget https://github.com/gcc-mirror/gcc/archive/refs/tags/releases/gcc-14.2.0.tar.gz
tar -xvf gcc-14.2.0.tar.gz
cd gcc-14.2.0
./contrib/download_prerequisites
cd ..  
mkdir gcc14-build && cd gcc14-build
../gcc-14.2.0/configure --prefix=/opt/gcc-14 \
    --disable-multilib --disable-bootstrap \
    --enable-languages=c,c++,lto,objc,obj-c++ \
    --enable-targets=x86
make -j$(nproc)
sudo make install

#https://releases.llvm.org/

mkdir -p llvm-latest
cd llvm-lates
git clone https://github.com/llvm/llvm-project.git
mkdir llvm-trunk-build && cd llvm-trunk-build

AFL_USE_ASAN=0 cmake -G Ninja -Wall ../llvm-project/llvm/ \
-DCMAKE_BUILD_TYPE=Release \
-DLLVM_ENABLE_PROJECTS="clang;lld;clang-tools-extra" \
-DCMAKE_C_COMPILER=gcc-11 \
-DCMAKE_CXX_COMPILER=g++-11 \
-DBUILD_SHARED_LIBS=OFF \
-DLLVM_TARGETS_TO_BUILD=X86 \
-DLLVM_BUILD_DOCS="OFF" \
-DLLVM_BUILD_EXAMPLES="OFF"

ninja -j "$(nproc)"

user42@node0:~/llvm-latest/llvm-trunk-build$ ./bin/clang --version
clang version 21.0.0git (https://github.com/llvm/llvm-project.git 605a9f590d91a42ae652c2ab13487b5ad57c58a5)
Target: x86_64-unknown-linux-gnu
Thread model: posix
InstalledDir: /users/user42/llvm-latest/llvm-trunk-build/bin

#user42@node0:~$ ldd llvm-latest/llvm-trunk-build/bin/clang
#        linux-vdso.so.1 (0x00007ffcb3955000)
#        libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007f7265800000)
#        libstdc++.so.6 => /lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007f7265593000)
#        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007f72654ac000)
#        libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007f7265488000)
#        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f726525f000)
#        /lib64/ld-linux-x86-64.so.2 (0x00007f726d06f000)

#user42@node0:~/build-test$ ldd ./bin/clang-options 
#        linux-vdso.so.1 (0x00007ffdce993000)
#        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007fa372c97000)
#        libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007fa372c7b000)
#        libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007fa372c49000)
#        libstdc++.so.6 => /lib/x86_64-linux-gnu/libstdc++.so.6 (0x00007fa3729dc000)
#        libgcc_s.so.1 => /lib/x86_64-linux-gnu/libgcc_s.so.1 (0x00007fa3729b8000)
#        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fa37278d000)
#        /lib64/ld-linux-x86-64.so.2 (0x00007fa374cb4000)

