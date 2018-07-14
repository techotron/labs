import-module awspowershell

remove-variable region -Force -ErrorAction SilentlyContinue
remove-variable awsProfile -Force -ErrorAction SilentlyContinue


if (Test-Path C:\users\eddy) {

    $profileDir = "eddy"

} elseif (Test-Path C:\users\eddys) {

    $profileDir = "eddys"

}

set-location c:\

###################################################################################################################
#------------------ Deployment Control ----------------------------
###################################################################################################################

$downloadPackagesFromArtifactory = 1
$simulateJenkinsUploadToS3 = 1                # This is to simulate the scripts getting uploaded to S3 after they're built.
$uploadPackage = 1                            # This is to upload the package to S3 once it's been bundled, for the EB stack to use
$deployVPC = 1
$deployEC = 0
$deployEB = 1
$deployDataRds = 1
$deployDataRdsFromLatestSnapshot = 0
$deployDataDatabase = 1
$deployCaptureRds = 1
$deployCaptureRdsFromLatestSnapshot = 0
$deployCaptureDatabase = 1
$processSsrsFiles = 1
$deploySsrsAsg = 1
$deployDynamoDb = 1
$deploySqs = 1

$updateDnsRecords = 1

###################################################################################################################
#------------------ Script Wide Variables ----------------------------
###################################################################################################################

$templatePath = "C:\Temp\" # Holding area for files
$templateBuildFolder = "$templatePath`git\build"
$branch = "latest"
$deploymentPackageRoot = $($templatePath + $branch) # Path to the location of the deployment packages, downloaded from Artifactory
$deploymentScriptsPath = "C:\users\$profileDir\git\timecloud-scripts\Cloud Formation Templates\Convergence" # Location of deployment scripts used to upload to S3 in Jenkins simulation upload
$artifactoryApiKey = get-content C:\temp\artifactoryApiKey.txt -ErrorAction SilentlyContinue
$artifactoryRootUrl = "https://artifactory.dev.intapp.com/artifactory/generic-time-releases/"
$packagesToDownload = @("time.admin.tool", "time.server", "time.database", "time.capture.database", "time.server.plugins", "time.capture.website", "time.api.service", "time.ssrs.reports","ReportingServices.DataExtensions.Multitenancy","cloud.job.executor")

$region = "eu-west-1"
$awsAccessKey = get-content C:\temp\jobExecAwsAccessKey.txt -ErrorAction SilentlyContinue
$awsSecretKey = get-content C:\temp\jobExecAwsSecretKey.txt -ErrorAction SilentlyContinue
$deploymentBucketName = "intapp-time-dev-deployments"
$deploymentBucketRegion = "eu-west-1"
$stackName = "dev-eddy"
$keyName = "devops.dev@intapp.com"
$serviceRole = "aws-elasticbeanstalk-service-role"
$iamInstanceProfile = "aws-elasticbeanstalk-ec2-role"
$appInstanceType = "m5.large"
$ebMultiAZ = "False"
$awsAccount = "357128852511"
$cfnWaitTimeOut = 1800

$ebVpcStackName = "dev-eddy"               # Name of the VPC stack in which the EB stack is to go
$ebStackVariant = "dev-eddy"               # Name of the EB stack 
$ebPackagesToBundle = @("time.server", "time.server.plugins", "time.admin.tool", "time.capture.website", "time.api.service","cloud.job.executor")
$ebTimeServerSiteName = "timeserver.timedev.intapp.com"
$ebAdminToolAppName = "IntappTimeAdminTool"
$ebCaptureAppName = "Capture"
$ebCaptureApiAppName = "CaptureApi"
$ebAppPools = @("$ebTimeServerSiteName`_pool", "$ebAdminToolAppName`_pool", "$ebCaptureAppName`_pool", "$ebCaptureApiAppName`_pool")
$jobExecAwsAccessKey = get-content C:\temp\jobExecAwsAccessKey.txt -ErrorAction SilentlyContinue
$jobExecAwsSecretKey = get-content C:\temp\jobExecAwsSecretKey.txt -ErrorAction SilentlyContinue
$jobExecRegion = $region

$dataDbSuffix = "multitenant"
$dataDbInstanceType = "db.m4.large"
$dataRdsKmsKey = "arn:aws:kms:eu-west-1:357128852511:key/b4d2e1b0-fe5c-4ee8-8170-f2b9d10f2634"
$dataDbStorageCapacity = 200
$dataRdsInstanceMasterUsername = $($dataDbSuffix + "admin")
$dataRdsInstanceMasterPassword = "Password01"
$dataDbMultiAZ = "False"
$dataDBDeploymentPackageFolder = "C:\temp\convergenceDBPackages\timeDB" # Output folder where DB scripts will be unpacked to
$rdsDataStack = "https://s3.amazonaws.com/$deploymentBucketName/git/convergence-rds-timedata-template.yml"
$rdsDataStackName = "time-$stackName-rds-data-$dataDbSuffix"

$captureDbSuffix = "multitenantcapture"
$captureDbInstanceType = "db.m4.large"
$captureRdsKmsKey = "arn:aws:kms:eu-west-1:357128852511:key/b4d2e1b0-fe5c-4ee8-8170-f2b9d10f2634"
$captureDbStorageCapacity = 200
$captureRdsInstanceMasterUsername = $($captureDbSuffix + "admin")
$captureRdsInstanceMasterPassword = "Password01"
$captureDbMultiAZ = "False"
$captureDBDeploymentPackageFolder = "C:\temp\convergenceDBPackages\captureDB" # Output folder where DB scripts will be unpacked to
$rdsCaptureStack = "https://s3.amazonaws.com/$deploymentBucketName/git/convergence-rds-timecapture-template.yml"
$rdsCaptureStackName = "time-$stackName-rds-capture-$captureDbSuffix"

