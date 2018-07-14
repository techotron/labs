& "$env:userprofile\git\labs\deploy-infra.ps1" `
    -gitPath "$env:userprofile\git\labs" `
    -tagValueProduct "lab" `
    -tagValueContact "eddysnow@googlemail.com" `
    -awsAccessKey $(get-content C:\temp\snowcoAccessKey.txt -ErrorAction SilentlyContinue) `
    -awsSecretKey $(get-content C:\temp\snowcoSecretKey.txt -ErrorAction SilentlyContinue) `
    -region "eu-west-1" `
    -components vpc `
    -stackStemName "gitlab" `
    -deploymentBucket "722777194664-eddy-scratch" `
    -keyName eddy-lab@gmail.com `
    -confirmWhenStackComplete

& "$env:userprofile\git\labs\deploy-infra.ps1" `
	-gitPath "$env:userprofile\git\labs" `
	-tagValueProduct "lab" `
	-tagValueContact "eddysnow@googlemail.com" `
	-awsAccessKey $(get-content C:\temp\snowcoAccessKey.txt -ErrorAction SilentlyContinue) `
	-awsSecretKey $(get-content C:\temp\snowcoSecretKey.txt -ErrorAction SilentlyContinue) `
	-region "eu-west-1" `
	-components postgresrds `
	-stackStemName "gitlab" `
	-deploymentBucket "722777194664-eddy-scratch" `
	-keyName eddy-lab@gmail.com `
    -confirmWhenStackComplete `
    -dbSuffix gitlabDb `
    -dbInstanceClass db.t2.small `
    -rdsRootPass Password01 `
    -rdsMultiAz False

& "$env:userprofile\git\labs\deploy-infra.ps1" `
	-gitPath "$env:userprofile\git\labs" `
	-tagValueProduct "lab" `
	-tagValueContact "eddysnow@googlemail.com" `
	-awsAccessKey $(get-content C:\temp\snowcoAccessKey.txt -ErrorAction SilentlyContinue) `
	-awsSecretKey $(get-content C:\temp\snowcoSecretKey.txt -ErrorAction SilentlyContinue) `
	-region "eu-west-1" `
	-components gitlablinuxEc2Asg `
	-stackStemName "gitlab" `
	-deploymentBucket "722777194664-eddy-scratch" `
	-keyName eddy-lab@gmail.com `
    -ec2AsgInstanceType t2.small `
    -ec2AsgMultiAz False `
    -ec2AsgImage amzn-ami-hvm-*-x86_64-gp2* `
    -confirmWhenStackComplete 