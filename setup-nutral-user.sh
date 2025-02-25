sudo useradd user42
sudo passwd user42
sudo usermod -aG sudo user42
sudo mkdir -p /users/user42
sudo usermod -d /users/user42 user42

sudo usermod -aG kclsystemfuzz-PG user42
sudo chown user42:kclsystemfuzz-PG /users/user42
sudo chmod 755 /users/user42

sudo apt-get install software-properties-common
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt install python3-pip
sudo apt-get install libssl-dev openssl
sudo apt-get install libgdbm-dev libdb-dev
sudo pip install coverage
sudo pip install numpy scikit-learn xgboost

sudo chown -R user42:user42 /users/user42/.cache/pip
sudo apt install python3.10-venv

cd /users/user42
sudo fallocate -l 4G swapfile
sudo chmod 600 swapfile 
sudo mkswap swapfile 
sudo swapon swapfile
sudo swapon --show

echo "All Okay. Run: su - user42"