$vpcStack = "https://s3.amazonaws.com/$deploymentBucketName/git/convergence-vpc-template.yml"
$vpcStackName = "time-$stackName-vpc"
$ebStack = "https://s3.amazonaws.com/$deploymentBucketName/git/convergence-eb-template.yml"
$ebStackName = "time-$ebStackVariant-eb"

$ssrsAsgStack = "https://s3.amazonaws.com/$deploymentBucketName/git/convergence-ssrs-asg-template.yml"
$ssrsAsgStackName = "time-$stackName-ssrs-asg"
$ssrsMultiAZ = "False"
$ssrsInstanceType = "m5.large"
$ssrsBuildScriptName = "SSRS_cfn_init-time.ps1"
$ssrsRdlWarmupName = "warmup.rdl"
$ssrsScaleUpSchedule = "0 9 * * *"
$ssrsScaleDownSchedule = "0 10 * * *"

$ecStack = "https://s3.amazonaws.com/$deploymentBucketName/git/convergence-ec-template.yml"
$ecStackName = "time-$stackName-elasticache"
$ecMultiAZ = "False"
$ecInstanceType = "cache.t2.micro"
$ecCachePort = "6235"

$dynamoDbStack = "https://s3.amazonaws.com/$deploymentBucketName/git/convergence-je-dynamodb-template.yml"
$dynamoDbStackName = "time-$stackName-dynamodb"
$dynamoDbTableName = "time-$stackName-time-cronTable"

$sqsStack = "https://s3.amazonaws.com/$deploymentBucketName/git/convergence-je-sqs-template.yml"
$sqsStackName = "time-$stackName-sqs"
$sqsQueueName = "time-$stackName-jobExecutorQueue"

$route53Stack = "https://s3.amazonaws.com/$deploymentBucketName/git/convergence-route53-template.yml"

$s3ConnectionStringBucketName = "intapp-opentime-dev"

###################################################################################################################
#------------------------ Parameter Set Config ---------------------
###################################################################################################################

