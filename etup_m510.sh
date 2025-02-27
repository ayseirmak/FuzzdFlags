#!/usr/bin/env bash

# -------------------------------------------------------
# Step 0: Update & upgrade the system, install core tools
# -------------------------------------------------------
sudo useradd -m -d /users/user42 -s /bin/bash user42
sudo passwd user42
sudo usermod -aG sudo user42
sudo usermod -aG kclsystemfuzz-PG user42
sudo chown -R user42:kclsystemfuzz-PG /users/user42
sudo chmod 755 /users/user42

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

# -------------------------------------------------------
# Step 4: Download & install LLVM 14 (for system clang)
# -------------------------------------------------------
wget https://apt.llvm.org/llvm.sh
sudo chmod +x llvm.sh
sudo ./llvm.sh 14
sudo apt-get install -y llvm-14-dev


# Set LLVM 14 as the default LLVM/Clang
sudo update-alternatives --install /usr/bin/clang clang /usr/bin/clang-14 1400 \
  --slave /usr/bin/clang++ clang++ /usr/bin/clang++-14
sudo update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-14 1400

export LLVM_CONFIG=/usr/bin/llvm-config-14

# -------------------------------------------------------
# Step 5: Install AFL++ from source
# -------------------------------------------------------
git clone https://github.com/AFLplusplus/AFLplusplus.git
cd AFLplusplus

# Checkout a specific commit (optional)
git checkout f596a297c4de6a5e1a6fb9fbb3b4e18124a24f58

# Build AFL++ (disable ASAN via AFL_USE_ASAN=0 for performance/simplicity)
AFL_USE_ASAN=0 make
sudo make install

# -------------------------------------------------------
# Step 6: Configure Swap Space (4GB)
# -------------------------------------------------------
cd /users/user42
sudo fallocate -l 4G swapfile
sudo chmod 600 swapfile
sudo mkswap swapfile
sudo swapon swapfile
sudo swapon --show

# -------------------------------------------------------
# Step 7: Set Up Core Dump Handling
# -------------------------------------------------------
echo "core" | sudo tee /proc/sys/kernel/core_pattern

# -------------------------------------------------------
# Step 8: Set Up Environment Variables
# -------------------------------------------------------
export CC=/usr/local/bin/afl-clang-fast
export CXX=/usr/local/bin/afl-clang-fast++

# -------------------------------------------------------
# Step 9: Set Ownership and Permissions
# -------------------------------------------------------

sudo chown -R user42:user42 /users/user42/
chmod -R u+w /users/user42/

# -------------------------------------------------------
# Step 10: Download & build LLVM 17 with AFL compiler
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
# Step 8: Download and extract reindexed after cmin llvmSS c files
# -------------------------------------------------------
cd ~
wget https://github.com/ayseirmak/ISSTA_2025_Tool/raw/refs/heads/main/cmin-input-output/llvmSS-reindex-cfiles.tar.gz
tar -zxvf llvmSS-reindex-cfiles.tar.gz
