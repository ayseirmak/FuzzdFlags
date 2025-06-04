
#!/bin/bash
# This script is for setting up a local environment for the input corpus coverage with -O2 flag.
sudo useradd -m -d /users/user42 -s /bin/bash user42
sudo passwd user42
sudo usermod -aG sudo user42
sudo usermod -aG kclsystemfuzz-PG user42
sudo chown -R user42:user42 /users/user42
sudo chmod 777 /users/user42
sudo apt-get update && sudo apt-get upgrade -y

su - user42
# I need to add coveragescripts here (wget)
sudo chown -R user42:user42 /users/user42/
chmod 777 *.sh

./0-install-compilers-local.sh 
mkdir -p coverage
./1-clone-llvm.sh /users/user42/coverage 19
./2-llvm-cov-install.sh /users/user42/coverage <TMP_SOURCE_FOLDER> 1 > /tmp/llvm1-cov-install.log 2>&1 & 
./2-llvm-cov-install.sh /users/user42/coverage <TMP_SOURCE_FOLDER> 2 > /tmp/llvm2-cov-install.log 2>&1 &

git clone https://github.com/google/graphicsfuzz.git
cd graphicsfuzz/gfauto/
python3 --version # 3.10.2
vi dev_shell.sh.template
EDIT TO YOUR LOCAL VERSION of Python3: PYTHON=${PYTHON-python3.6} to PYTHON=${PYTHON-python3.10}
rm Pipfile.lock (if Python3.8 or above)
./dev_shell.sh.template
cd ../..

wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v1.0-alpha/llvmSS-reindex-after-Cmin.tar.gz
tar -zxvf llvmSS-reindex-after-Cmin.tar.gz

mkdir -p /users/user42/fuzzdflags-1-seed
mkdir -p /users/user42/fuzzdflags-30-seed

wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v5.0/exp21-fuzzdflags-1seed-queue.tar.gz
tar -zxvf exp21-fuzzdflags-1seed-queue.tar.gz --strip-components=1 -C /users/user42/fuzzdflags-1-seed
wget https://github.com/ayseirmak/FuzzdFlags/releases/download/v5.0/exp22-fuzzdflags-30seed-queue.tar.gz
tar -zxvf exp22-fuzzdflags-30seed-queue.tar.gz --strip-components=1 -C /users/user42/fuzzdflags-30-seed

mkdir -p coverage-measurement
cd coverage-measurement
mkdir -p fuzzdflags-cov/fuzzdflags-1seed-cov fuzzdflags-cov/fuzzdflags-30seed-cov
cd ~

cd /users/user42/coverage-measurement/fuzzdflags-cov/fuzzdflags-1seed-cov
nohup /users/user42/3-gfauto-fuzzdflags.sh /users/user42/fuzzdflags-1-seed /users/user42/coverage/llvm-clang-1 > exp21-fuzzDflags-1seed-cov.log 2>&1 &

cd /users/user42/coverage-measurement/fuzzdflags-cov/fuzzdflags-30seed-cov
nohup /users/user42/3-gfauto-fuzzdflags.sh /users/user42/fuzzdflags-30-seed /users/user42/coverage/llvm-clang-2 > exp22-fuzzdflags-30seed-cov.log 2>&1 &

cd ~
nohup /users/user42/4-cov-analysis-multidir.sh ~/coverage-measurement/fuzzdflags-cov/fuzzdflags-1seed-cov /users/user42/coverage/llvm-clang-1 table_line_cov_1seed.csv > cov-mes-fuzzdflag-1seed.log 2>&1 &
nohup /users/user42/4-cov-analysis-multidir.sh ~/coverage-measurement/fuzzdflags-cov/fuzzdflags-30seed-cov /users/user42/coverage/llvm-clang-2 table_line_cov_10seed.csv > cov-mes-fuzzdflag-10seed.log 2>&1 &

tar -czvf fuzzdflags-cov-analysis.tar.gz -C /users/user42/coverage-measurement/ fuzzdflags-cov
tar -czvf cov-fuzzdflags-1seed-result.tar.gz -C /users/user42/coverage/llvm-clang-1 coverage_processed coverage_gcda_files
tar -czvf cov-fuzzdflags-30seed-result.tar.gz -C /users/user42/coverage/llvm-clang-2 coverage_processed coverage_gcda_files
