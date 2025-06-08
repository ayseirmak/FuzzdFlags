# m510 setup FuzzdFlags - 10 seeds
# -------------------------------------------------------
# Step 0: Update & upgrade the system, install core tools
# -------------------------------------------------------
sudo useradd -m -d /users/user42 -s /bin/bash user42
sudo passwd user42
sudo usermod -aG sudo user42
sudo usermod -aG kclsystemfuzz-PG user42
sudo chown -R user42:kclsystemfuzz-PG /users/user42
sudo chmod 777 /users/user42
sudo chown -R user42:user42 /users/user42/
chmod -R u+w /users/user42/
# -------------------------------------------------------
# Step 1: Update & upgrade the system, install core tools
# -------------------------------------------------------
sudo apt-get update && sudo apt-get upgrade -y

# Install a broad set of essential development packages
sudo apt-get install -y \
  software-properties-common \
  build-essential \
  apt-utils \
  wget \
  curl \
  git \
  vim \
  nano \
  zip \
  unzip \
  lsb-release \
  zlib1g \
  zlib1g-dev \
  libssl-dev \
  python3-dev \
  automake \
  cmake \
  flex \
  bison \
  libglib2.0-dev \
  libpixman-1-dev \
  python3-setuptools \
  cargo \
  libgtk-3-dev \
  ninja-build \
  gdb \
  coreutils \
  gcc-11-plugin-dev \
  libedit-dev \
  libpfm4-dev \
  valgrind \
  ocaml-nox \
  autoconf \
  libtool \
  pkg-config \
  libxml2-dev \
  ocaml \
  ocaml-findlib \
  libpthread-stubs0-dev \
  libtinfo-dev \
  libncurses5-dev \
  libz-dev \
  python3-pip \
  binutils-dev \
  libiberty-dev


# ------------------------------------------
# Step 2: Add Toolchain PPA & install GCC-11
# ------------------------------------------
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt-get update
sudo apt-get -y install gcc-11 g++-11 cpp-11

# --------------------------------------------------
# Step 3: Set GCC-11, G++-11, etc. as the system default
# --------------------------------------------------
sudo rm /usr/bin/cpp /usr/bin/gcc /usr/bin/g++ /usr/bin/gcov /usr/bin/c++ /usr/bin/cc 2>/dev/null

sudo ln -s /usr/bin/cpp-11  /usr/bin/cpp
sudo ln -s /usr/bin/gcc-11  /usr/bin/gcc
sudo ln -s /usr/bin/gcc-11  /usr/bin/cc
sudo ln -s /usr/bin/g++-11  /usr/bin/g++
sudo ln -s /usr/bin/g++-11  /usr/bin/c++
sudo ln -s /usr/bin/gcov-11 /usr/bin/gcov

su user42

# --------------------------------------------------
# Step 4: Clang-trunk-build
# --------------------------------------------------

mkdir -p llvm-latest
cd llvm-latest
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

# --------------------------------------------------
# Step 5: Clang-19-build
# --------------------------------------------------
mkdir -p llvm-19
cd llvm-19
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout release/19.x
cd ..
mkdir llvm-19-build && cd llvm-19-build
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

# --------------------------------------------------
# Step 5: Clang-20-build
# --------------------------------------------------
mkdir -p llvm-20
cd llvm-20
git clone https://github.com/llvm/llvm-project.git
cd llvm-project
git checkout release/20.x
cd ..
mkdir llvm-20-build && cd llvm-20-build
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

# --------------------------------------------------
# Step 6: Input C programs
# --------------------------------------------------
wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v1.0-alpha/llvmSS-reindex-after-Cmin.tar.gz 
tar -zxvf llvmSS-reindex-after-Cmin.tar.gz







