param(
    [Parameter(Mandatory=$true)][string] $sqlStatement,
    [Parameter(Mandatory=$true)][string] $rdsEndpoint,
    [Parameter(Mandatory=$true)][string] $databaseName,
    [Parameter(Mandatory=$true)][string] $dbUsername,
    [Parameter(Mandatory=$true)][string] $dbPassword
)

try {
        
    $dbConnectionCheck = 0    
    $dbConnectionCheck = (Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query "SELECT COUNT(*) FROM master.dbo.sysdatabases" -Username $dbUsername -Password $dbPassword -ErrorAction SilentlyContinue).Column1

} catch {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Not able to connect to the RDS instance!" -ForegroundColor Red -BackgroundColor Yellow
    throw "Not able to connect to the RDS instance!"

}

if ($dbConnectionCheck -gt 0) {

    Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query $sqlStatement -Database $databaseName -Username $dbUsername -Password $dbPassword

}