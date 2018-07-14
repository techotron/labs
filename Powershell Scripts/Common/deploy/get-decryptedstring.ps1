Param(
  [string]$stringToDecrypt,
  [string]$pathToTimeCoreDll #e.g. "D:\Dev\timecloud-scripts\Cloud Formation Templates\Convergence\build\Intapp.Time.Core.dll"
)

Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Decrypting $stringToDecrypt..." -ForegroundColor Green

$job = Start-Job -ScriptBlock {

    $stringToDecrypt = $args[0]
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

    # Call DecryptString method
    $decryptedString = $cryptoInstance.DecryptString($stringToDecrypt)

    return $decryptedString

} -ArgumentList $stringToDecrypt, $pathToTimeCoreDll

Wait-Job $job | Out-Null

if ((Get-Job $($job.id)).JobStateInfo.State -ne "Completed") {

    Receive-Job $job
    throw "Failed to decrypt string!"

} else {

    Receive-Job $job

}