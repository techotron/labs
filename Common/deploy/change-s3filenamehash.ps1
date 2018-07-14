param(
    [string] $tempPath,
    [string] $s3FileKey,
    [string] $bucketName,
    [string] $bucketRegion,
    [string] $awsAccessKey,
    [string] $awsSecretKey,
    [string] $region
)

try {
        
    Copy-S3Object -BucketName $bucketName -Key $s3FileKey -LocalFile $($tempPath + "tempHash") -Region $bucketRegion -AccessKey $awsAccessKey -SecretKey $awsSecretKey -ErrorAction stop | Out-Null

} catch {

    if ($($Error[0]) -like "*The specified key does not exist*") {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - $s3FileKey not found. Nothing to do." -ForegroundColor darkyellow
        break

    } else {

        throw "Failed to copy $s3FileKey!"

    }

}

$localScriptHash = (Get-FileHash -Path $($tempPath + "tempHash") -Algorithm SHA256).hash
    
try {
    
    Write-S3Object -BucketName $bucketName -key $($s3FileKey + "_SHA256_$localScriptHash") -File $($tempPath + "tempHash") -Region $bucketRegion -AccessKey $awsAccessKey -SecretKey $awsSecretKey -ErrorAction stop

} catch {

    throw "Failed to write $($tempPath + "tempHash") to $($s3FileKey + "_SHA256_$localScriptHash")!"

}

$s3FileCheck = (Get-S3Object -BucketName $bucketName -Key $($s3FileKey + "_SHA256_$localScriptHash") -AccessKey $awsAccessKey -SecretKey $awsSecretKey -ErrorAction SilentlyContinue).count

if ($s3FileCheck -le 0) {

    throw "Failed to find $($s3FileKey + "_SHA256_$localScriptHash") in bucket: $bucketName"

} elseif ($s3FileCheck -eq 1) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - $($s3FileKey + "_SHA256_$localScriptHash") uploaded to S3 to bucket: $bucketName successfully" -ForegroundColor Green
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Removing old file: $s3FileKey..." -ForegroundColor Green
    $s3FileObject = Get-S3Object -BucketName $bucketName -Key $($s3FileKey + "_SHA256_$localScriptHash") -AccessKey $awsAccessKey -SecretKey $awsSecretKey
    Write-Output "https://s3-$bucketRegion.amazonaws.com/$bucketName/$($s3FileObject.key)"
        
    try {
        
        Remove-S3Object -BucketName $bucketName -Key $s3FileKey -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Confirm:$false -ErrorAction stop | Out-Null

    } catch {

        throw "Failed to remove $s3FileKey!"

    }

}