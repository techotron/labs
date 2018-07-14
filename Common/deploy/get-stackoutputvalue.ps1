param(
    [string] $stackName,
    [string] $exportName,
    [string] $awsAccessKey,
    [string] $awsSecretKey,
    [string] $region
)

Write-Output (Get-CFNStack -StackName $stackName -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Region $region | Select-Object -ExpandProperty outputs | where {$_.exportName -eq "$exportName"}).outputvalue