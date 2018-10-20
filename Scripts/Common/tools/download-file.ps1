param(
    [string] $uri,
    [string] $outPath
)

& c:\init_scripts\common\write-event-log.ps1 -message "Downloading from $uri to $outPath..."

$directory = split-path -path $outPath

if (!(Test-Path $directory)) {

    & c:\init_scripts\common\write-event-log.ps1 -message "$directory does not exist. Creating now..."
    new-item -ItemType Directory -Path $directory -Force | out-null

}

Invoke-WebRequest -Uri $uri -OutFile $outPath

if (!($?)) {

    & c:\init_scripts\common\write-event-log.ps1 -message "Failed to download $uri!" -eType Error
    throw "Failed to download $uri!"

} else {

    if (Test-Path $outPath) {

        & c:\init_scripts\common\write-event-log.ps1 -message "Confirmed that $outPath exists"

    } else {

        & c:\init_scripts\common\write-event-log.ps1 -message "$outPath does not exist!" -eType Error
        throw "$outPath does not exist!"

    }

}