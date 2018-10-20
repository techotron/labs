$files = @(
"https://s3-eu-west-1.amazonaws.com/357128852511-eddy-public/6e3af03c-febf-4387-8002-e03af05a10fd/tools/write-event-log.ps1",
"https://s3-eu-west-1.amazonaws.com/357128852511-eddy-public/6e3af03c-febf-4387-8002-e03af05a10fd/tools/quick-putty-logon.ps1",
"https://s3-eu-west-1.amazonaws.com/357128852511-eddy-public/6e3af03c-febf-4387-8002-e03af05a10fd/tools/download-file.ps1"
)

foreach ($file in $files) {

    write-host "Downloading: $file"
    Invoke-WebRequest -Uri $file -OutFile c:\downloads

}