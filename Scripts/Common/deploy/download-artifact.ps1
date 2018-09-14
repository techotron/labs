param(
    [string] $apiKey,
    [string] $url,
    [string] $branch,
    [string] $outFolder,
    [array] $applications
)

$headers = @{ "X-JFrog-Art-Api" = $apiKey }

if (!(Test-Path $outFolder)) {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - $outFolder not found. Creating..." -ForegroundColor darkyellow
    mkdir $outFolder -Force | Out-Null

    if (!($?)) {

        throw "Failed to create $outFolder!"

    } else {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Created $outFolder..." -ForegroundColor Green

    }

}

if ($apiKey -eq "") {

    throw "Failed to find an API key!"

}

$fileNames = ((Invoke-WebRequest -uri $($url + $branch) -headers $headers).links).innerHTML | where {$_ -notlike "../"}

foreach ($application in $applications) {

    foreach ($fileName in $fileNames) {
        
        if ($fileName | select-string -Pattern "$application.\d.\d.\d*") {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Downloading $fileName..." -ForegroundColor darkyellow

            $outfile = $($outFolder + "\$fileName")
            $uri = $($url + "$branch/" + $fileName)

            if (Test-Path $outfile) {

                Remove-Item $outfile -Force | Out-Null

            }

            Invoke-WebRequest -uri $uri -headers $headers -OutFile $outfile

            if (!(Test-Path $outfile)) {

                throw "Failed to download file from artifactory!"

            } else {

                $artifactoryChecksum = (Invoke-WebRequest -uri $uri -headers $headers -Method Head).headers["X-Checksum-Sha256"]
                $downloadedChecksum = (Get-FileHash -Path $outfile -Algorithm SHA256).hash
            
                if (!($artifactoryChecksum -eq $downloadedChecksum)) {

                    Write-Warning "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))] - Checksum failed for $fileName...re-downloading..."
                    Invoke-WebRequest -uri $uri -headers $headers -OutFile $outfile

                    $artifactoryChecksum = (Invoke-WebRequest -uri $uri -headers $headers -Method Head).headers["X-Checksum-Sha256"]
                    $downloadedChecksum = (Get-FileHash -Path $outfile -Algorithm SHA256).hash

                    if (!($artifactoryChecksum -eq $downloadedChecksum)) {

                        throw "Final Checksum failed for $fileName!"

                    } else {

                        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Second download attempted successful for $fileName" -ForegroundColor Green

                    }

                } else {

                    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Checksum passed for $fileName" -ForegroundColor Green

                }

            }

        }

    }

}