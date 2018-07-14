param(
    [string] $path,
    [string] $destinationPath
)

if (Test-Path $destinationPath) {

    Remove-Item $destinationPath -Force -Confirm:$false -Recurse

}

if (Test-Path $path) {

    Expand-Archive -Path $path -DestinationPath $destinationPath
    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host "" -foregroundcolor gray -nonewline; write-host " - Expanded $path to $destinationPath..." -ForegroundColor Green

} else {

    Write-Warning "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))] - Could not find file to expand: $path"
    throw "Could not find file to expand: $path"

}
