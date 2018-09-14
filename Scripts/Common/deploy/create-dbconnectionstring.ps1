param(
    [string] $rdsEndpoint,
    [string] $databaseName,
    [string] $sqlApplicationUsername,
    [string] $sqlApplicationPassword,
    [switch] $writeOutput,
    [switch] $uploadToS3,
    [string] $bucketName,
    [string] $s3Key,
    [string] $awsAccessKey,
    [string] $awsSecretKey
)

$connectionString = "Data Source=$rdsEndpoint;Initial Catalog=$databaseName;User Id=$sqlApplicationUsername;Password=$sqlApplicationPassword;Persist Security Info=True"

if ($uploadToS3) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Uploading connection string to s3..." -ForegroundColor Green
    Write-S3Object -BucketName $bucketName -content $connectionString -key $($s3Key.ToLower()) -AccessKey $awsAccessKey -SecretKey $awsSecretKey

    if (!($?)) {

        throw "Failed to upload connection string to S3!"

    } else {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Validating connection string upload..." -ForegroundColor Green

        Get-S3Object -BucketName $bucketName -Key $($s3Key.ToLower()) -AccessKey $awsAccessKey -SecretKey $awsSecretKey | Out-Null

        if (!($?)) {

            throw "Failed to validate if connection string is in S3"

        } else {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Connection String found in S3..." -ForegroundColor Green

        }

    }

}

if ($writeOutput) {

    Write-Output $connectionString

}