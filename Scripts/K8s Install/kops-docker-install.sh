#!/usr/bin/env bash
# Requires kops-base image and awscli installed with profile
## curl https://raw.githubusercontent.com/techotron/labs/master/Docker/kops-base/Dockerfile -o Dockerfile
## docker build -t kops-base:0.0.1 .

# Change the value of the AWS_PROFILE variable to suit your needs

AWS_PROFILE="intapp-devopssbx_eddy.snow@intapp.com"
AK=$(aws configure get aws_access_key_id --profile $AWS_PROFILE)
SK=$(aws configure get aws_secret_access_key --profile $AWS_PROFILE)
AWS_REGION="eu-west-1"
KOPS_IAM_USER="eddy-kops-user"
KOPS_BUCKET="eddy-k8s-clusterstorage"
KOPS_BUCKET_REG="us-east-1"

KOPS_NAME="eddy-kops.k8s.local"
KOPS_STATE_STORE="s3://$KOPS_BUCKET"
AWS_AZ0=$(aws ec2 describe-availability-zones | jq -r '.AvailabilityZones[0].ZoneName')
AWS_AZ1=$(aws ec2 describe-availability-zones | jq -r '.AvailabilityZones[1].ZoneName')

echo "Export keys..."
docker run kops-base:0.0.1 cat /root/.ssh/id_rsa.pub > ~/.ssh/eddy-kops-test_id_rsa.pub
docker run kops-base:0.0.1 cat /root/.ssh/id_rsa > ~/.ssh/eddy-kops-test_id_rsa

echo "Create bucket: $KOPS_BUCKET..."
docker run \
    -e AWS_ACCESS_KEY_ID=$AK \
    -e AWS_SECRET_ACCESS_KEY=$SK \
    -e AWS_REGION=$AWS_REGION \
    -e KOPS_IAM_USER=$KOPS_IAM_USER \
    -e KOPS_BUCKET=$KOPS_BUCKET \
    -e KOPS_BUCKET_REG=$KOPS_BUCKET_REG \
    kops-base:0.0.1 \
aws s3api create-bucket --bucket $KOPS_BUCKET --region $KOPS_BUCKET_REG

echo "Enable versioning for bucket: $KOPS_BUCKET"
docker run \
    -e AWS_ACCESS_KEY_ID=$AK \
    -e AWS_SECRET_ACCESS_KEY=$SK \
    -e AWS_REGION=$AWS_REGION \
    -e KOPS_IAM_USER=$KOPS_IAM_USER \
    -e KOPS_BUCKET=$KOPS_BUCKET \
    -e KOPS_BUCKET_REG=$KOPS_BUCKET_REG \
    kops-base:0.0.1 \
aws s3api put-bucket-versioning --bucket $KOPS_BUCKET --versioning-configuration Status=Enabled

echo "Create KOPS cluster config..."
docker run \
    -e AWS_ACCESS_KEY_ID=$AK \
    -e AWS_SECRET_ACCESS_KEY=$SK \
    -e AWS_REGION=$AWS_REGION \
    -e KOPS_IAM_USER=$KOPS_IAM_USER \
    -e KOPS_BUCKET=$KOPS_BUCKET \
    -e KOPS_BUCKET_REG=$KOPS_BUCKET_REG \
    -e KOPS_NAME=$KOPS_NAME \
    -e KOPS_STATE_STORE=$KOPS_STATE_STORE \
    -e AWS_AZ0=$AWS_AZ0 \
    -e AWS_AZ1=$AWS_AZ1 \
    kops-base:0.0.1 \
kops create cluster --zones $AWS_AZ0,$AWS_AZ1 --name $KOPS_NAME --state $KOPS_STATE_STORE --node-count 3 --node-size t2.micro --master-size t2.small

echo "Create KOPS secret key..."
docker run \
    -e AWS_ACCESS_KEY_ID=$AK \
    -e AWS_SECRET_ACCESS_KEY=$SK \
    -e AWS_REGION=$AWS_REGION \
    -e KOPS_IAM_USER=$KOPS_IAM_USER \
    -e KOPS_BUCKET=$KOPS_BUCKET \
    -e KOPS_BUCKET_REG=$KOPS_BUCKET_REG \
    -e KOPS_NAME=$KOPS_NAME \
    -e KOPS_STATE_STORE=$KOPS_STATE_STORE \
    -e AWS_AZ0=$AWS_AZ0 \
    -e AWS_AZ1=$AWS_AZ1 \
    kops-base:0.0.1 \
kops create secret --name $KOPS_NAME --state $KOPS_STATE_STORE sshpublickey root -i /root/.ssh/id_rsa.pub

echo "Create KOPS cluster in AWS and save config to S3..."
docker run \
    -e AWS_ACCESS_KEY_ID=$AK \
    -e AWS_SECRET_ACCESS_KEY=$SK \
    -e AWS_REGION=$AWS_REGION \
    -e KOPS_IAM_USER=$KOPS_IAM_USER \
    -e KOPS_BUCKET=$KOPS_BUCKET \
    -e KOPS_BUCKET_REG=$KOPS_BUCKET_REG \
    -e KOPS_NAME=$KOPS_NAME \
    -e KOPS_STATE_STORE=$KOPS_STATE_STORE \
    -e AWS_AZ0=$AWS_AZ0 \
    -e AWS_AZ1=$AWS_AZ1 \
    kops-base:0.0.1 \
/bin/bash -c "kops update cluster --name $KOPS_NAME --state $KOPS_STATE_STORE --ssh-public-key /root/.ssh/id_rsa.pub --yes \
&& aws s3api put-object --bucket $KOPS_BUCKET --key $KOPS_NAME/.kube/config --body /root/.kube/config"

echo "Downloading kubectl config file..."
aws s3api get-object --bucket $KOPS_BUCKET --key $KOPS_NAME/.kube/config ~/.kube/$KOPS_NAME --profile $AWS_PROFILE

echo "Adding config file to KUBECONFIG env var..."
unset KUBECONFIG
export KUBECONFIG=~/.kube/config:~/.kube/$KOPS_NAME
kubectl config use-context $KOPS_NAME
echo "You are ready to start using your new cluster! Go nuts!"