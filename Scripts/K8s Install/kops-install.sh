#!/bin/bash
# Source for instructions: https://github.com/kubernetes/kops/blob/master/docs/aws.md

DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr "[:upper:]" "[:lower:]" | tr -d '"')
HOST=$(hostname)

echo "Creating SSH key..."
sudo [ -d ~/.ssh ] || mkdir ~/.ssh
sudo ssh-keygen -t rsa -N 'id_rsa' -f ~/.ssh/id_rsa

echo "Setting environment variables..."
if [ "$HOST" == "EDDY-LAPTOP1" ]; then
    AWS_ACCESSKEY=$(cat /mnt/c/temp/awsAccessKey.txt)
    AWS_SECRETKEY=$(cat /mnt/c/temp/awsSecretKey.txt)
    AWS_REGION="eu-west-1"
    KOPS_IAM_USER="kops-eddy"
else
    AWS_ACCESSKEY=$(aws cloudformation describe-stacks --stack-name k8s-kops-k8s-iam | jq -r '.Stacks[0].Outputs[]|select(.OutputKey=="kopsUserAccessKey").OutputValue')
    AWS_SECRETKEY=$(aws cloudformation describe-stacks --stack-name k8s-kops-k8s-iam | jq -r '.Stacks[0].Outputs[]|select(.OutputKey=="kopsUserSecretKey").OutputValue')
    AWS_REGION=$(aws configure get region)
    KOPS_IAM_USER=$(aws cloudformation describe-stacks --stack-name k8s-kops-k8s-iam | jq -r '.Stacks[0].Outputs[]|select(.OutputKey=="kopsUserName").OutputValue')
fi

echo "Creating default AWS credentials file..."
if [ "$HOST" == "EDDY-LAPTOP1" ]; then
sudo [ -d ~/.aws ] || mkdir ~/.aws
sudo cat >~/.aws/credentials <<EOL
[default]
aws_access_key_id = $AWS_ACCESSKEY
aws_secret_access_key = $AWS_SECRETKEY
region = $AWS_REGION
EOL
else
    echo "EC2 instance - credentials file already exists..."
fi

echo "Starting installation..."
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

    echo "Installing awscli..."
    sudo pip install awscli
elif [ "$DISTRO" == "centos" ]; then
    echo "centos"
fi

echo "Create S3 bucket to store cluster state..."
sudo aws s3api create-bucket --bucket eddy-kops-test-state-store --region us-east-1
sudo aws s3api put-bucket-versioning --bucket eddy-kops-test-state-store  --versioning-configuration Status=Enabled

echo "Set KOPS creation environment variables..."
KOPS_NAME="eddy-kops.k8s.local"
KOPS_STATE_STORE="s3://eddy-kops-test-state-store"
AWS_AZ0=$(aws ec2 describe-availability-zones | jq -r '.AvailabilityZones[0].ZoneName')
AWS_AZ1=$(aws ec2 describe-availability-zones | jq -r '.AvailabilityZones[1].ZoneName')
MASTER_SEC_GROUP=$(aws cloudformation describe-stacks --stack-name k8s-vpc | jq -r '.Stacks[0].Outputs[]|select(.OutputKey=="k8s-vpc-externalssh-securitygroup").OutputValue')

echo "Create KOPS secret key..."
sudo kops create secret --name $KOPS_NAME --state $KOPS_STATE_STORE sshpublickey root -i ~/.ssh/id_rsa.pub
echo "Create KOPS cluster config..."
sudo kops create cluster --zones $AWS_AZ0,$AWS_AZ1 --name $KOPS_NAME --state $KOPS_STATE_STORE --node-count 3 --node-size t2.small --master-size t2.small --master-security-groups $MASTER_SEC_GROUP
echo "Create KOPS cluster in AWS..."
sudo kops update cluster --name $KOPS_NAME --state $KOPS_STATE_STORE --ssh-public-key ~/.ssh/id_rsa.pub --yes

unset AWS_ACCESSKEY
unset AWS_SECRETKEY
unset DISTRO
unset HOST

# Delete cluster: sudo kops delete cluster --name $KOPS_NAME --state $KOPS_STATE_STORE --yes