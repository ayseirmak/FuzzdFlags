# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Suppress debconf interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Switch to root for system-level installations
USER root

# Replace /bin/sh with bash, create new user "user42" and password "password"
RUN rm /bin/sh && ln -s /bin/bash /bin/sh && \
    useradd -m -d /users/user42 -s /bin/bash user42 && \
    echo "user42:123" | chpasswd && \
    usermod -aG sudo user42 && \
    chmod 755 /users/user42

# Update package lists, upgrade packages, and install basic utilities
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
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

# Add the toolchain PPA and update package lists again
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update

# Install GCC 11 toolchain and reconfigure system symlinks
RUN apt-get -y install gcc-11 g++-11 cpp-11 && \
    rm /usr/bin/cpp /usr/bin/gcc /usr/bin/g++ /usr/bin/gcov /usr/bin/c++ /usr/bin/cc 2>/dev/null && \
    ln -s /usr/bin/cpp-11  /usr/bin/cpp && \
    ln -s /usr/bin/gcc-11  /usr/bin/gcc && \
    ln -s /usr/bin/gcc-11  /usr/bin/cc && \
    ln -s /usr/bin/g++-11  /usr/bin/g++ && \
    ln -s /usr/bin/g++-11  /usr/bin/c++ && \
    ln -s /usr/bin/gcov-11 /usr/bin/gcov

# Install LLVM/Clang 14 using the official script and set up llvm-config symlink
RUN bash -c "$(wget -O - https://apt.llvm.org/llvm.sh)" && \
    apt-get install -y clang-14 lldb-14 lld-14 && \
    ln -s /usr/bin/llvm-config-14 /usr/bin/llvm-config

# Switch to the non-root user "user42" and set the working directory
USER user42
WORKDIR /users/user42

# Set environment variable for LLVM_CONFIG
ENV LLVM_CONFIG=/usr/bin/llvm-config

# Download and install AFL++
RUN wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v1.0-alpha/AFL-latest.tar.gz && \
    tar -zxvf AFL-latest.tar.gz

USER root
RUN cd /users/user42/AFLplusplus && make install && cd ..
USER user42
WORKDIR /users/user42

# Download and extract C-programset-reindexed
RUN wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v1.0-alpha/llvmSS-reindex-after-Cmin.tar.gz && \
    tar -zxvf llvmSS-reindex-after-Cmin.tar.gz

# Download and extract rs-clang-options-build
RUN wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v2.0-beta/exp1-clang-build.tar.gz && \
    tar -zxvf exp1-clang-build.tar.gz

# Download and extract rs-fuzz-scripts, make scripts executable, and remove tarballs
RUN wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v2.0-beta/exp1-fuzz-scripts.tar.gz && \
    tar -xzvf exp1-fuzz-scripts.tar.gz && \
    chmod +x *.sh && \
    rm *.tar.gz

# Set proper ownership and writable permissions for /users/user42/
USER root
RUN chown -R user42:user42 /users/user42/ && chmod -R u+w /users/user42/
USER user42

# Optionally, set the core dump pattern (may require privileged container or may not persist in Docker)
USER root
RUN echo "core" | tee /proc/sys/kernel/core_pattern || true
USER user42

# Set default command
CMD ["/bin/bash"]
