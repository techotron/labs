Param(
  [string]$stringToEncrypt,
  [string]$pathToTimeCoreDll #e.g. "D:\Dev\timecloud-scripts\Cloud Formation Templates\Convergence\build\Intapp.Time.Core.dll"
)

Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Encrypting $stringToEncrypt before inserting into the db..." -ForegroundColor Green

$job = Start-Job -ScriptBlock {

    $stringToEncrypt = $args[0]
    $pathToTimeCoreDll = $args[1]

    try {

        # Load Assembly into memory
        [Reflection.Assembly]::LoadFile($pathToTimeCoreDll) | Out-Null

    } catch {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Failed to load the time core dll with exception: $($error[0].Exception)" -ForegroundColor Red -BackgroundColor Yellow    
        throw "Failed to load the time core dll!"

    }

    # Create instance of Crypto class
    $cryptoInstance = New-Object Intapp.Time.Core.Security.Crypto

    # Call EncryptString method
    $encryptedString = $cryptoInstance.EncryptString($stringToEncrypt)

    return $encryptedString

} -ArgumentList $stringToEncrypt, $pathToTimeCoreDll

Wait-Job $job | Out-Null

if ((Get-Job $($job.id)).JobStateInfo.State -ne "Completed") {

    Receive-Job $job
    throw "Failed to encrypt string!"

} else {

    Receive-Job $job

}