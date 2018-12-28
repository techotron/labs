





Get-S3Object -BucketName $deploymentBucket -KeyPrefix git/$stackStemName -AccessKey $awsAccessKey -SecretKey $awsSecretKey | foreach {Remove-S3Object -BucketName $deploymentBucket -Key $_.key -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Confirm:$false | Out-Null}
Write-S3Object -BucketName $deploymentBucket -KeyPrefix git/$stackStemName -Recurse -Folder $deploymentScriptsPath -AccessKey $awsAccessKey -SecretKey $awsSecretKey