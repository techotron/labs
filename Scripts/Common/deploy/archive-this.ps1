param(
    [string] $itemsToArchiveFolder,
    [string] $archivePath
)

if (Test-path $archivePath) {
    
    Remove-item $archivePath
    
}

compress-archive -LiteralPath ((get-childitem $itemsToArchiveFolder).fullname) -DestinationPath $archivePath