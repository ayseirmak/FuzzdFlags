#!/usr/bin/env bash

# -------------------------------------------------------
# 0. Create/Configure a Non-Root User (Optional)
# -------------------------------------------------------
# Adjust group names, etc. according to your environment

sudo useradd -m -d /users/user42 -s /bin/bash user42
sudo passwd user42
sudo usermod -aG sudo user42
sudo usermod -aG kclsystemfuzz-PG user42



# Adjust ownership/permissions as desired:
sudo chown -R user42:user42 /users/user42
sudo chmod 777 /users/user42

# -------------------------------------------------------
# 1. Update & Upgrade the System
# -------------------------------------------------------
sudo apt-get update && sudo apt-get upgrade -y

# -------------------------------------------------------
# 2. Install Docker (Host Only)
# -------------------------------------------------------
sudo apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  wget \
  git

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Optionally allow user42 to run docker without sudo:
sudo usermod -aG docker user42
# -------------------------------------------------------
# 3. Configure Core Dumps
# -------------------------------------------------------
echo "core" | sudo tee /proc/sys/kernel/core_pattern

# -------------------------------------------------------
# 4. Download Dockerfile & Helper Scripts & Build Fuzzing Image
# -------------------------------------------------------
su - user42
wget https://raw.githubusercontent.com/ayseirmak/FuzzdFlags/refs/heads/main/1-LLVMSS-dataset/1-afl-vanilla/2-fuzz-afl-vanilla-o3/exp12-dock.dockerfile
wget https://raw.githubusercontent.com/ayseirmak/FuzzdFlags/refs/heads/main/1-LLVMSS-dataset/extract_fuzz_stat_dir.sh
chmod +x *.sh

# Build Docker image from the local Dockerfile
docker build -f exp12-dock.dockerfile -t afl-vanilla-img .

# -------------------------------------------------------
# 5. Prepare Output Directories
# -------------------------------------------------------
mkdir -p fuzz01 fuzz02 fuzz03 fuzz04 fuzz05
chown -R user42:user42 fuzz01 fuzz02 fuzz03 fuzz04 fuzz05
chmod -R 777 fuzz01 fuzz02 fuzz03 fuzz04 fuzz05



# -------------------------------------------------------
# 6. Launch 5 Fuzzing Containers
# -------------------------------------------------------
# NOTE: Adjust --cpuset-cpus according to the actual cores on your m510 node.
# Give each container 3 cores:
# fuzz01 -> 0-2, fuzz02 -> 3-5, fuzz03 -> 6-8, fuzz04 -> 9-11, fuzz05 -> 12-14

docker run -d --name fuzz01 --cpuset-cpus="0-2" \
  -v /users/user42/fuzz01:/users/user42/output-fuzz \
  afl-vanilla-img \
  /users/user42/24_fuzz.sh run_AFL_conf_fp_o3.sh /users/user42/llvmSS-reindex-cfiles \
    /users/user42/output-fuzz /users/user42/build-test/bin/clang

docker run -d --name fuzz02 --cpuset-cpus="3-5" \
  -v /users/user42/fuzz02:/users/user42/output-fuzz \
  afl-vanilla-img \
  /users/user42/24_fuzz.sh run_AFL_conf_fp_o3.sh /users/user42/llvmSS-reindex-cfiles \
    /users/user42/output-fuzz /users/user42/build-test/bin/clang

docker run -d --name fuzz03 --cpuset-cpus="6-8" \
  -v /users/user42/fuzz03:/users/user42/output-fuzz \
  afl-vanilla-img \
  /users/user42/24_fuzz.sh run_AFL_conf_fp_o3.sh /users/user42/llvmSS-reindex-cfiles \
    /users/user42/output-fuzz /users/user42/build-test/bin/clang

docker run -d --name fuzz04 --cpuset-cpus="9-11" \
  -v /users/user42/fuzz04:/users/user42/output-fuzz \
  afl-vanilla-img \
  /users/user42/24_fuzz.sh run_AFL_conf_fp_o3.sh /users/user42/llvmSS-reindex-cfiles \
    /users/user42/output-fuzz /users/user42/build-test/bin/clang

docker run -d --name fuzz05 --cpuset-cpus="12-14" \
  -v /users/user42/fuzz05:/users/user42/output-fuzz \
  afl-vanilla-img \
  /users/user42/24_fuzz.sh run_AFL_conf_fp_o3.sh /users/user42/llvmSS-reindex-cfiles \
    /users/user42/output-fuzz /users/user42/build-test/bin/clang

echo "All 5 fuzzing containers started."
# -------------------------------------------------------
# After Fuzzing to Extract Fuzz Statistics
# -------------------------------------------------------
sudo chown -R user42:user42 /users/user42
./extract_fuzz_stat_dir.sh /users/user42
tar -czvf exp12-fuzz-results.tar.gz -C /users/user42/ fuzz01 fuzz02 fuzz03 fuzz04 fuzz05
