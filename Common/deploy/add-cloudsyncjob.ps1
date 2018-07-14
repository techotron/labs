param(
    [string] $region,
    [string] $dynamoDbTableName,
    [string] $companyName,
    [string] $addDbTableScriptPath,
    [string] $awsAccessKey,
    [string] $awsSecretKey
)

try {
        
    Get-DDBTable -TableName $dynamoDbTableName -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey | Out-Null

    if ($?) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Adding CloudSyncJob to $dynamoDbTableName..." -ForegroundColor green
        python $addDbTableScriptPath $region $dynamoDbTableName $companyName $awsAccessKey $awsSecretKey

    }

} catch {

    if ($error[0].Exception -like "*Requested resource not found: Table:*not found*") {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - $dynamoDbTableName not found!" -ForegroundColor Yellow -BackgroundColor Red
        throw "$dynamoDbTableName not found!"

    } else {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - ERROR: $($error[0].Exception)" -ForegroundColor Yellow -BackgroundColor Red
        throw "ERROR: $($error[0].Exception)"

    }

}