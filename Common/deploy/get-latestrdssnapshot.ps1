param(
    [string] $awsAccessKey,
    [string] $awsSecretKey,
    [string] $region,
    [string] $stackName,
    [string] $dbSuffix
)

$rdsInstanceName = "time-$stackName-$dbSuffix"

$dbSnapshotId = (Get-RDSDBSnapshot -DBInstanceIdentifier $rdsInstanceName -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey | Sort-Object SnapshotCreateTime -Descending | Select-Object -First 1).DBSnapshotIdentifier

if (!($?)) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Failed to get the latest snapshot ID for $rdsInstanceName!" -ForegroundColor Yellow -BackgroundColor Red
    throw "Failed to get the latest snapshot ID for $rdsInstanceName!"

} else {

    Write-Output $dbSnapshotId

}