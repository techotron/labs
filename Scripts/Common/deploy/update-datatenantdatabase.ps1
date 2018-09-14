param(
    [string] $rdsEndpoint,
    [string] $databaseName,
    [string] $dbUsername,
    [string] $dbPassword,
    [string[]] $inputFiles,
    [string] $installScriptVersion
)

# Check connection to the rdsEndpoint

try {
        
    $dbConnectionCheck = 0    
    $dbConnectionCheck = (Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query "SELECT COUNT(*) FROM master.dbo.sysdatabases" -Username $dbUsername -Password $dbPassword -ErrorAction SilentlyContinue).Column1

} catch {

    throw "Not able to connect to the RDS instance"

}

if ($dbConnectionCheck -gt 0) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Successfully connected to the RDS instance: $rdsEndpoint..." -ForegroundColor Green

    # Check if database name already exists on the RDS instance

    try {
        
        $existingDbCheck = 0
        $existingDbNames = (Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query "SELECT name FROM master.dbo.sysdatabases" -Username $dbUsername -Password $dbPassword -ErrorAction SilentlyContinue).name
            
        foreach ($existingDbName in $existingDbNames) {

            if ($databaseName -eq $existingDbNames) {

                $existingDbCheck ++
                throw "Database with that name already exsists on: $rdsEndpoint!"

            }

        }
        
    } catch {

        throw "Connection to RDS instance failed at existingDbCheck stage!"

    }

    if ($existingDbCheck -eq 0) {

        # Check current DB version

        try {

            $dbVersion = 0
            $dbVersion = Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query "SELECT ConfigValue1 FROM dbo.Config WHERE ConfigVariable = 'TMDatabaseVersion'" -Database $databaseName -Username $dbUsername -Password $dbPassword -ErrorAction SilentlyContinue

        } catch {

            throw "Failed to check database version!"

        }

        if ($dbVersion -ne 0) {

            foreach ($inputFile in $inputFiles) {
            
                try {
                
                    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Running $inputFile against $rdsEndpoint..." -ForegroundColor Green
                    Invoke-Sqlcmd -ServerInstance $rdsEndpoint -InputFile $inputFile -Database $databaseName -Username $dbUsername -Password $dbPassword

                } catch {

                    $Error[0,1]
                    throw "Failed to run $inputFile query against: $rdsEndpoint!"

                }

            }

        }
        
    }     

}