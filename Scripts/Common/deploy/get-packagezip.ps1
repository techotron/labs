param (
    [string] $packagePath,
    [string] $packageName
)

if (Test-Path -Path $packagePath) {

    $fullPath = (Get-ChildItem -Path $packagePath -Recurse | where {$_.name -like "$packageName*"}).FullName | Select-String -Pattern "$packageName.\d.\d.\d*"
    Write-Output $fullPath

} else {

    throw "Deployment package path not found!"

}