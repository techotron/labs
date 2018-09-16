#!/bin/bash
# Script by Edward Snow
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
    AWS_ACCESSKEY=${THIS_SHOULD_BE_A_SUB_IN_CFN}
    AWS_SECRETKEY=${THIS_SHOULD_BE_A_SUB_IN_CFN}
    AWS_REGION=${THIS_SHOULD_BE_A_SUB_IN_CFN}
    KOPS_IAM_USER=${THIS_SHOULD_BE_A_SUB_IN_CFN}
fi

echo "Creating default AWS credentials file..."
sudo [ -d ~/.aws ] || mkdir ~/.aws
sudo cat >~/.aws/credentials <<EOL
[default]
aws_access_key_id = $AWS_ACCESSKEY
aws_secret_access_key = $AWS_SECRETKEY
region = $AWS_REGION
EOL

echo "Creating IAM creation script..."
sudo cat >~/kops-iam.sh <<EOL
sudo aws iam create-group --group-name $KOPS_IAM_USER
sudo aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --group-name $KOPS_IAM_USER
sudo aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --group-name $KOPS_IAM_USER
sudo aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess --group-name $KOPS_IAM_USER
sudo aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/IAMFullAccess --group-name $KOPS_IAM_USER
sudo aws iam attach-group-policy --policy-arn arn:aws:iam::aws:policy/AmazonVPCFullAccess --group-name $KOPS_IAM_USER
sudo aws iam create-user --user-name $KOPS_IAM_USER
sudo aws iam add-user-to-group --user-name $KOPS_IAM_USER --group-name $KOPS_IAM_USER
sudo aws iam create-access-key --user-name $KOPS_IAM_USER
EOL

echo "Chmod-ing IAM creation script to execute..."
sudo chmod +x ~/kops-iam.sh

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

echo "Create new KOPS IAM account..."
sudo ~/kops-iam.sh > kops-iam.json

echo "Change default aws credential file to use new KOPS account..."
unset AWS_ACCESSKEY
unset AWS_SECRETKEY
AWS_ACCESSKEY=$(cat ~/kops-iam.json | jq -r '.AccessKey.AccessKeyId' | grep -v "null")
AWS_SECRETKEY=$(cat ~/kops-iam.json | jq -r '.AccessKey.SecretAccessKey' | grep -v "null")

sudo cat >~/.aws/credentials <<EOL
[default]
aws_access_key_id = $AWS_ACCESSKEY
aws_secret_access_key = $AWS_SECRETKEY
region = $AWS_REGION
EOL

AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

echo "Create S3 bucket to store cluster state..."
sudo aws s3api create-bucket --bucket eddy-kops-test-state-store --region us-east-1
sudo aws s3api put-bucket-versioning --bucket eddy-kops-test-state-store  --versioning-configuration Status=Enabled

echo "Set KOPS creation environment variables..."
KOPS_NAME="eddy-kops.k8s.local"
KOPS_STATE_STORE="s3://eddy-kops-test-state-store"
AWS_AZ0=$(aws ec2 describe-availability-zones | jq -r '.AvailabilityZones[0].ZoneName')
AWS_AZ1=$(aws ec2 describe-availability-zones | jq -r '.AvailabilityZones[1].ZoneName')

echo "Create KOPS secret key..."
sudo kops create secret --name $KOPS_NAME --state $KOPS_STATE_STORE sshpublickey root -i ~/.ssh/id_rsa.pub
echo "Create KOPS cluster config..."
sudo kops create cluster --zones $AWS_AZ0 --name $KOPS_NAME --state $KOPS_STATE_STORE
echo "Create KOPS cluster in AWS..."
sudo kops update cluster --name $KOPS_NAME --state $KOPS_STATE_STORE --ssh-public-key ~/.ssh/id_rsa.pub --yes

unset AWS_ACCESSKEY
unset AWS_SECRETKEY
unset DISTRO
unset HOST

# Delete cluster: sudo kops delete cluster --name $KOPS_NAME --state $KOPS_STATE_STORE --yes