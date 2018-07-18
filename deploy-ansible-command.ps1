& "$env:userprofile\git\labs\deploy-infra.ps1" `
    -gitPath "$env:userprofile\git\labs" `
    -tagValueProduct "lab" `
    -tagValueContact "eddysnow@googlemail.com" `
    -awsAccessKey $(get-content C:\temp\snowcoAccessKey.txt -ErrorAction SilentlyContinue) `
    -awsSecretKey $(get-content C:\temp\snowcoSecretKey.txt -ErrorAction SilentlyContinue) `
    -region "eu-west-1" `
    -components vpc `
    -stackStemName "ansible" `
    -deploymentBucket "722777194664-eddy-scratch" `
    -keyName eddy-lab@gmail.com `
    -confirmWhenStackComplete

