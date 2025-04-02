#Create nutral user and install defaults
sudo useradd -m -d /users/user42 -s /bin/bash user42
sudo passwd user42
sudo usermod -aG sudo user42
sudo usermod -aG kclsystemfuzz-PG user42
sudo chown -R user42:kclsystemfuzz-PG /users/user42
sudo chmod 777 /users/user42
sudo apt-get install -y   software-properties-common   build-essential   apt-utils   wget   curl   git   vim   nano   zip   unzip   lsb-release   zlib1g   zlib1g-dev   libssl-dev   python3-dev   automake   cmake   flex   bison   libglib2.0-dev   libpixman-1-dev   python3-setuptools   cargo   libgtk-3-dev   ninja-build   gdb   coreutils   gcc-11-plugin-dev   libedit-dev   libpfm4-dev   valgrind   ocaml-nox   autoconf   libtool   pkg-config   libxml2-dev   ocaml   ocaml-findlib   libpthread-stubs0-dev   libtinfo-dev   libncurses5-dev   libz-dev   python3-pip   binutils-dev   libiberty-dev
which python3
python3 --version
>> 3.10.12

#Build gfauto tool
cd /users/user42/
git clone https://github.com/google/graphicsfuzz.git
cd graphicsfuzz/gfauto/
vi dev_shell.sh.template
EDIT TO YOUR LOCAL VERSION of Python3: PYTHON=${PYTHON-python3.6} to PYTHON=${PYTHON-python3.10}
rm Pipfile.lock (since it is Python3.8 or above)
./dev_shell.sh.template 

#Install default gcc g cpp and clang
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt-get update
sudo apt-get -y install gcc-11 g++-11 cpp-11
sudo rm /usr/bin/cpp /usr/bin/gcc /usr/bin/g++ /usr/bin/gcov /usr/bin/c++ /usr/bin/cc 2>/dev/null
sudo ln -s /usr/bin/cpp-11  /usr/bin/cpp
sudo ln -s /usr/bin/gcc-11  /usr/bin/gcc
sudo ln -s /usr/bin/gcc-11  /usr/bin/cc
sudo ln -s /usr/bin/g++-11  /usr/bin/g++
sudo ln -s /usr/bin/g++-11  /usr/bin/c++
sudo ln -s /usr/bin/gcov-11 /usr/bin/gcov

sudo bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
sudo apt-get install -y llvm-14 llvm-14-dev llvm-14-tools clang-14 libclang-common-14-dev libclang-14-dev
sudo apt-get install -y llvm-12 llvm-12-dev llvm-12-tools clang-12 libclang-common-12-dev libclang-12-dev

#Build GrayC
git clone https://github.com/srg-imperial/GrayC.git
cd GrayC
mkdir build
cd build
which clang
find /usr/bin/clang*
cmake -GNinja -DCMAKE_C_COMPILER=clang-12 -DCMAKE_CXX_COMPILER=clang++-12 -DLLVM_CONFIG_BINARY=llvm-config-12 ../
ninja
bin/grayc --list-mutations

