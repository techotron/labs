param(
    [string] $rdsStackName,
    [string] $dbType,
    [string] $dbSuffix,
    [string] $awsAccessKey,
    [string] $awsSecretKey,
    [string] $region
)

Remove-Variable rdsEndpoint -Force -ErrorAction SilentlyContinue

$rdsEndpoint = (Get-CFNStack -StackName $rdsStackName -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Region $region | Select-Object -ExpandProperty outputs | where {$_.exportName -eq "time-$stackName-rdsDatabaseEndpoint-$dbType-$dbSuffix"}).outputvalue
Write-Output $rdsEndpoint