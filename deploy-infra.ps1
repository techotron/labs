﻿param (
    [string] $gitPath = "$env:userprofile\git\labs",
    [string] $tagValueProduct,
    [string] $tagValueContact,
    [string] $awsAccessKey,
    [string] $awsSecretKey,
    [string] $region,
    [ValidateSet("vpc","repository","ecscluster","windowsEc2Asg","genericlinuxEc2Asg","dockerlinuxEc2Asg","gitlablinuxEc2Asg","postgresrds","ansible","k8sEc2Asg","k8s-kops")][array] $components,
    [string] $stackStemName,
    [string] $deploymentBucket = "722777194664-eddy-scratch",
    [ValidateSet("t2.micro","t2.small","t2.medium","t2.large")][string] $ecsClusterInstanceType,
    [string] $escClusterSize,
    [ValidateSet("amzn-ami-*amazon-ecs-optimized")][string] $hostAmiName,
    [string] $keyName,
    [ValidateSet("t2.micro","t2.small","t2.medium","t2.large")][string] $ec2AsgInstanceType,
    [ValidateSet("False","True")][string] $ec2AsgMultiAz,
    [string] $ec2AsgScaleUpSchedule = "0 9 * * *",
    [string] $ec2AsgScaleDownSchedule = "0 10 * * *",
    [ValidateSet("Windows_Server-2016-English-Nano-Base*","Windows_Server-2016-English-Full-Base*","Windows_Server-2016-English-Core-Base*","amzn-ami-hvm-*-x86_64-gp2*","ubuntu-16.04")][string] $ec2AsgImage,
    [switch] $confirmWhenStackComplete,
    [string] $dbSuffix,
    [ValidateSet("db.t2.small","db.t2.medium","db.t2.large")][String] $dbInstanceClass,
    [string] $rdsRootPass,
    [ValidateSet("True","False")][string] $rdsMultiAz,
    [ValidateSet("t2.micro","t2.small","t2.medium","t2.large")][string] $ec2AnsibleInstanceType,
    [string] $pemToInject,
    [string] $iamResourcePrefix = "eddy",
    [ValidateSet("t2.micro","t2.small","t2.medium","t2.large")][string] $ec2InstanceType
)

Set-Location $gitPath
import-module awspowershell

###################################################################################################################
#------------------ Script Wide Variables ----------------------------
###################################################################################################################

$vpcStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/vpc.yml"
$ecsRepositoryStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/ecs-repository.yml"
$ecsClusterStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/ecs-cluster.yml"
$windowsEc2AsgStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/ec2-asg-generic-windows.yml"
$genericlinuxEc2AsgStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/ec2-asg-generic-linux.yml"
$dockerlinuxEc2AsgStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/ec2-asg-docker-linux.yml"
$gitlablinuxEc2AsgStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/ec2-asg-gitlab-linux.yml"
$postgresRdsStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/rds-postgres-db.yml"
$ansibleStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/ec2-asg-ansible.yml"
$k8sStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/ec2-asg-k8s-linux.yml"
$k8sIamStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/kops-iam.yml"
$k8sKopsInstallerStackUrl = "https://s3.amazonaws.com/$deploymentBucket/git/$stackStemName/kops-installer.yml"

$deploymentScriptsPath = "$gitPath\CloudFormation"

$pemToInjectUrl = "https://s3-$region.amazonaws.com/$deploymentBucket/$pemToInject"

###################################################################################################################
#------------------------ Common Tags ----------------------
###################################################################################################################

$tagProduct = New-Object Amazon.CloudFormation.Model.Tag
$tagProduct.Key = "Product"
$tagProduct.Value = $tagValueProduct

$tagProductComponentsVpc = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsVpc.Key = "ProductComponents"
$tagProductComponentsVpc.Value = "vpc"

$tagProductComponentsEcsRepository = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsEcsRepository.Key = "ProductComponents"
$tagProductComponentsEcsRepository.Value = "ecsrepository"

$tagProductComponentsEcsCluster = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsEcsCluster.Key = "ProductComponents"
$tagProductComponentsEcsCluster.Value = "ecscluster"

$tagProductComponentsEc2Asg = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsEc2Asg.Key = "ProductComponents"
$tagProductComponentsEc2Asg.Value = "ec2asg"

