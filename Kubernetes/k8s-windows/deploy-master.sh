#!/usr/bin/env bash

AWS_PROFILE="intapp-devopssbx_eddy.snow@intapp.com"
AWS_REGION="eu-west-1"

echo "[$(date)] - Deploying stacks to region: $AWS_REGION"
echo "[$(date)] - Uploading templates to s3"
aws s3api put-object --bucket 278942993584-eddy-scratch --key git/eddy-k8s-windows-cluster/vpc.yml --region $AWS_REGION --profile $AWS_PROFILE --body /Users/eddys/git/labs/Cloudformation/vpc.yml
aws s3api put-object --bucket 278942993584-eddy-scratch --key git/eddy-k8s-windows-cluster/ec2-k8s-master.yml --region $AWS_REGION --profile $AWS_PROFILE --body /Users/eddys/git/labs/Cloudformation/ec2-k8s-master.yml

echo "[$(date)] - vpc stack"
if [ ! $(aws cloudformation describe-stacks --region $AWS_REGION --profile $AWS_PROFILE | jq '.Stacks[].StackName' | grep eddy-vpc) ]; then
    echo "[$(date)] - Creating eddy-vpc stack"
    aws cloudformation create-stack --stack-name eddy-vpc --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-k8s-windows-cluster/vpc.yml --profile $AWS_PROFILE --region $AWS_REGION;
else
    echo "[$(date)] - Updating eddy-vpc stack"
    aws cloudformation update-stack --stack-name eddy-vpc --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-k8s-windows-cluster/vpc.yml --profile $AWS_PROFILE --region $AWS_REGION;
fi

echo "[$(date)] - master node stack"
if [ ! $(aws cloudformation describe-stacks --region $AWS_REGION --profile $AWS_PROFILE | jq '.Stacks[].StackName' | grep \"eddy-k8s-windows-master\") ]; then
    echo "[$(date)] - Creating eddy-k8s-windows-master stack"
    aws cloudformation create-stack --stack-name eddy-k8s-master --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-k8s-windows-cluster/ec2-k8s-master.yml --profile $AWS_PROFILE --region $AWS_REGION
else
    echo "[$(date)] - Updating eddy-k8s-windows-master stack"
    aws cloudformation update-stack --stack-name eddy-k8s-master --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-k8s-windows-cluster/ec2-k8s-master.yml --profile $AWS_PROFILE --region $AWS_REGION
fi
