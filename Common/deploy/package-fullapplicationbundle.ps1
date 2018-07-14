param(
    [array] $packagesToBundle,
    [string] $bundleDestinationPath,
    [string] $ebDeployPath,
    [string] $deploymentPackageRoot,
    [string] $functionPath
)

if (!(Test-Path $ebDeployPath)) {

    throw "Failed to find Deploy folder: $ebDeployPath!"

}

if (Test-Path $bundleDestinationPath) {

    remove-item -Recurse -Path $bundleDestinationPath -Force

    if (!($?)) {

        throw "Failed to delete bundleDirectory: $bundleDestinationPath!"

    }

}

mkdir $bundleDestinationPath | Out-Null

if (!($?)) {

    throw "Failed to create bundleDirectory: $bundleDestinationPath!"

}

Get-ChildItem $ebDeployPath | foreach {copy-item $_.FullName -Recurse -Destination $bundleDestinationPath}

foreach ($package in $packagesToBundle) {

    $packageZip = & "$functionPath\get-packagezip.ps1" -packagePath $deploymentPackageRoot -packageName $package
    Copy-Item -path $packageZip -Destination $bundleDestinationPath

}

$outputBundlePath = $($bundleDestinationPath + $(get-date -Format "_yyyyMMddHHmmss") + ".zip")
& "$functionPath\archive-this.ps1" -itemsToArchiveFolder $bundleDestinationPath -archivePath $outputBundlePath

Write-Output $outputBundlePath