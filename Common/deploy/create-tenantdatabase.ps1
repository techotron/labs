param(
    [string] $rdsEndpoint,
    [string] $databaseName,
    [string] $dbUsername,
    [string] $dbPassword,
    [string[]] $inputFiles,
    [string] $installScriptVersion,
    [string] $functionPath
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

    $existingDbCheck = 0
    $existingDbNames = (Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query "SELECT name FROM master.dbo.sysdatabases" -Username $dbUsername -Password $dbPassword -ErrorAction SilentlyContinue).name
            
    foreach ($existingDbName in $existingDbNames) {

        if ($databaseName -eq $existingDbName) {

            $existingDbCheck ++
            Write-Warning "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))] - Database with that name already exsists on: $rdsEndpoint. Attempting to Update..."

            & "$functionPath\update-datatenantdatabase.ps1" -rdsEndpoint $rdsEndpoint -databaseName $databaseName -dbUsername $dbUsername -dbPassword $dbPassword -inputFiles $inputFiles -installScriptVersion $installScriptVersion
                
        }

    }

    if ($existingDbCheck -eq 0) {

        if ($databaseName -eq (Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query "SELECT name FROM master.dbo.sysdatabases WHERE name = '$databaseName'" -Username $dbUsername -Password $dbPassword -ErrorAction SilentlyContinue).name) {

            foreach ($inputFile in $inputFiles) {
            
                try {
                
                    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Running $inputFile against $rdsEndpoint..." -ForegroundColor Green
                    Invoke-Sqlcmd -ServerInstance $rdsEndpoint -InputFile $inputFile -Database $databaseName -Username $dbUsername -Password $dbPassword

                } catch {

                    $Error[0,1]
                    throw "Failed to run $inputFile query against: $rdsEndpoint!"

                }

            }

        } else {

            throw "Database: $databaseName does not exist!"
                
        }
        
    }     

}