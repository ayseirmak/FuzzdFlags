# ISSTA_2025_Tool
###  Step1 - Install Docker on Ubuntu (ARM64) 🚀 

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

###  Step2 - Create Dockerfile
mkdir docker_project  
cd docker_project  
create your dockerfile  
**NOTE: On Ubuntu 22.04 (Jammy), the gcov binary is included with the gcc package. Therefore, you don’t need to install gcov-11 separately.**

### Step 3 - Build the Docker Image 🏗️ 
docker build -t afl-clang-env .  
docker images  
<img width="794" alt="image" src="https://github.com/user-attachments/assets/066d521a-8276-4228-843f-b124bb190f46" />  
docker run -it --name afl-clang-container afl-clang-env
<img width="954" alt="image" src="https://github.com/user-attachments/assets/006319a0-25af-4761-8c5e-46d7ab6f7919" />

### Step 4 - Start and Connect Docker Image
docker start container-name-or-id  
docker exec -it container-name-or-id /bin/bash 

### Step 5 - Modify Docker Image
docker commit container-id new-image-name    
sudo docker commit afl-clang-container afl-clang-env:modified-clang2-driver    






