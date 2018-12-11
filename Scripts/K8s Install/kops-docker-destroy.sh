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

echo "Delete kubectl config file which was added to the bucket manually..."
aws s3api delete-object --bucket $KOPS_BUCKET --key $KOPS_NAME/.kube/config --profile $AWS_PROFILE

echo "Destroy cluster..."
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
kops delete cluster --name $KOPS_NAME --state $KOPS_STATE_STORE --yes