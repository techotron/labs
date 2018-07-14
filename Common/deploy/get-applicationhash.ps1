param(
    [string] $bucketName,
    [string] $s3Key,
    [string] $localArchivePath,
    [string] $awsAccessKey,
    [string] $awsSecretKey
)

Remove-Variable appHashCheck -Force -ErrorAction SilentlyContinue 

if (Test-Path $localArchivePath) {

    $localAppVersionHash = (Get-FileHash -Path $localArchivePath -Algorithm SHA256).hash

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host "" -foregroundcolor gray -nonewline; write-host " - local application not found - downloading latest version from s3" -ForegroundColor darkyellow
    $latestAppKey = (Get-S3Object -BucketName $bucketName -key $s3Key -AccessKey $awsAccessKey -SecretKey $awsSecretKey | where {$_.key -like "*.zip"}).key
    copy-s3object -bucketname $bucketName -key $latestAppKey -localFile $localArchivePath -AccessKey $awsAccessKey -SecretKey $awsSecretKey
    $Global:appHashCheck = "false"
    break

}

if (Get-S3Object -BucketName $bucketName -key $($s3Key + "\" + $localAppVersionHash + ".zip") -AccessKey $awsAccessKey -SecretKey $awsSecretKey) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - no changes to application version" -ForegroundColor darkyellow
    $Global:appHashCheck = "true"

} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - application has changed - downloading new archive" -ForegroundColor darkyellow
    $latestAppKey = (Get-S3Object -BucketName $bucketName -key $s3Key -AccessKey $awsAccessKey -SecretKey $awsSecretKey | where {$_.key -like "*.zip"}).key
    copy-s3object -bucketname $bucketName -key $latestAppKey -localFile $localArchivePath -AccessKey $awsAccessKey -SecretKey $awsSecretKey
    $Global:appHashCheck = "false"

}