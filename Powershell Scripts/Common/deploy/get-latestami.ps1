param(
    [string] $region,
    [string] $imageName,
    [string] $awsAccessKey,
    [string] $awsSecretKey
)

if ($imageName -eq "ubuntu-16.04") {

    $imageId = "ami-2a7d75c0"

} else {

    $imageId = (Get-EC2ImageByName -Name "*$imageName" -region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey | Sort-Object CreationDate -Descending).imageId[0]

}

if (!($?)) {

    throw "Failed to get Image ID for latest AMI!"
        
} else {

    Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Retrieved latest AMI for $imageName`: $imageId" -ForegroundColor Green
    Write-Output $imageId

}