$tagProductComponentsEc2 = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsEc2.Key = "ProductComponents"
$tagProductComponentsEc2.Value = "ec2"

$tagProductComponentsRds = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsRds.Key = "ProductComponents"
$tagProductComponentsRds.Value = "rds"

$tagProductComponentsIam = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsIam.Key = "ProductComponents"
$tagProductComponentsIam.Value = "iam"

$tagTeam = New-Object Amazon.CloudFormation.Model.Tag
$tagTeam.Key = "Team"
$tagTeam.Value = "Devops"

$tagEnvironment = New-Object Amazon.CloudFormation.Model.Tag
$tagEnvironment.Key = "Environment"
$tagEnvironment.Value = "lab"

$tagContact = New-Object Amazon.CloudFormation.Model.Tag
$tagContact.Key = "Contact"
$tagContact.Value = $tagValueContact

###################################################################################################################
#----------------------- Cloudformation Parameters -----------------------
###################################################################################################################

$stackNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$stackNameParam.ParameterKey = "stackName"
$stackNameParam.ParameterValue = ""

$keyPairParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$keyPairParam.ParameterKey = "keyName"
$keyPairParam.ParameterValue = $keyName

$ecsClusterInstanceTypeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ecsClusterInstanceTypeParam.ParameterKey = "instanceType"
$ecsClusterInstanceTypeParam.ParameterValue = $ecsClusterInstanceType

$ecsClusterSizeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ecsClusterSizeParam.ParameterKey = "clusterSize"
$ecsClusterSizeParam.ParameterValue = $escClusterSize

$ecsVpcStackNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ecsVpcStackNameParam.ParameterKey = "vpcStackName"
$ecsVpcStackNameParam.ParameterValue = $("$stackStemName-vpc")

$ecsClusterAmiParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ecsClusterAmiParam.ParameterKey = "ecsAmi"
$ecsClusterAmiParam.ParameterValue = ""

$ec2VpcStackNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2VpcStackNameParam.ParameterKey = "vpcStackName"
$ec2VpcStackNameParam.ParameterValue = $("$stackStemName-vpc")

$ec2AsgInstanceTypeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2AsgInstanceTypeParam.ParameterKey = "instanceType"
$ec2AsgInstanceTypeParam.ParameterValue = $ec2AsgInstanceType

$ec2AnsibleInstanceTypeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2AnsibleInstanceTypeParam.ParameterKey = "ansibleInstanceType"
$ec2AnsibleInstanceTypeParam.ParameterValue = $ec2AnsibleInstanceType

$ec2AnsiblePemToInjectParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2AnsiblePemToInjectParam.ParameterKey = "pemToInject"
$ec2AnsiblePemToInjectParam.ParameterValue = $pemToInjectUrl

$ec2AnsibleAmiParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2AnsibleAmiParam.ParameterKey = "ansibleAmi"
$ec2AnsibleAmiParam.ParameterValue = ""

$ec2AnsibleAccessKeyParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2AnsibleAccessKeyParam.ParameterKey = "accessKey"
$ec2AnsibleAccessKeyParam.ParameterValue = $awsAccessKey

$ec2AnsibleSecretKeyParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2AnsibleSecretKeyParam.ParameterKey = "secretKey"
$ec2AnsibleSecretKeyParam.ParameterValue = $awsSecretKey

$ec2MultiAzParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2MultiAzParam.ParameterKey = "multiAZ"
$ec2MultiAzParam.ParameterValue = $ec2AsgMultiAz

$ec2S3BuildBucketParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2S3BuildBucketParam.ParameterKey = "s3BuildBucket"
$ec2S3BuildBucketParam.ParameterValue = $deploymentBucket

$ec2AsgScaleUpScheduleParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2AsgScaleUpScheduleParam.ParameterKey = "scaleUpSchedule"
$ec2AsgScaleUpScheduleParam.ParameterValue = $ec2AsgScaleUpSchedule

$ec2AsgScaleDownScheduleParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2AsgScaleDownScheduleParam.ParameterKey = "scaleDownSchedule"
$ec2AsgScaleDownScheduleParam.ParameterValue = $ec2AsgScaleDownSchedule

$ec2AsgAmiParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ec2AsgAmiParam.ParameterKey = "ec2Image"
$ec2AsgAmiParam.ParameterValue = $ec2AsgImage

$rdsVpcStackNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsVpcStackNameParam.ParameterKey = "vpcStackName"
$rdsVpcStackNameParam.ParameterValue = $("$stackStemName-vpc")

$rdsDbSuffixParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsDbSuffixParam.ParameterKey = "DBSuffix"
$rdsDbSuffixParam.ParameterValue = $dbSuffix

$rdsInstanceClassParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsInstanceClassParam.ParameterKey = "rdsInstanceClass"
$rdsInstanceClassParam.ParameterValue = $dbInstanceClass

$rdsRootLoginParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsRootLoginParam.ParameterKey = "rdsInstanceRootLogin"
$rdsRootLoginParam.ParameterValue = "postgres"

$rdsRootPassParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsRootPassParam.ParameterKey = "rdsInstanceRootPassword"
$rdsRootPassParam.ParameterValue = $rdsRootPass

$rdsKmsKeyParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsKmsKeyParam.ParameterKey = "kmsKey"
$rdsKmsKeyParam.ParameterValue = "arn:aws:kms:us-east-1:722777194664:key/bca8781b-18b9-42be-830a-381b5683c876"

$rdsSnapShotIdParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsSnapShotIdParam.ParameterKey = "DBSnapshotIdentifier"
$rdsSnapShotIdParam.ParameterValue = ""

$rdsMultiAzParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsMultiAzParam.ParameterKey = "multiAZ"
$rdsMultiAzParam.ParameterValue = $rdsMultiAz

$rdsUsernameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsUsernameParam.ParameterKey = "rdsUsername"
$rdsUsernameParam.ParameterValue = ""

$rdsPasswordParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsPasswordParam.ParameterKey = "rdsPassword"
$rdsPasswordParam.ParameterValue = ""

$rdsEndpointPortParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsEndpointPortParam.ParameterKey = "rdsEndpointPort"
$rdsEndpointPortParam.ParameterValue = ""

$rdsEndpointAddressParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$rdsEndpointAddressParam.ParameterKey = "rdsEndpointAddress"
$rdsEndpointAddressParam.ParameterValue = ""

$kopsGroupNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$kopsGroupNameParam.ParameterKey = "kopsGroupName"
$kopsGroupNameParam.ParameterValue = $iamResourcePrefix

$kopsUserNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$kopsUserNameParam.ParameterKey = "kopsUserName"
$kopsUserNameParam.ParameterValue = $iamResourcePrefix

$singleEc2InstanceTypeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$singleEc2InstanceTypeParam.ParameterKey = "instanceType"
$singleEc2InstanceTypeParam.ParameterValue = $ec2InstanceType

$singleEc2AmiParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$singleEc2AmiParam.ParameterKey = "linuxImage"
$singleEc2AmiParam.ParameterValue = ""

$kopsFullUserNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$kopsFullUserNameParam.ParameterKey = "kopsFullUsername"
$kopsFullUserNameParam.ParameterValue = ""

$kopsAccessKeyParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$kopsAccessKeyParam.ParameterKey = "kopsAccessKey"
$kopsAccessKeyParam.ParameterValue = ""

$kopsSecretKeyParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$kopsSecretKeyParam.ParameterKey = "kopsSecretKey"
$kopsSecretKeyParam.ParameterValue = ""

###################################################################################################################
#----------------- Upload Deploy Scripts to S3 to simulate Jenkins build doing the same --------------
###################################################################################################################

Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Simulating Jenkins upload to S3..." -ForegroundColor Green
Get-S3Object -BucketName $deploymentBucket -KeyPrefix git/$stackStemName -AccessKey $awsAccessKey -SecretKey $awsSecretKey | foreach {Remove-S3Object -BucketName $deploymentBucket -Key $_.key -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Confirm:$false | Out-Null}
Write-S3Object -BucketName $deploymentBucket -KeyPrefix git/$stackStemName -Recurse -Folder $deploymentScriptsPath -AccessKey $awsAccessKey -SecretKey $awsSecretKey

###################################################################################################################
#--------------------- Deploy VPC -------------------------
###################################################################################################################

