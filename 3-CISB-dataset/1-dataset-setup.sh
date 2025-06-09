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
su - user42
export LLVM_CONFIG=/usr/bin/llvm-config
# -------------------------------------------------------
# Step 5: setup AFL++ from source
# -------------------------------------------------------
wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v1.0-alpha/AFL-latest.tar.gz
tar -zxvf AFL-latest.tar.gz
cd AFLplusplus
sudo make install
cd ~
# -------------------------------------------------------
# Step 6: setup clang17-build
# -------------------------------------------------------
wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v5.0/exp2-clangOpt-build.tar.gz && \
tar -zxvf exp2-clangOpt-build.tar.gz
# -------------------------------------------------------
# Step 7: download CISB dataset
# -------------------------------------------------------
mkdir CISB_dataset
cd CISB_dataset
git clone --depth 1 --filter=blob:none --sparse https://github.com/H0w1/CISB-dataset.git .
git sparse-checkout set reproduction_material/testcases

mkdir -p cisb-dataset
i=1
find /users/user42/CISB_dataset/reproduction_material/testcases \
    -name '*.c' -type f | sort | \
while read -r file; do
    cp "$file" "/users/user42/CISB_dataset/cisb-dataset/test_${i}.c"
    ((i++))
done

tar -czvf csib-programs.tar.gz -C /users/user42/CISB_dataset/ cisb-dataset

