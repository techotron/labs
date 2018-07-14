param(
    [string] $waitForStackName,
    [string] $stackName,
    [string] $stackUrl,
    [array] $parameters,
    [array] $tags,
    [string] $awsAccessKey,
    [string] $awsSecretKey,
    [string] $region,
    [string] $cfnWaitTimeOut,
    [array] $dependsOnStacks
)

if ($waitForStackName) {

    Wait-CFNStack -StackName $waitForStackName -Status CREATE_COMPLETE, UPDATE_COMPLETE -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Timeout $cfnWaitTimeOut -ErrorAction SilentlyContinue | Out-Null

}

if ($dependsOnStacks.count -gt 0) {

    foreach ($dependsOnStack in $dependsOnStacks) {

        try {

            get-cfnstack -StackName $dependsOnStack -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -ErrorAction SilentlyContinue | Out-Null

        } catch {}

        if (!($?)) {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Failed to confirm that $dependsOnStack exists. Can't deploy $stackName without it!" -ForegroundColor Yellow -BackgroundColor Red
            throw "Failed to confirm that $dependsOnStack exists. Can't deploy $stackName without it!"

        } else {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Confirmed prerequisite stack: $dependsOnStack exists..." -ForegroundColor Green

        }

    }

}

try {

    $stackCheck = get-cfnstack -StackName $stackName -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -ErrorAction SilentlyContinue | Out-Null

    } catch {}

if ($?) {
    
    try {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Updating $stackName..." -ForegroundColor green
        Update-CFNStack -StackName $stackName -TemplateURL $stackUrl -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Parameter $parameters -Capability CAPABILITY_IAM, CAPABILITY_NAMED_IAM -Tag $tags -ErrorAction Stop

    } catch {

        if ($($error[0]) -like "*No updates are to be performed*") {
             
            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - No updates found for $stackName" -ForegroundColor darkyellow

        } elseif ($($error[0] -like "*DELETE_IN_PROGRESS state and can not be updated*")) {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack: $stackName still in deleting state." -ForegroundColor Yellow -BackgroundColor Red
            # TODO: Wait function

        } else {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Error Deploying stack: $stackName`: $($error[0])" -ForegroundColor Yellow -BackgroundColor Red

        }

    }

} else {

    try {

        Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Creating $stackName..." -ForegroundColor darkyellow
        New-CFNStack -StackName $stackName -TemplateURL $stackUrl -Region $region -AccessKey $awsAccessKey -SecretKey $awsSecretKey -Parameter $parameters -Capability CAPABILITY_IAM, CAPABILITY_NAMED_IAM -Tag $tags

    } catch {

        if ($($error[0] -like "*DELETE_IN_PROGRESS state and can not be updated*")) {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Stack: $stackName still in deleting state." -ForegroundColor Yellow -BackgroundColor Red
            # TODO: Wait function

        } elseif ($($error[0]) -like "*") {

            Write-Host "[$((get-date).tostring('dd/MM/yy HH:mm:ss'))]" -foregroundcolor gray -nonewline; write-host " - Error Deploying stack: $stackName`: $($error[0])" -ForegroundColor Yellow -BackgroundColor Red

        }

    }

}