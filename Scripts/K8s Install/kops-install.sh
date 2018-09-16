#!/bin/bash

DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr "[:upper:]" "[:lower:]" | tr -d '"')
if [ "$DISTRO" == "ubuntu" ]; then
    echo "Installing KOPS on Ubuntu..."
    echo "Running updates and installing dependancies..."
    sudo apt-get update
    sudo apt-get install -y python-pip

    echo "Installing KOPS binaries..."
    sudo wget -O kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
    sudo chmod +x ./kops
    sudo mv ./kops /usr/local/bin/

    echo "Installing kubectl..."
    sudo wget -O kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    sudo chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl

elif [ "$DISTRO" == "centos" ]; then
    echo "centos"
fi
unset DISTRO
