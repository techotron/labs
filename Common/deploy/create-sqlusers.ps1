param(
    [string] $rdsEndpoint,
    [string] $databaseName,
    [string] $dbUsername,
    [string] $dbPassword,
    [string] $sqlApplicationUsername,
    [string] $sqlApplicationPassword
)

$sqlQueryNewSqlUser = "

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = '$sqlApplicationUsername')

    CREATE LOGIN [$sqlApplicationUsername] WITH PASSWORD=N'$sqlApplicationPassword', DEFAULT_DATABASE=[$databaseName], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
        
    USE [$databaseName]
    GO

    CREATE USER [$sqlApplicationUsername] FOR LOGIN [$sqlApplicationUsername]
    ALTER ROLE [db_owner] ADD MEMBER [$sqlApplicationUsername]
    GO

"

try {
        
    $dbConnectionCheck = 0    
    $dbConnectionCheck = (Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query "SELECT COUNT(*) FROM master.dbo.sysdatabases" -Username $dbUsername -Password $dbPassword -ErrorAction SilentlyContinue).Column1

} catch {

    throw "Not able to connect to the RDS instance"

}

if ($dbConnectionCheck -gt 0) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Creating new SQL user: $sqlApplicationUsername..." -ForegroundColor Green
    Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query $sqlQueryNewSqlUser -Database master -Username $dbUsername -Password $dbPassword

}