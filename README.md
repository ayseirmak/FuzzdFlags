# FloatingPoint_and_CompilerTesting_Coverage
####  Install Docker on Ubuntu (ARM64)

**Update Package Index**   
sudo apt-get update

**Install Prerequisites**  
sudo apt-get install -y \\  
    apt-transport-https \\  
    ca-certificates \\  
    curl \\  
    software-properties-common \\  
    gnupg

**Add Docker's Official GPG Key**        
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

**Add Docker Repository for ARM64**   
echo \\  
  "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \\  
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

**Install Docker Engine**   
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

**Verify Docker Installation**   
sudo docker --version  
Docker version 27.4.0, build bde2b89
