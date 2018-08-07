# Install Minikube on an Ubuntu Server

## Setup Keys
```
mkdir ~/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAgxyjoaP1Jd0w9c8PnBW960eZBSSurEY/HU/cYGY2SF54RPrb96n9GNoVnQ8vsCLuCEemTSLeFwkYWvwuhLGpL2/5u9VdSAfVw1EIzH06bS3/vMNs+wiKEGFKO/qj6SyYFl4s1qQHM+5nHOAPe2YrMrSVr0BEjTLTd20i+XFSPw1oeKizVu8ZTMx5JVE8wxEqRNYqPJCi4zwnAHsB/omVzg0gt6p7M4PidabKeguJusf2PCflMT0ep8fVZQ/MAuzU7UQLEV+0TcywIe1tcf6tf3MU47LWX+IcR+7Va08cur1rTqdJZIotMvW3favXOMw0sWpMthLmz6r7/zAuoKb51w== eddy@k8s-minikube-ubuntu" >> ~/.ssh/authorized_keys
```

## Download and Install docker ce
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce
```

### Add user to docker group
```
sudo usermod -aG docker ${USER}
```

## Install Virtual box as the hypervisor for minikube
```
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
sudo sh -c 'echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" >> /etc/apt/sources.list.d/virtualbox.list'
sudo apt update
sudo apt-get -y install gcc make linux-headers-$(uname -r) dkms
sudo apt update
sudo apt-get install virtualbox-5.2
```

## Download minikube binaries and move to local path
```
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.28.2/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

## Download kubectl binaries and move to local path
```
curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/releases/$(curl -s https://storage.googleapis.com/kubernetes-release/releases/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && sudo mv kubectl /usr/local/bin/
```

## Install bash-completion

```
sudo apt-get -y install bash-completion
```

## Add the following to ~/.bashrc (running in current shell session to enable completion in terminal immediately)
source <(kubectl completion bash)










