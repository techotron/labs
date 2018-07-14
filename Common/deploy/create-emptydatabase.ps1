param(
    [string] $rdsEndpoint,
    [string] $databaseName,
    [string] $dbUsername,
    [string] $dbPassword,
    [string] $sqlApplicationUsername,
    [string] $sqlApplicationPassword,
    [string] $functionPath
)

### Empty Database Creation SQL #################################

$sqlQueryNewDb = "

CREATE DATABASE [$databaseName]
    CONTAINMENT = NONE
    ON  PRIMARY 
( NAME = N'$databaseName', FILENAME = N'D:\RDSDBDATA\DATA\$databaseName.mdf' , SIZE = 5120KB , FILEGROWTH = 10%)
    LOG ON 
( NAME = N'$databaseName`_log', FILENAME = N'D:\RDSDBDATA\DATA\$databaseName`_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%)
GO
ALTER DATABASE [$databaseName] COLLATE SQL_Latin1_General_CP1_CI_AS
GO
ALTER DATABASE [$databaseName] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [$databaseName] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [$databaseName] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [$databaseName] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [$databaseName] SET ARITHABORT OFF 
GO
ALTER DATABASE [$databaseName] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [$databaseName] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [$databaseName] SET AUTO_CREATE_STATISTICS ON
GO
ALTER DATABASE [$databaseName] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [$databaseName] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [$databaseName] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [$databaseName] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [$databaseName] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [$databaseName] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [$databaseName] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [$databaseName] SET  DISABLE_BROKER 
GO
ALTER DATABASE [$databaseName] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [$databaseName] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [$databaseName] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [$databaseName] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [$databaseName] SET  READ_WRITE 
GO
ALTER DATABASE [$databaseName] SET RECOVERY FULL 
GO
ALTER DATABASE [$databaseName] SET  MULTI_USER 
GO
ALTER DATABASE [$databaseName] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [$databaseName] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [$databaseName] SET DELAYED_DURABILITY = DISABLED 
GO
USE [$databaseName]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [$databaseName] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO

"

    

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
            Write-Warning "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))] - Database with that name already exsists on: $rdsEndpoint!"

        }

    }

    if ($existingDbCheck -eq 0) {
        
        # Create the new database 

        try {
                
            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Creating database: $databaseName on: $rdsEndpoint..." -ForegroundColor Green
            Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query $sqlQueryNewDb -Database master -Username $dbUsername -Password $dbPassword
            & "$functionPath\create-sqlusers.ps1" -rdsEndpoint $rdsEndpoint -databaseName $databaseName -dbUsername $dbUsername -dbPassword $dbPassword -sqlApplicationUsername $sqlApplicationUsername -sqlApplicationPassword $sqlApplicationPassword

        } catch {

            $Error[0]
            throw "Failed to create database: $databaseName on: $rdsEndpoint!"

        }
        
    }
        
    # Post creation check
        
    try {
        
        $postDbCreationCheck = (Invoke-Sqlcmd -ServerInstance $rdsEndpoint -Query "SELECT COUNT(*) FROM master.dbo.sysdatabases WHERE name = '$databaseName'" -Username $dbUsername -Password $dbPassword).Column1

        if ($postDbCreationCheck -ne 1) {

            throw "New database: $databaseName not found on: $rdsEndpoint!"

        }
        
    } catch {
        
        throw "Failed to check if new database: $databaseName was created!"
        
    }    

}