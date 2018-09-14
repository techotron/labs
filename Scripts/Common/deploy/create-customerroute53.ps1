param(
    [string] $domainName,
    [string] $elbCname,
    [string] $Route53ZoneDomain,
    [string] $awsAccessKey,
    [string] $awsSecretKey,
    [string] $region
)

$hostedZoneId = (Get-R53HostedZonesByName -AccessKey $awsAccessKey -SecretKey $awsSecretKey | where {$_.Name -eq $Route53ZoneDomain}).id
$recordSet = Get-R53ResourceRecordSet -HostedZoneId $hostedZoneId -AccessKey $awsAccessKey -SecretKey $awsSecretKey | Select-Object -ExpandProperty ResourceRecordSets | where {$_.name -eq $($domainName + ".$Route53ZoneDomain")}
        
if ($recordSet -ne $null) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Found record for: $($domainName + ".$Route53ZoneDomain"). Updating record with new CNAME..." -ForegroundColor Green
        
} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Creating a new record for: $($domainName + ".$Route53ZoneDomain")..." -ForegroundColor Green

}

$oldCnameValue = $recordSet.resourcerecords

$change1 = New-Object Amazon.Route53.Model.Change
$change1.Action = "UPSERT"
$change1.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$change1.ResourceRecordSet.Name = $($domainName + ".$Route53ZoneDomain")
$change1.ResourceRecordSet.Type = "CNAME"
$change1.ResourceRecordSet.TTL = 300
$change1.ResourceRecordSet.ResourceRecords.Add(@{Value=$elbCname})

Edit-R53ResourceRecordSet -ChangeBatch_Change $change1 -HostedZoneId $hostedZoneId -ChangeBatch_Comment "Update record for $($domainName) from $oldCnameValue to $elbCname" -AccessKey $awsAccessKey -SecretKey $awsSecretKey | Out-Null


# Validate new record
$newRecordSet = ((Get-R53ResourceRecordSet -HostedZoneId $hostedZoneId -AccessKey $awsAccessKey -SecretKey $awsSecretKey | Select-Object -ExpandProperty ResourceRecordSets | where {$_.name -eq $($domainName + ".$Route53ZoneDomain")}).ResourceRecords).value
    
if ($elbCname -ne $newRecordSet) {

    throw "Record: $domainName is not pointing to new ELB!"
    
} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Record: $domainName has been changed correctly..." -ForegroundColor Green

}