# TODO: Not currently used
$iisParameters = "
{
    `"httpErrorMode`" = `" -section:system.webServer/httpErrors /errorMode:'Custom'`"
}
"

$ebDeployParameters = "
{
    `"TimeServerSiteName`": `"$ebTimeServerSiteName`",
    `"AdminToolApplicationName`": `"$ebAdminToolAppName`",
    `"CaptureApplicationName`": `"$ebCaptureAppName`",
    `"CaptureApiApplicationName`": `"$ebCaptureApiAppName`",
    `"ApplicationsToDeploy`": `"$ebPackagesToBundle`",
    `"ApplicationPools`": `"$ebAppPools`",
    `"ConnStringBucketName`": `"$s3ConnectionStringBucketName`",
    `"JobExecAwsAccessKey`": `"$jobExecAwsAccessKey`",
    `"JobExecAwsSecretKey`": `"$jobExecAwsSecretKey`",
    `"DynamoDbTableName`": `"$dynamoDbTableName`",
    `"SqsQueueName`": `"$sqsQueueName`",
    `"JobExecRegion`": `"$jobExecRegion`"
}
"

###################################################################################################################
#------------------------ Tenant Details ---------------------
###################################################################################################################

$tenants = @(
    @{
        CompanyName = "snowlaw"
        TimeAppRdsInstance = "multitenant"
        CaptureAppRdsInstance = "multitenantcapture"
        SQLApplicationPassword = "SoundChoicesMakeIceCream1"
        SQLCapturePassword = "SoundChoicesMakeIceCream1"
        ConnectionStringBucket = $s3ConnectionStringBucketName
        Route53ZoneDomain = "timedev.intapp.com."
        EBTenantStackVariant = "dev-eddy"
    }
)
###################################################################################################################
#------------------------ RDS Restore Options ----------------------
###################################################################################################################
if (($deployDataRdsFromLatestSnapshot -eq 1) -and ($deployDataRds -eq 1)) {
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Restore from latest snapshot selected for time-$stackName-$dataDbSuffix" -ForegroundColor Green
    $dataDbSnapshotIdentifier = $(& "$templateBuildFolder\get-latestrdssnapshot.ps1" -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -stackName $stackName -dbSuffix $dataDbSuffix)
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Using $dataDbSnapshotIdentifier to restore: time-$stackName-$dataDbSuffix..." -ForegroundColor Green
} elseif ($deployDataRds -eq 1) {
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - No snapshot ID used for deployment of time-$stackName-$dataDbSuffix" -ForegroundColor Green
    $dataDbSnapshotIdentifier = ""
}
if (($deployCaptureRdsFromLatestSnapshot -eq 1) -and ($deployCaptureRds -eq 1)) {
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Restore from latest snapshot selected for time-$stackName-$captureDbSuffix" -ForegroundColor Green
    $captureDbSnapshotIdentifier = $(& "$templateBuildFolder\get-latestrdssnapshot.ps1" -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -stackName $stackName -dbSuffix $captureDbSuffix)
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Using $captureDbSnapshotIdentifier to restore: time-$stackName-$captureDbSuffix..." -ForegroundColor Green
} elseif ($deployCaptureRds -eq 1) {
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - No snapshot ID used for deployment of time-$stackName-$captureDbSuffix" -ForegroundColor Green
    $captureDbSnapshotIdentifier = ""
}

###################################################################################################################
#------------------------ Common Tags ----------------------
###################################################################################################################

$tagProduct = New-Object Amazon.CloudFormation.Model.Tag
$tagProduct.Key = "Product"
$tagProduct.Value = "time"

$tagProductComponentsVpc = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsVpc.Key = "ProductComponents"
$tagProductComponentsVpc.Value = "vpc"

$tagProductComponentsEc = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsEc.Key = "ProductComponents"
$tagProductComponentsEc.Value = "elastic cache"

$tagProductComponentsEb = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsEb.Key = "ProductComponents"
$tagProductComponentsEb.Value = "elastic beanstalk"

$tagProductComponentsRds = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsRds.Key = "ProductComponents"
$tagProductComponentsRds.Value = "rds"

$tagProductComponentsSsrs = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsSsrs.Key = "ProductComponents"
$tagProductComponentsSsrs.Value = "ssrs"

$tagProductComponentsDynamoDb = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsDynamoDb.Key = "ProductComponents"
$tagProductComponentsDynamoDb.Value = "dynamodb"

$tagProductComponentsRoute53 = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsRoute53.Key = "ProductComponents"
$tagProductComponentsRoute53.Value = "route53"

$tagProductComponentsSqs = New-Object Amazon.CloudFormation.Model.Tag
$tagProductComponentsSqs.Key = "ProductComponents"
$tagProductComponentsSqs.Value = "sqs"

$tagTeam = New-Object Amazon.CloudFormation.Model.Tag
$tagTeam.Key = "Team"
$tagTeam.Value = "Devops"

$tagEnvironment = New-Object Amazon.CloudFormation.Model.Tag
$tagEnvironment.Key = "Environment"
$tagEnvironment.Value = "dev"

$tagContact = New-Object Amazon.CloudFormation.Model.Tag
$tagContact.Key = "Contact"
$tagContact.Value = "eddy.snow@intapp.com"

###################################################################################################################
#----------------------- Cloudformation Parameters -----------------------
###################################################################################################################

$stackNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$stackNameParam.ParameterKey = "stackName"
$stackNameParam.ParameterValue = $stackName

$keyPairParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$keyPairParam.ParameterKey = "keyName"
$keyPairParam.ParameterValue = $keyName

$serviceRoleParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$serviceRoleParam.ParameterKey = "serviceRole"
$serviceRoleParam.ParameterValue = $serviceRole

$iamInstanceProfileParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$iamInstanceProfileParam.ParameterKey = "iamInstanceProfile"
$iamInstanceProfileParam.ParameterValue = $iamInstanceProfile

$packageArchiveKeyParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$packageArchiveKeyParam.ParameterKey = "packageArchiveKey"
$packageArchiveKeyParam.ParameterValue = "" # Populated during the package bundle stage

$packageBucketParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$packageBucketParam.ParameterKey = "packageBucket"
$packageBucketParam.ParameterValue = $($awsAccount + "-$region")

$timeApplicationVersionNumberParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$timeApplicationVersionNumberParam.ParameterKey = "timeApplicationVersionNumber"
$timeApplicationVersionNumberParam.ParameterValue = "" # Populated during the package bundle stage

$ebStackVariantParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ebStackVariantParam.ParameterKey = "ebStackVariant"
$ebStackVariantParam.ParameterValue = $ebStackVariant

$ebVpcStackNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ebVpcStackNameParam.ParameterKey = "ebVpcStackName"
$ebVpcStackNameParam.ParameterValue = $ebVpcStackName

$dataDbSuffixParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$dataDbSuffixParam.ParameterKey = "dataDbSuffix"
$dataDbSuffixParam.ParameterValue = $dataDbSuffix

$dataDbInstanceTypeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$dataDbInstanceTypeParam.ParameterKey = "dataRdsInstanceType"
$dataDbInstanceTypeParam.ParameterValue = $dataDbInstanceType

$dataRdsKmsKeyParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$dataRdsKmsKeyParam.ParameterKey = "dataRdsKmsKey"
$dataRdsKmsKeyParam.ParameterValue = $dataRdsKmsKey

$dataDbSnapshotIdentifierParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$dataDbSnapshotIdentifierParam.ParameterKey = "dataDbSnapshotIdentifier"
$dataDbSnapshotIdentifierParam.ParameterValue = $dataDbSnapshotIdentifier

$dataDbStorageCapacityParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$dataDbStorageCapacityParam.ParameterKey = "dataDbStorageCapacity"
$dataDbStorageCapacityParam.ParameterValue = $dataDbStorageCapacity

$dataRdsInstanceMasterUsernameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$dataRdsInstanceMasterUsernameParam.ParameterKey = "dataRdsInstanceMasterUsername"
$dataRdsInstanceMasterUsernameParam.ParameterValue = $dataRdsInstanceMasterUsername

$dataRdsInstanceMasterPasswordParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$dataRdsInstanceMasterPasswordParam.ParameterKey = "dataRdsInstanceMasterPassword"
$dataRdsInstanceMasterPasswordParam.ParameterValue = $dataRdsInstanceMasterPassword

$dataDbMultiAZParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$dataDbMultiAZParam.ParameterKey = "dataDbMultiAZ"
$dataDbMultiAZParam.ParameterValue = $dataDbMultiAZ

$captureDbSuffixParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$captureDbSuffixParam.ParameterKey = "captureDbSuffix"
$captureDbSuffixParam.ParameterValue = $captureDbSuffix

$captureDbInstanceTypeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$captureDbInstanceTypeParam.ParameterKey = "captureRdsInstanceType"
$captureDbInstanceTypeParam.ParameterValue = $captureDbInstanceType

$captureRdsKmsKeyParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$captureRdsKmsKeyParam.ParameterKey = "captureRdsKmsKey"
$captureRdsKmsKeyParam.ParameterValue = $captureRdsKmsKey

$captureDbSnapshotIdentifierParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$captureDbSnapshotIdentifierParam.ParameterKey = "captureDbSnapshotIdentifier"
$captureDbSnapshotIdentifierParam.ParameterValue = $captureDbSnapshotIdentifier

$captureDbStorageCapacityParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$captureDbStorageCapacityParam.ParameterKey = "captureDbStorageCapacity"
$captureDbStorageCapacityParam.ParameterValue = $captureDbStorageCapacity

$captureRdsInstanceMasterUsernameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$captureRdsInstanceMasterUsernameParam.ParameterKey = "captureRdsInstanceMasterUsername"
$captureRdsInstanceMasterUsernameParam.ParameterValue = $captureRdsInstanceMasterUsername

$captureRdsInstanceMasterPasswordParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$captureRdsInstanceMasterPasswordParam.ParameterKey = "captureRdsInstanceMasterPassword"
$captureRdsInstanceMasterPasswordParam.ParameterValue = $captureRdsInstanceMasterPassword

$captureDbMultiAZParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$captureDbMultiAZParam.ParameterKey = "captureDbMultiAZ"
$captureDbMultiAZParam.ParameterValue = $captureDbMultiAZ

$appInstanceTypeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$appInstanceTypeParam.ParameterKey = "appInstanceType"
$appInstanceTypeParam.ParameterValue = $appInstanceType

$appMultiAZParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$appMultiAZParam.ParameterKey = "appMultiAZ"
$appMultiAZParam.ParameterValue = $ebMultiAZ

$ssrsMultiAZParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ssrsMultiAZParam.ParameterKey = "ssrsMultiAZ"
$ssrsMultiAZParam.ParameterValue = $ssrsMultiAZ

$ssrsInstanceTypeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ssrsInstanceTypeParam.ParameterKey = "ssrsInstanceType"
$ssrsInstanceTypeParam.ParameterValue = $ssrsInstanceType

$ssrsConfigureScriptParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ssrsConfigureScriptParam.ParameterKey = "ssrsConfigureScript"
$ssrsConfigureScriptParam.ParameterValue = "" # populated during the SSRS file process stage

$ssrsWarmupRdlNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ssrsWarmupRdlNameParam.ParameterKey = "ssrsWarmupName"
$ssrsWarmupRdlNameParam.ParameterValue = "" # populated during the SSRS file process stage

$ssrsReportFilesNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ssrsReportFilesNameParam.ParameterKey = "ssrsReportFilesName"
$ssrsReportFilesNameParam.ParameterValue = "" # populated during the SSRS file process stage

$ssrsMultiTenantExtensionParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ssrsMultiTenantExtensionParam.ParameterKey = "ssrsMultiTenantExtension"
$ssrsMultiTenantExtensionParam.ParameterValue = "" # populated during the SSRS file process stage

$ssrsScaleUpScheduleParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ssrsScaleUpScheduleParam.ParameterKey = "scaleUpSchedule"
$ssrsScaleUpScheduleParam.ParameterValue = $ssrsScaleUpSchedule

$ssrsScaleDownScheduleParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ssrsScaleDownScheduleParam.ParameterKey = "scaleDownSchedule"
$ssrsScaleDownScheduleParam.ParameterValue = $ssrsScaleDownSchedule

$ecMultiAZParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ecMultiAZParam.ParameterKey = "ecMultiAZ"
$ecMultiAZParam.ParameterValue = $ecMultiAZ

$ecInstanceTypeParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ecInstanceTypeParam.ParameterKey = "ecInstanceType"
$ecInstanceTypeParam.ParameterValue = $ecInstanceType

$ecCachePortParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$ecCachePortParam.ParameterKey = "ecCachePort"
$ecCachePortParam.ParameterValue = $ecCachePort

$s3BuildBucketParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$s3BuildBucketParam.ParameterKey = "s3BuildBucket"
$s3BuildBucketParam.ParameterValue = $deploymentBucketName

$route53elbCnameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$route53elbCnameParam.ParameterKey = "elbCname"
$route53elbCnameParam.ParameterValue = $deploymentBucketName

$route53tenantNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$route53tenantNameParam.ParameterKey = "tenantName"
$route53tenantNameParam.ParameterValue = "" # populated during the Route53 process stage

$route53domainNameParam = New-Object -Type Amazon.CloudFormation.Model.Parameter
$route53domainNameParam.ParameterKey = "domainName"
$route53domainNameParam.ParameterValue = "" # populated during the Route53 process stage

###################################################################################################################
#------------------ Environment Settings ----------------------------
###################################################################################################################

Set-DefaultAWSRegion -Region $region

###################################################################################################################
#----------------- Upload Deploy Scripts to S3 to simulate Jenkins build doing the same --------------
###################################################################################################################

# TODO: This may not be required anymore due to Jenkins uploading to artifactory instead of S3.

if ($simulateJenkinsUploadToS3 -eq 1) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Simulating Jenkins upload to S3..." -ForegroundColor Green
    Get-S3Object -BucketName $deploymentBucketName -KeyPrefix git -AccessKey $awsAccessKey -SecretKey $awsSecretKey | foreach {Remove-S3Object -BucketName $deploymentBucketName -Key $_.key -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Confirm:$false | Out-Null}
    Write-S3Object -BucketName $deploymentBucketName -KeyPrefix git -Recurse -Folder $deploymentScriptsPath -AccessKey $awsAccessKey -SecretKey $awsSecretKey

}

###################################################################################################################
#------------------ Download Deployment Files from S3 ----------------------------
###################################################################################################################

# Create Temp folder to hold packages
if (!(Test-Path $templatePath)) {mkdir $templatePath | out-null}

# Download deployment scripts from S3
Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Downloading deployment files from S3..." -ForegroundColor Green
Get-S3Object -BucketName $deploymentBucketName -KeyPrefix git -AccessKey $awsAccessKey -SecretKey $awsSecretKey | foreach {Copy-S3Object -BucketName $deploymentBucketName -Key $_.key -LocalFile $($templatePath + $_.key) -AccessKey $awsAccessKey -SecretKey $awsSecretKey} | Out-Null

###################################################################################################################
#------------------ Download Packages from Artifactory ----------------------------
###################################################################################################################

# TODO: Download packages from Artifactory 
# TODO: Merge deployment scripts with package from Artifactory || package up || upload to S3

if ($downloadPackagesFromArtifactory -eq 1) {

    & "$templateBuildFolder\download-artifact.ps1" -apiKey $artifactoryApiKey -outFolder $deploymentPackageRoot -branch $branch -url $artifactoryRootUrl -applications $packagesToDownload

}

###################################################################################################################
#--------------------- SSRS File Process -------------------------
###################################################################################################################

if ($processSsrsFiles -eq 1) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Packaging SSRS report files..." -ForegroundColor Green
    $ssrsReportFilesPackage = & "$templateBuildFolder\get-packagezip.ps1" -packagePath $deploymentPackageRoot -packageName time.ssrs.reports
    copy-item $ssrsReportFilesPackage $($templatePath + "ssrsReports.zip")
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Uploading $($templatePath + "ssrsReports.zip") to S3..." -ForegroundColor Green
    Write-S3Object -BucketName $deploymentBucketName -key "git/ssrsReports.zip" -File $($templatePath + "ssrsReports.zip") -Region $deploymentBucketRegion -AccessKey $awsAccessKey -SecretKey $awsSecretKey
    remove-item $($templatePath + "ssrsReports.zip") -Force -Confirm:$false

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Packaging SSRS multitentant extension..." -ForegroundColor Green
    $ssrsMultiTenancyExtensionPackage = & "$templateBuildFolder\get-packagezip.ps1" -packagePath $deploymentPackageRoot -packageName ReportingServices.DataExtensions.Multitenancy
    copy-item $ssrsMultiTenancyExtensionPackage $($templatePath + "ssrsMultiTenantExtension.zip")
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Uploading $($templatePath + "ssrsMultiTenantExtension.zip") to S3..." -ForegroundColor Green
    Write-S3Object -BucketName $deploymentBucketName -key "git/ssrsMultiTenantExtension.zip" -File $($templatePath + "ssrsMultiTenantExtension.zip") -Region $deploymentBucketRegion -AccessKey $awsAccessKey -SecretKey $awsSecretKey
    remove-item $($templatePath + "ssrsMultiTenantExtension.zip") -Force -Confirm:$false

    $ssrsBuildScriptURL = & "$templateBuildFolder\change-s3filenamehash.ps1" -s3FileKey $("git/$ssrsBuildScriptName") -tempPath $("$templatePath`git\") -bucketName $deploymentBucketName -bucketRegion $deploymentBucketRegion -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
    $ssrsRdlWarmupURL = & "$templateBuildFolder\change-s3filenamehash.ps1" -s3FileKey $("git/$ssrsRdlWarmupName") -tempPath $("$templatePath`git\") -bucketName $deploymentBucketName -bucketRegion $deploymentBucketRegion -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
    $ssrsReportFilesURL = & "$templateBuildFolder\change-s3filenamehash.ps1" -s3FileKey "git/ssrsReports.zip" -tempPath $($templatePath + "ssrsReports.zip") -bucketName $deploymentBucketName -bucketRegion $deploymentBucketRegion -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
    $ssrsMultiTenantExtensionURL = & "$templateBuildFolder\change-s3filenamehash.ps1" -s3FileKey "git/ssrsMultiTenantExtension.zip" -tempPath $($templatePath + "ssrsMultiTenantExtension.zip") -bucketName $deploymentBucketName -bucketRegion $deploymentBucketRegion -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

    $ssrsConfigureScriptParam.ParameterValue = $ssrsBuildScriptURL
    $ssrsWarmupRdlNameParam.ParameterValue = $ssrsRdlWarmupURL
    $ssrsReportFilesNameParam.ParameterValue = $ssrsReportFilesURL
    $ssrsMultiTenantExtensionParam.ParameterValue = $ssrsMultiTenantExtensionURL

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping SSRS File processing steps..." -ForegroundColor DarkYellow

}

###################################################################################################################
#--------------------- Application Package -------------------------
###################################################################################################################

if ($deployEB -eq 1) {

    # Add eb config template
    $ebDeployParameters | out-file $($templatePath + "git\deploy\parameters.config")

    # Package deployment files together
    $archivedTimeApplicationFolderPath = & "$templateBuildFolder\package-fullapplicationbundle.ps1" -functionPath $($templatePath + "git\build") -packagesToBundle $ebPackagesToBundle -bundleDestinationPath $($templatePath + "timeserver") -ebDeployPath $($templatePath + "git\deploy") -deploymentPackageRoot $deploymentPackageRoot
    $archivedTimeApplicationName = $archivedTimeApplicationFolderPath.split("\")[-1]
    $builtPackageKey = "dev/" + "time-" + $stackName + "/$archivedTimeApplicationName"

    # Update EB CFN Stack Parameters with bundled package details
    $packageArchiveKeyParam.ParameterValue = $builtPackageKey
    $timeApplicationVersionNumberParam.ParameterValue = $(($archivedTimeApplicationName).split("_")[-1].replace(".zip",""))

    # Copy deployment package to S3 bucket
    if ($uploadPackage -eq 1) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Uploading deployment package bundle for eb stack to S3 bucket: $($awsAccount + "-$region")..." -ForegroundColor Green
        Write-S3Object -BucketName $($awsAccount + "-$region") -Key $builtPackageKey -File $archivedTimeApplicationFolderPath -AccessKey $awsAccessKey -SecretKey $awsSecretKey

    } else {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping package upload to S3..." -ForegroundColor DarkYellow

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping EB Package processing steps..." -ForegroundColor DarkYellow

}

###################################################################################################################
#---------------------- Deploy VPC Template ------------------------
###################################################################################################################

if ($deployVPC -eq 1) {

    & "$templateBuildFolder\deploy-cfnstack.ps1" -stackName $vpcStackName -stackUrl $vpcStack -parameters $stackNameParam -tags $tagProduct, $tagProductComponentsVpc, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping VPC Stack deployment..." -ForegroundColor darkyellow

}

###################################################################################################################
#---------------------- Deploy Elasti Cache Template ------------------------
###################################################################################################################

if ($deployEC -eq 1) {

    & "$templateBuildFolder\deploy-cfnstack.ps1" -stackName $ecStackName -stackUrl $ecStack -parameters $stackNameParam, $ecMultiAZParam, $ecInstanceTypeParam, $ecCachePortParam -tags $tagProduct, $tagProductComponentsEc, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping Elasti Cache Stack deployment..." -ForegroundColor darkyellow

}

###################################################################################################################
#----------------------- Deploy Time SSRS ASG Template -----------------------
###################################################################################################################

if ($deploySsrsAsg -eq 1) {

    & "$templateBuildFolder\deploy-cfnstack.ps1" -waitForStackName $vpcStackName -stackName $ssrsAsgStackName -stackUrl $ssrsAsgStack -parameters $stackNameParam, $keyPairParam, $ssrsMultiAZParam, $ssrsInstanceTypeParam, $ssrsConfigureScriptParam, $s3BuildBucketParam, $ssrsWarmupRdlNameParam, $ssrsReportFilesNameParam, $ssrsScaleUpScheduleParam, $ssrsScaleDownScheduleParam, $ssrsMultiTenantExtensionParam -tags $tagProduct, $tagProductComponentsSsrs, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping SSRS ASG CFN deployment..." -ForegroundColor darkyellow

}

###################################################################################################################
#----------------------- Deploy Time RDS Template -----------------------
###################################################################################################################

if ($deployDataRds -eq 1) {

    & "$templateBuildFolder\deploy-cfnstack.ps1" -waitForStackName $vpcStackName -stackName $rdsDataStackName -stackUrl $rdsDataStack -parameters $stackNameParam, $keyPairParam, $dataDbSuffixParam, $dataDbInstanceTypeParam, $dataRdsKmsKeyParam, $dataDbSnapshotIdentifierParam, $dataDbStorageCapacityParam, $dataRdsInstanceMasterUsernameParam, $dataRdsInstanceMasterPasswordParam, $dataDbMultiAZParam -tags $tagProduct, $tagProductComponentsRds, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping Data RDS CFN deployment..." -ForegroundColor darkyellow

}

###################################################################################################################
#----------------------- Deploy Capture RDS Template -----------------------
###################################################################################################################

if ($deployCaptureRds -eq 1) {

    & "$templateBuildFolder\deploy-cfnstack.ps1" -waitForStackName $vpcStackName -stackName $rdsCaptureStackName -stackUrl $rdsCaptureStack -parameters $stackNameParam, $keyPairParam, $captureDbSuffixParam, $captureDbInstanceTypeParam, $captureRdsKmsKeyParam, $captureDbSnapshotIdentifierParam, $captureDbStorageCapacityParam, $captureRdsInstanceMasterUsernameParam, $captureRdsInstanceMasterPasswordParam, $captureDbMultiAZParam -tags $tagProduct, $tagProductComponentsRds, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping Capture RDS CFN deployment..." -ForegroundColor darkyellow

}

###################################################################################################################
#------------------- Deploy Elastic Beanstalk Template ---------------------------
###################################################################################################################

if ($deployEB -eq 1) {

    & "$templateBuildFolder\deploy-cfnstack.ps1" -waitForStackName $vpcStackName -stackName $ebStackName -stackUrl $ebStack -parameters $keyPairParam, $ebVpcStackNameParam, $ebStackVariantParam, $serviceRoleParam, $iamInstanceProfileParam, $packageArchiveKeyParam, $packageBucketParam, $timeApplicationVersionNumberParam, $appMultiAZParam, $appInstanceTypeParam -tags $tagProduct, $tagProductComponentsEb, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping EB CFN deployment..." -ForegroundColor darkyellow     

}

###################################################################################################################
#------------------- Deploy DynamoDb Template ---------------------------
###################################################################################################################

if ($deployDynamoDb -eq 1) {

    & "$templateBuildFolder\deploy-cfnstack.ps1" -stackName $dynamoDbStackName -stackUrl $dynamoDbStack -parameters $stackNameParam -tags $tagProduct, $tagProductComponentsDynamoDb, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping DynamoDB CFN deployment..." -ForegroundColor darkyellow     

}

###################################################################################################################
#------------------- Deploy SQS Template ---------------------------
###################################################################################################################

if ($deploySqs -eq 1) {

    & "$templateBuildFolder\deploy-cfnstack.ps1" -stackName $sqsStackName -stackUrl $sqsStack -parameters $stackNameParam -tags $tagProduct, $tagProductComponentsSqs, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping SQS CFN deployment..." -ForegroundColor darkyellow     

}

################################################################################################################### 
#------------------- Run Data SQL Scripts ---------------------------
###################################################################################################################

if ($deployDataDatabase -eq 1) {

    foreach ($tenant in $tenants) {

        $companyName = $tenant.CompanyName
        $timeDatabaseName = "$companyName`_time_data"
        $connectionStringBucket = $tenant.ConnectionStringBucket
        $sqlApplicationUsername = "$timeDatabaseName`_db_user"
        $sqlApplicationPassword = $tenant.SQLApplicationPassword
        $sqlTimeAppRdsInstance = $tenant.TimeAppRdsInstance
        
        # Extract TimeDB Package

        & "$templateBuildFolder\expand-this.ps1" -path $(& "$templateBuildFolder\get-packagezip.ps1" -packagePath $deploymentPackageRoot -packageName time.database) -destinationPath $dataDBDeploymentPackageFolder
    
        # Gather components for SQL command

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack: $rdsDataStackName to be complete before running DB scripts..." -ForegroundColor Green
        Wait-CFNStack -StackName $rdsDataStackName -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout $cfnWaitTimeOut -ErrorAction SilentlyContinue | Out-Null

        $dataSqlInstallFiles = (get-childitem $dataDBDeploymentPackageFolder | Sort-Object fullname).FullName
        $rdsDataEndpoint = & "$templateBuildFolder\get-rdsendpoint.ps1" -rdsStackName $rdsDataStackName -dbType data -dbSuffix $sqlTimeAppRdsInstance -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
        $sqlInstallDataDbFileVersion = ""

        & "$templateBuildFolder\create-emptydatabase.ps1" -rdsEndpoint $rdsDataEndpoint -databaseName $timeDatabaseName -dbUsername $dataRdsInstanceMasterUsername -dbPassword $dataRdsInstanceMasterPassword -sqlApplicationUsername $sqlApplicationUsername -sqlApplicationPassword $sqlApplicationPassword -functionPath $($templatePath + "git\build")
        & "$templateBuildFolder\create-tenantdatabase.ps1" -rdsEndpoint $rdsDataEndpoint -databaseName $timeDatabaseName -dbUsername $dataRdsInstanceMasterUsername -dbPassword $dataRdsInstanceMasterPassword -inputFiles $dataSqlInstallFiles -functionPath $($templatePath + "git\build")
        & "$templateBuildFolder\create-dbconnectionstring.ps1" -rdsEndpoint $rdsDataEndpoint -databaseName $timeDatabaseName  -sqlApplicationUsername $sqlApplicationUsername -sqlApplicationPassword $sqlApplicationPassword -uploadToS3 -bucketName $connectionStringBucket -s3Key $("time/$companyName") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping time database/tenant deployment..." -ForegroundColor darkyellow

}

###################################################################################################################
#------------------- Run Capture SQL Scripts ---------------------------
###################################################################################################################

if ($deployCaptureDatabase -eq 1) {

    foreach ($tenant in $tenants) {

        $companyName = $tenant.CompanyName
        $captureDatabaseName = "$companyName`_time_capture"
        $connectionStringBucket = $tenant.ConnectionStringBucket
        $sqlCaptureUsername = "$captureDatabaseName`_db_user"
        $sqlCapturePassword = $tenant.SQLCapturePassword
        $sqlCaptureAppRdsInstance = $tenant.CaptureAppRdsInstance

        # Extract CaptureDB Package

        & "$templateBuildFolder\expand-this.ps1" -path $(& "$templateBuildFolder\get-packagezip.ps1" -packagePath $deploymentPackageRoot -packageName time.capture.database) -destinationPath $captureDBDeploymentPackageFolder   
        $captureSqlInstallFiles = (get-childitem $captureDBDeploymentPackageFolder | Sort-Object fullname).FullName

        if ($tenant.TimeAppRdsInstance -eq $tenant.CaptureAppRdsInstance) {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack: $rdsDataStackName to be complete before running DB scripts..." -ForegroundColor Green
            Wait-CFNStack -StackName $rdsDataStackName -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout $cfnWaitTimeOut -ErrorAction SilentlyContinue | Out-Null
            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Deploying Capture DB for $companyName onto the Time (Data) DB RDS Instance..." -ForegroundColor Green
            $rdsCaptureEndpoint = & "$templateBuildFolder\get-rdsendpoint.ps1" -rdsStackName $rdsDataStackName -dbType data -dbSuffix $sqlTimeAppRdsInstance -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
            $sqlInstallCaptureDbFileVersion = ""

            & "$templateBuildFolder\create-emptydatabase.ps1" -rdsEndpoint $rdsCaptureEndpoint -databaseName $captureDatabaseName -dbUsername $dataRdsInstanceMasterUsername -dbPassword $dataRdsInstanceMasterPassword -sqlApplicationUsername $sqlCaptureUsername -sqlApplicationPassword $sqlCapturePassword -functionPath $($templatePath + "git\build")
            & "$templateBuildFolder\create-tenantdatabase.ps1" -rdsEndpoint $rdsCaptureEndpoint -databaseName $captureDatabaseName -dbUsername $dataRdsInstanceMasterUsername -dbPassword $dataRdsInstanceMasterPassword -inputFiles $captureSqlInstallFiles -functionPath $($templatePath + "git\build")
        
        } else {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Waiting for stack: $rdsCaptureStackName to be complete before running DB scripts..." -ForegroundColor Green
            Wait-CFNStack -StackName $rdsCaptureStackName -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout $cfnWaitTimeOut -ErrorAction SilentlyContinue | Out-Null
            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Deploying Capture DBs for $companyName onto the Capture RDS instance..." -ForegroundColor Green
            $rdsCaptureEndpoint = & "$templateBuildFolder\get-rdsendpoint.ps1" -rdsStackName $rdsCaptureStackName -dbType capture -dbSuffix $sqlCaptureAppRdsInstance -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region
            $sqlInstallCaptureDbFileVersion = ""

            & "$templateBuildFolder\create-emptydatabase.ps1" -rdsEndpoint $rdsCaptureEndpoint -databaseName $captureDatabaseName -dbUsername $captureRdsInstanceMasterUsername -dbPassword $captureRdsInstanceMasterPassword -sqlApplicationUsername $sqlCaptureUsername -sqlApplicationPassword $sqlCapturePassword -functionPath $($templatePath + "git\build")
            & "$templateBuildFolder\create-tenantdatabase.ps1" -rdsEndpoint $rdsCaptureEndpoint -databaseName $captureDatabaseName -dbUsername $captureRdsInstanceMasterUsername -dbPassword $captureRdsInstanceMasterPassword -inputFiles $captureSqlInstallFiles -functionPath $($templatePath + "git\build")

        }

        # Need to add into an if block (if tenant upgrade or if tenant creation). This will need to be decoupled from this deployment script

        # New function: Configure-TenantDatabase: https://www.intapp.com/wiki/display/TBKB/Cloud+Deployment+Configuration
        # Need to configure anything with "DevOps Determined"
        

        & "$templateBuildFolder\create-dbconnectionstring.ps1" -rdsEndpoint $rdsCaptureEndpoint -databaseName $captureDatabaseName  -sqlApplicationUsername $sqlCaptureUsername -sqlApplicationPassword $sqlCapturePassword -uploadToS3 -bucketName $connectionStringBucket -s3Key $("capture/$companyName") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping capture database/tenant deployment..." -ForegroundColor darkyellow

}

###################################################################################################################
#------------------- Add Initial CloudSyncJob ---------------------------
###################################################################################################################

if (($deployCaptureDatabase -eq 1) -and ($deployDynamoDb -eq 1)) {

    foreach ($tenant in $tenants) {

        $companyName = $tenant.CompanyName
        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Adding initial schedule table for $companyName..." -ForegroundColor Green
        & "$templateBuildFolder\add-cloudsyncjob.ps1" -dynamoDbTableName $dynamoDbTableName -companyName $companyName -addDbTableScriptPath $($templatePath + "git\add-db-table.py") -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping adding initial cloud sync job to dynamoDb table..." -ForegroundColor darkyellow

}

###################################################################################################################
#------------------- Change Route53 Records ---------------------------
###################################################################################################################

if ($updateDnsRecords -eq 1) {

    foreach ($tenant in $tenants) {

        $companyName = $tenant.CompanyName 
        $route53ZoneDomain = $tenant.Route53ZoneDomain
        $ebTenantStackVariant = $tenant.EBTenantStackVariant
        
        $route53elbCnameParam.Value = $(& "$templateBuildFolder\get-stackoutputvalue.ps1" -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -stackName $("time-" + $ebTenantStackVariant + "-eb") -exportName $("time-" + $ebTenantStackVariant + "-elbCname"))
        $route53tenantNameParam.Value = $companyName
        $route53domainNameParam.Value = $route53ZoneDomain
                                   
        & "$templateBuildFolder\deploy-cfnstack.ps1" -waitForStackName $("time-" + $ebTenantStackVariant + "-eb") -stackName $("time-" + "$ebTenantStackVariant-$companyName" + "-route53") -stackUrl $route53Stack -parameters $route53elbCnameParam, $route53tenantNameParam, $route53domainNameParam -tags $tagProduct, $tagProductComponentsRoute53, $tagTeam, $tagEnvironment, $tagContact -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region

    }

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Skipping DNS record update..." -ForegroundColor darkyellow

}
