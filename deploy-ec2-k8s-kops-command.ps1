$awsAccount = "asds"
$region = "eu-west-1"

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
    -region $region `
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
    -region $region `
    -components k8s-kops `
    -stackStemName "k8s" `
    -deploymentBucket $deploymentBucket `
    -keyName $keyName `
    -confirmWhenStackComplete `
    -ec2InstanceType t2.micro

sleep -Seconds 5
& "$env:userprofile\git\labs\Scripts\Common\tools\quick-putty-logon.ps1" -stackName k8s-kops-k8s-installer -LogicalResourceId kopsInstaller -awsAccessKey $awsAccessKey -awsSecretKey $awsSecretKey -region $region -resourceType singleEc2Instance
