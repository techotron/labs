﻿$awsAccount = "asds"

if ($awsAccount -eq "personal") {

    $awsAccessKey = $(get-content C:\temp\snowcoAccessKey.txt -ErrorAction SilentlyContinue)
    $awsSecretKey = $(get-content C:\temp\snowcoSecretKey.txt -ErrorAction SilentlyContinue)
    $deploymentBucket = "722777194664-eddy-scratch"
    $tagValueContact = "eddysnow@googlemail.com"
    $keyName = "eddy-lab@gmail.com"

} else {

    $awsAccessKey = $(get-content C:\temp\awsAccessKey.txt -ErrorAction SilentlyContinue)
    $awsSecretKey = $(get-content C:\temp\awsSecretKey.txt -ErrorAction SilentlyContinue)
    $deploymentBucket = "357128852511-eddy-scratch"
    $tagValueContact = "eddy.snow@intapp.com"
    $keyName = "eddy-scratch@intapp.com"

}
    
& "$env:userprofile\git\labs\deploy-infra.ps1" `
    -gitPath "$env:userprofile\git\labs" `
    -tagValueProduct "lab" `
    -tagValueContact $tagValueContact `
    -awsAccessKey $awsAccessKey `
    -awsSecretKey $awsSecretKey `
    -region "eu-west-1" `
    -components vpc `
    -stackStemName "k8s" `
    -deploymentBucket $deploymentBucket `
    -keyName $keyName `
    -confirmWhenStackComplete

& "$env:userprofile\git\labs\deploy-infra.ps1" `
    -gitPath "$env:userprofile\git\labs" `
    -tagValueProduct "lab" `
    -tagValueContact $tagValueContact `
    -awsAccessKey $awsAccessKey `
    -awsSecretKey $awsSecretKey `
    -region "eu-west-1" `
    -components k8sEc2Asg `
    -stackStemName "k8s" `
    -deploymentBucket $deploymentBucket `
    -keyName $keyName `
    -ec2AsgInstanceType t2.medium `
    -ec2AsgMultiAz False 

  