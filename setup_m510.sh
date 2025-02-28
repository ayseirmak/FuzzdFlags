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
sudo bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)"
sudo apt-get install -y clang-14 lldb-14 lld-14
sudo ln -s /usr/bin/llvm-config-14 /usr/bin/llvm-config
export LLVM_CONFIG=/usr/bin/llvm-config

# -------------------------------------------------------
# Step 5: Install AFL++ from source
# -------------------------------------------------------
git clone https://github.com/karineek/SearchGEM5.git 
git clone https://github.com/AFLplusplus/AFLplusplus.git 
cd AFLplusplus 
git checkout f596a297c4de6a5e1a6fb9fbb3b4e18124a24f58 
cp ../SearchGEM5/src/gem5-afl/afl-fuzz-init.c src/afl-fuzz-init.c 
AFL_USE_ASAN=0 make 

# Build AFL++ (disable ASAN via AFL_USE_ASAN=0 for performance/simplicity)
sudo make install

# -------------------------------------------------------
# Step 6: Configure Swap Space (4GB)
# -------------------------------------------------------
cd /users/user42
sudo dd if=/dev/zero of=/swapfile bs=1G count=8
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
free -h


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
# Step 10: Final Cleanup
# -------------------------------------------------------
sudo apt -y autoremove
sudo apt-get clean

echo "All setup complete! Run: su - user42"



# -------------------------------------------------------
# Step 8: Download and extract reindexed after cmin llvmSS c files
# -------------------------------------------------------
cd ~
wget https://github.com/ayseirmak/ISSTA_2025_Tool/raw/refs/heads/main/cmin-input-output/llvmSS-reindex-cfiles.tar.gz
tar -zxvf llvmSS-reindex-cfiles.tar.gz



# -------------------------------------------------------
# All done!
# -------------------------------------------------------

AFL_DEBUG=1 AFL_USE_ASAN=0 AFL_PRINT_FILENAMES=1 AFL_DEBUG_CHILD_OUTPUT=1 afl-cmin -i /users/user42/llvmSS-before-Cmin-cfiles -o /users/user42/output-Cmin2 -m none -t 500 -T 12 -- /users/user42/build-test/bin/clang -x c -c -O3 -fpermissive -w -Wno-implicit-function-declaration -Wno-implicit-int -Wno-return-type -Wno-builtin-redeclared -Wno-int-conversion  -target x86_64-linux-gnu -march=native -I/usr/include -I/users/user42/llvmSS-include @@ -o /dev/null 2>&1 | tee /users/user42/afl-cmin-errors.log

cd /sys/devices/system/cpu
sudo echo performance | sudo tee cpu*/cpufreq/scaling_governor
./multi_round_fuzz.sh /users/user42/llvmSS-reindex-cfiles /users/user42/output-fuzz exp1 /users/user42/build-test/bin/clang
