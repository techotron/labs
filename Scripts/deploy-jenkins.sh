#!/usr/bin/env bash

echo "[$(date)] - Uploading template to s3"
aws s3api put-object --bucket 278942993584-eddy-scratch --key git/eddy-jenkins/ec2-asg-docker-jenkins-linux.yml --region eu-west-1 --profile intapp-devopssbx_eddy.snow@intapp.com --body /Users/eddys/git/labs/Cloudformation/ec2-asg-docker-jenkins-linux.yml
if [ ! $(aws cloudformation describe-stacks --region eu-west-1 --profile intapp-devopssbx_eddy.snow@intapp.com | jq '.Stacks[].StackName' | grep eddy-jenkins) ]; then
    echo "[$(date)] - Creating eddy-jenkins stack"
    aws cloudformation create-stack --stack-name eddy-jenkins --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-jenkins/ec2-asg-docker-jenkins-linux.yml --profile intapp-devopssbx_eddy.snow@intapp.com --region eu-west-1 --capabilities CAPABILITY_IAM;
else
    echo "[$(date)] - Updating eddy-jenkins stack"
    aws cloudformation update-stack --stack-name eddy-jenkins --template-url https://s3-eu-west-1.amazonaws.com/278942993584-eddy-scratch/git/eddy-jenkins/ec2-asg-docker-jenkins-linux.yml --profile intapp-devopssbx_eddy.snow@intapp.com --region eu-west-1 --capabilities CAPABILITY_IAM;
fi