﻿& "$env:userprofile\git\labs\deploy-infra.ps1" `
    -gitPath "$env:userprofile\git\labs" `
    -tagValueProduct "lab" `
    -tagValueContact "eddysnow@googlemail.com" `
    -awsAccessKey $(get-content C:\temp\snowcoAccessKey.txt -ErrorAction SilentlyContinue) `
    -awsSecretKey $(get-content C:\temp\snowcoSecretKey.txt -ErrorAction SilentlyContinue) `
    -region "eu-west-1" `
    -components gitlablinuxEc2Asg `
    -stackStemName "gitlab" `
    -deploymentBucket "722777194664-eddy-scratch" `
    -ecsClusterInstanceType t2.micro `
    -escClusterSize 1 `
    -hostAmiName amzn-ami-*amazon-ecs-optimized `
    -keyName eddy-lab@gmail.com `
    -ec2AsgInstanceType t2.small `
    -ec2AsgMultiAz False `
    -ec2AsgImage amzn-ami-hvm-*-x86_64-gp2* `
    -confirmWhenStackComplete `
    -dbSuffix gitlabDb `
    -dbInstanceClass db.t2.small `
    -rdsRootPass Password01 `
    -rdsMultiAz False