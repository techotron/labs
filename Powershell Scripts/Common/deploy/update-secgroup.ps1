param(
    [string] $securityGroupId,
    [ValidateSet("addIp","removeIp")][string] $action,
    [string] $awsAccessKey,
    [string] $awsSecretKey,
    [string] $region,
    [ValidateSet("mssql","postgresql")][string] $application,
    [string] $ipAddress
)

if ($application -eq "mssql") {

    $port = 1433

} elseif ($application -eq "postgresql") {

    $port = 5432

}

$protectedIps = @("81.130.156.208","92.60.188.189","193.105.219.210")
$securityGroupName = (Get-EC2SecurityGroup -GroupId $securityGroupId -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Region $region).Description

if ($action -eq "addIp") {
    
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Updating $securityGroupName to add $ipAddress to access $port..." -ForegroundColor Green
    $ipRange = $("$ipAddress/32")
    $ruleToAdd = @{ IpProtocol="tcp"; FromPort=$port; ToPort=$port; IpRanges=$ipRange }
    
    try {

        Grant-EC2SecurityGroupIngress -GroupId $securityGroupId -IpPermission $ruleToAdd -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Region $region

        if (!($?)) {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Failed to add IP: $ipAddress to access sec group Id: $securityGroupId!" -ForegroundColor Red -BackgroundColor Yellow

        } else {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Added IP: $ipAddress to access sec group Id: $securityGroupId for port: $port..." -ForegroundColor Green

        }

    } catch {

        if ($error[0].Exception -like "*the specified rule*already exists*") {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Rule for IP: $ipAddress to access port: $port already exists. Nothing to change." -ForegroundColor Green

        } else {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Failed to add IP: $ipAddress to access sec group Id: $securityGroupId!" -ForegroundColor Red -BackgroundColor Yellow
            throw "Failed to add IP: $ipAddress to access sec group Id: $securityGroupId!"

        }

    }

}

if ($action -eq "removeIp") {
    
    if ($protectedIps -contains $ipAddress) {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Protected IP - not changing security group" -ForegroundColor Green        

    } else {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Updating $securityGroupName to remove $ipAddress to access $port..." -ForegroundColor Green
        $ipRange = $("$ipAddress/32")
        $ruleToRemove = @{ IpProtocol="tcp"; FromPort=$port; ToPort=$port; IpRanges=$ipRange }
    
        try {
    
            Revoke-EC2SecurityGroupIngress -GroupId $securityGroupId -IpPermission $ruleToRemove -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Region $region

            if (!($?)) {

                Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Failed to remove IP: $ipAddress to access sec group Id: $securityGroupId!" -ForegroundColor Red -BackgroundColor Yellow

            } else {

                Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Removed IP: $ipAddress to access sec group Id: $securityGroupId for port: $port..." -ForegroundColor Green

            }

        } catch {

            if ($error[0].Exception -like "*the specified rule*already exists*") {

                Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Rule for IP: $ipAddress to access port: $port already exists. Nothing to change." -ForegroundColor Green

            } else {

                Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Failed to remove IP: $ipAddress to access sec group Id: $securityGroupId!" -ForegroundColor Red -BackgroundColor Yellow
                throw "Failed to add IP: $ipAddress to access sec group Id: $securityGroupId!"

            }

        }

    }

}
