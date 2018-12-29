#!/usr/bin/env bash

AWS_PROFILE="intapp-devopssbx_eddy.snow@intapp.com"
AWS_REGION="eu-west-1"

echo "[$(date)] - Deploying stacks to region: $AWS_REGION"
echo "[$(date)] - Uploading templates to s3"
aws s3api put-object --bucket 278942993584-eddy-scratch --key git/eddy-jenkins/vpc.yml --region $AWS_REGION --profile $AWS_PROFILE --body /Users/eddys/git/labs/Cloudformation/vpc.yml
aws s3api put-object --bucket 278942993584-eddy-scratch --key git/eddy-jenkins/efs-volume.yml --region $AWS_REGION --profile $AWS_PROFILE --body /Users/eddys/git/labs/Cloudformation/efs-volume.yml
aws s3api put-object --bucket 278942993584-eddy-scratch --key git/eddy-jenkins/ec2-asg-docker-jenkins-linux.yml --region $AWS_REGION --profile $AWS_PROFILE --body /Users/eddys/git/labs/Cloudformation/ec2-asg-docker-jenkins-linux.yml

echo "[$(date)] - vpc stack"
if [ ! $(aws cloudformation describe-stacks --region $AWS_REGION --profile $AWS_PROFILE | jq '.Stacks[].StackName' | grep eddy-vpc) ]; then
    echo "[$(date)] - Creating eddy-vpc stack"
    aws cloudformation create-stack --stack-name eddy-vpc --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-jenkins/vpc.yml --profile $AWS_PROFILE --region $AWS_REGION;
else
    echo "[$(date)] - Updating eddy-vpc stack"
    aws cloudformation update-stack --stack-name eddy-vpc --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-jenkins/vpc.yml --profile $AWS_PROFILE --region $AWS_REGION;
fi

echo "[$(date)] - efs stack"
if [ ! $(aws cloudformation describe-stacks --region $AWS_REGION --profile $AWS_PROFILE | jq '.Stacks[].StackName' | grep eddy-vpc) ]; then
    echo "[$(date)] - Creating eddy-efs stack"
    aws cloudformation create-stack --stack-name eddy-efs --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-jenkins/efs-volume.yml --profile $AWS_PROFILE --region $AWS_REGION;
else
    echo "[$(date)] - Updating eddy-efs stack"
    aws cloudformation update-stack --stack-name eddy-efs --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-jenkins/efs-volume.yml --profile $AWS_PROFILE --region $AWS_REGION;
fi

echo "[$(date)] - jenkins asg stack"
if [ ! $(aws cloudformation describe-stacks --region $AWS_REGION --profile $AWS_PROFILE | jq '.Stacks[].StackName' | grep eddy-jenkins) ]; then
    echo "[$(date)] - Creating eddy-jenkins stack"
    aws cloudformation create-stack --stack-name eddy-jenkins --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-jenkins/ec2-asg-docker-jenkins-linux.yml --profile $AWS_PROFILE --region $AWS_REGION --capabilities CAPABILITY_IAM;
else
    echo "[$(date)] - Updating eddy-jenkins stack"
    aws cloudformation update-stack --stack-name eddy-jenkins --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-jenkins/ec2-asg-docker-jenkins-linux.yml --profile $AWS_PROFILE --region $AWS_REGION --capabilities CAPABILITY_IAM;
fi