# Base Image for ARM64
FROM arm64v8/ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Create 'debian' user
USER root
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN useradd -ms /bin/bash debian

# Install system-level dependencies as root
RUN apt-get update && apt-get install -y \
    gcc-11 g++-11 \
    python3 python3-pip \
    cmake m4 \
    clang llvm lld \
    git curl wget build-essential automake \
    && apt-get clean

# Set GCC, G++, and GCOV 11 as defaults
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 90 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 90 \
    && update-alternatives --install /usr/bin/gcov gcov /usr/bin/gcov-11 90

# Install AFL++ as root
RUN git clone https://github.com/AFLplusplus/AFLplusplus.git /opt/AFLplusplus \
    && cd /opt/AFLplusplus \
    && make clean all \
    && make install

# Install recent Clang version (Clang 15)
RUN apt-get install -y clang-15 llvm-15 lld-15

# Create two separate Clang binaries for fuzzing and coverage
RUN cp /opt/AFLplusplus/afl-clang-fast /usr/local/bin/clang-afl \
    && cp /usr/bin/clang-15 /usr/local/bin/clang-cov

# Verify the installations
RUN clang-afl --version && clang-cov --version

# Install Python packages
RUN pip3 install --upgrade pip && pip3 install wheel

# Change ownership of the home directory to 'debian'
RUN chown -R debian:debian /home/debian

# Switch to 'debian' user for safer execution of tasks
USER debian
WORKDIR /home/debian

# Create a workspace directory
RUN mkdir -p /home/debian/workspace

# Switch back to root for final preparations if needed
USER root

# Set the default working directory
WORKDIR /home/debian/workspace

CMD ["/bin/bash"]