if ($components -contains "vpc") {

    $stackNameParam.ParameterValue = $("$stackStemName-vpc")
    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -stackName $("$stackStemName-vpc") -stackUrl $vpcStackUrl -parameters $stackNameParam -tags $tagProduct, $tagProductComponentsVpc, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-vpc") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping vpc Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy ECS Repository -------------------------
###################################################################################################################

if ($components -contains "repository") {

    $stackNameParam.ParameterValue = $("$stackStemName-ecsrepository")
    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -stackName $("$stackStemName-ecsrepository") -stackUrl $ecsRepositoryStackUrl -parameters $stackNameParam -tags $tagProduct, $tagProductComponentsEcsRepository, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-ecsrepository") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping repository Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy ECS Cluster -------------------------
###################################################################################################################

if ($components -contains "ecscluster") {

    $stackNameParam.ParameterValue = $("$stackStemName-ecscluster")
    $ecsClusterAmiParam.ParameterValue = $(& ".\Scripts\Common\deploy\get-latestami.ps1" -imageName $hostAmiName -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region)

    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -waitForStackName $("$stackStemName-vpc") -stackName $("$stackStemName-ecscluster") -stackUrl $ecsClusterStackUrl -parameters $stackNameParam, $ecsVpcStackNameParam, $keyPairParam, $ecsClusterInstanceTypeParam, $ecsClusterSizeParam, $ecsClusterAmiParam -tags $tagProduct, $tagProductComponentsEcsCluster, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-ecscluster") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping ecscluster Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy Windows EC2 ASG -------------------------
###################################################################################################################

if ($components -contains "windowsEc2Asg") {

    $stackNameParam.ParameterValue = $("$stackStemName-windowsec2asg")
    $ec2AsgAmiParam.ParameterValue = $(& ".\Scripts\Common\deploy\get-latestami.ps1" -imageName $ec2AsgImage -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region)

    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -waitForStackName $("$stackStemName-vpc") -stackName $("$stackStemName-windowsec2asg") -stackUrl $windowsEc2AsgStackUrl -parameters $stackNameParam, $ec2VpcStackNameParam, $keyPairParam, $ec2AsgInstanceTypeParam, $ec2MultiAzParam, $ec2S3BuildBucketParam, $ec2AsgAmiParam, $ec2AsgScaleUpScheduleParam, $ec2AsgScaleDownScheduleParam -tags $tagProduct, $tagProductComponentsEc2Asg, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-windowsec2asg") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping windowsEc2Asg Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy Generic Linux EC2 ASG -------------------------
###################################################################################################################

if ($components -contains "genericlinuxEc2Asg") {

    $stackNameParam.ParameterValue = $("$stackStemName-genericlinuxEc2Asg")
    $ec2AsgAmiParam.ParameterValue = $(& ".\Scripts\Common\deploy\get-latestami.ps1" -imageName $ec2AsgImage -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region)

    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -waitForStackName $("$stackStemName-vpc") -stackName $("$stackStemName-genericlinuxEc2Asg") -stackUrl $genericlinuxEc2AsgStackUrl -parameters $stackNameParam, $ec2VpcStackNameParam, $keyPairParam, $ec2AsgInstanceTypeParam, $ec2MultiAzParam, $ec2S3BuildBucketParam, $ec2AsgAmiParam, $ec2AsgScaleUpScheduleParam, $ec2AsgScaleDownScheduleParam -tags $tagProduct, $tagProductComponentsEc2Asg, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-genericlinuxEc2Asg") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping genericlinuxEc2Asg Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy Docker Linux EC2 ASG -------------------------
###################################################################################################################

if ($components -contains "dockerlinuxEc2Asg") {

    $stackNameParam.ParameterValue = $("$stackStemName-dockerlinuxEc2Asg")
    $ec2AsgAmiParam.ParameterValue = $(& ".\Scripts\Common\deploy\get-latestami.ps1" -imageName "amzn-ami-hvm-*-x86_64-gp2*" -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region)

    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -waitForStackName $("$stackStemName-vpc") -stackName $("$stackStemName-dockerlinuxEc2Asg") -stackUrl $dockerlinuxEc2AsgStackUrl -parameters $stackNameParam, $ec2VpcStackNameParam, $keyPairParam, $ec2AsgInstanceTypeParam, $ec2MultiAzParam, $ec2S3BuildBucketParam, $ec2AsgAmiParam, $ec2AsgScaleUpScheduleParam, $ec2AsgScaleDownScheduleParam -tags $tagProduct, $tagProductComponentsEc2Asg, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-dockerlinuxEc2Asg") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping dockerlinuxEc2Asg Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy K8s Linux EC2 ASG -------------------------
###################################################################################################################

if ($components -contains "k8sEc2Asg") {

    $stackNameParam.ParameterValue = $("$stackStemName-k8sEc2Asg")
    $ec2AsgAmiParam.ParameterValue = $(& ".\Scripts\Common\deploy\get-latestami.ps1" -imageName "amzn-ami-hvm-*-x86_64-gp2*" -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region)

    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -waitForStackName $("$stackStemName-vpc") -stackName $("$stackStemName-k8sEc2Asg") -stackUrl $k8sStackUrl -parameters $stackNameParam, $ec2VpcStackNameParam, $keyPairParam, $ec2AsgInstanceTypeParam, $ec2MultiAzParam, $ec2S3BuildBucketParam, $ec2AsgAmiParam, $ec2AsgScaleUpScheduleParam, $ec2AsgScaleDownScheduleParam -tags $tagProduct, $tagProductComponentsEc2Asg, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-dockerlinuxEc2Asg") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping k8sEc2Asg Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy Gitlab Linux EC2 ASG -------------------------
###################################################################################################################

if ($components -contains "gitlablinuxEc2Asg") {

    $stackNameParam.ParameterValue = $("$stackStemName-gitlablinuxEc2Asg")
    $ec2AsgAmiParam.ParameterValue = $(& ".\Scripts\Common\deploy\get-latestami.ps1" -imageName $ec2AsgImage -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region)

    $rdsUsernameParam.Value = $(& ".\Scripts\Common\deploy\get-stackoutputvalue.ps1" -stackName $("$stackStemName-postgresrds") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -exportName $("$stackStemName-postgresrds-rdsRootLogin-gitlabDb"))
    $rdsPasswordParam.Value = $(& ".\Scripts\Common\deploy\get-stackoutputvalue.ps1" -stackName $("$stackStemName-postgresrds") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -exportName $("$stackStemName-postgresrds-rdsRootPassword-gitlabDb"))
    $rdsEndpointPortParam.Value = $(& ".\Scripts\Common\deploy\get-stackoutputvalue.ps1" -stackName $("$stackStemName-postgresrds") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -exportName $("$stackStemName-postgresrds-rdsDatabaseEndpointPort-gitlabDb"))
    $rdsEndpointAddressParam.Value = $(& ".\Scripts\Common\deploy\get-stackoutputvalue.ps1" -stackName $("$stackStemName-postgresrds") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -exportName $("$stackStemName-postgresrds-rdsDatabaseEndpoint-gitlabDb"))
    
    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -waitForStackName $("$stackStemName-vpc") -stackName $("$stackStemName-gitlablinuxEc2Asg") -stackUrl $gitlablinuxEc2AsgStackUrl -parameters $stackNameParam, $ec2VpcStackNameParam, $keyPairParam, $ec2AsgInstanceTypeParam, $ec2MultiAzParam, $ec2S3BuildBucketParam, $ec2AsgAmiParam, $ec2AsgScaleUpScheduleParam, $ec2AsgScaleDownScheduleParam, $rdsUsernameParam, $rdsPasswordParam, $rdsEndpointPortParam, $rdsEndpointAddressParam -tags $tagProduct, $tagProductComponentsEc2Asg, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-gitlablinuxEc2Asg") -Status CREATE_COMPLETE, UPDATE_COMPLETE -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Region $region -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping gitlablinuxEc2Asg Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy Postgres RDS -------------------------
###################################################################################################################

if ($components -contains "postgresrds") {

    $stackNameParam.ParameterValue = $("$stackStemName-postgresrds")
    
    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -waitForStackName $("$stackStemName-vpc") -stackName $("$stackStemName-postgresrds") -stackUrl $postgresRdsStackUrl -parameters $stackNameParam, $rdsVpcStackNameParam, $rdsDbSuffixParam, $rdsInstanceClassParam, $rdsRootLoginParam, $rdsRootPassParam, $rdsKmsKeyParam, $rdsSnapShotIdParam, $rdsMultiAzParam -tags $tagProduct, $tagProductComponentsRds, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-postgresrds") -Status CREATE_COMPLETE, UPDATE_COMPLETE -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Region $region -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping postgresrds Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy Ansible -------------------------
###################################################################################################################

if ($components -contains "ansible") {

    $stackNameParam.ParameterValue = $("$stackStemName-ansible")
    $ec2AsgAmiParam.ParameterValue = $(& ".\Scripts\Common\deploy\get-latestami.ps1" -imageName $ec2AsgImage -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region)
    $ec2AnsibleAmiParam.ParameterValue = $(& ".\Scripts\Common\deploy\get-latestami.ps1" -imageName ubuntu-16.04 -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region)
        
    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -waitForStackName $("$stackStemName-vpc") -stackName $("$stackStemName-ansible") -stackUrl $ansibleStackUrl -parameters $stackNameParam, $ec2VpcStackNameParam, $keyPairParam, $ec2AsgInstanceTypeParam, $ec2AnsibleInstanceTypeParam, $ec2MultiAzParam, $ec2S3BuildBucketParam, $ec2AsgAmiParam, $ec2AsgScaleUpScheduleParam, $ec2AsgScaleDownScheduleParam, $ec2AnsiblePemToInjectParam, $ec2AnsibleAmiParam, $ec2AnsibleAccessKeyParam, $ec2AnsibleSecretKeyParam -tags $tagProduct, $tagProductComponentsEc2Asg, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800
    
    if ($confirmWhenStackComplete) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
        Wait-CFNStack -StackName $("$stackStemName-ansible") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping ansible Stack deployment..." -ForegroundColor darkyellow
    
}

###################################################################################################################
#--------------------- Deploy Kops K8s -------------------------
###################################################################################################################

if ($components -contains "k8s-kops") {

    $stackNameParam.ParameterValue = $("$stackStemName-kops-k8s-iam")
    $singleEc2AmiParam.ParameterValue = $(& ".\Scripts\Common\deploy\get-latestami.ps1" -imageName ubuntu-16.04 -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region)
    
    # Deploy the IAM account needed to deploy K8s using KOPs:    
    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -stackName $("$stackStemName-kops-k8s-iam") -stackUrl $k8sIamStackUrl -parameters $stackNameParam, $kopsGroupNameParam, $kopsUserNameParam -tags $tagProduct, $tagProductComponentsIam, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800
    
    # Wait for IAM stack to complete before gathering outputs:
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
    Wait-CFNStack -StackName $("$stackStemName-kops-k8s-iam") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green
        
    $kopsFullUserNameParam.ParameterValue = & ".\Scripts\Common\deploy\get-stackoutputvalue.ps1" -stackName $("$stackStemName-kops-k8s-iam") -exportName $("$stackStemName-kops-k8s-iam" + "-kopsUsername") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
    $kopsAccessKeyParam.ParameterValue = & ".\Scripts\Common\deploy\get-stackoutputvalue.ps1" -stackName $("$stackStemName-kops-k8s-iam") -exportName $("$stackStemName-kops-k8s-iam" + "-kopsUserAccessKey") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
    $kopsSecretKeyParam.ParameterValue = & ".\Scripts\Common\deploy\get-stackoutputvalue.ps1" -stackName $("$stackStemName-kops-k8s-iam") -exportName $("$stackStemName-kops-k8s-iam" + "-kopsUserSecretKey") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

    # Deploy the installer instance after waiting for the VPC stack to complete:
    & ".\Scripts\Common\deploy\deploy-cfnstack.ps1" -waitForStackName $("$stackStemName-vpc") -stackName $("$stackStemName-kops-k8s-installer") -stackUrl $k8sKopsInstallerStackUrl -parameters $stackNameParam, $ecsVpcStackNameParam, $keyPairParam, $singleEc2InstanceTypeParam, $singleEc2AmiParam, $kopsFullUserNameParam, $kopsAccessKeyParam, $kopsSecretKeyParam -tags $tagProduct, $tagProductComponentsEc2, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -cfnWaitTimeOut 1800

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack deployment to complete..." -ForegroundColor darkyellow
    Wait-CFNStack -StackName $("$stackStemName-kops-k8s-installer") -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout 1800 -ErrorAction SilentlyContinue | Out-Null    
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack deployment complete..." -ForegroundColor green

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping kops-k8s Stack deployment..." -ForegroundColor darkyellow
    
}
