Param(
    [Parameter(Mandatory=$true)]  [string] $message,
    [Parameter(Mandatory=$false)]  [string] $etype = "Information"
)

if ((get-eventlog -LogName Application | Select-Object Source -Unique).source -notcontains "CustomEc2Config") {

    New-EventLog -source CustomEc2Config -LogName Application

}

if (!(Test-Path c:\logs)) {

    mkdir c:\logs -force | out-null

}

if ($etype -eq "Error") {

    Write-Eventlog -LogName Application -Source CustomEc2Config -EventId 1001 -EntryType Error -Message $message
    add-content -Path c:\logs\server.build.log -Value "$(get-date -Format 'yyyy-MM-dd HH:mm:ss') ERROR $message"

} else {

    Write-Eventlog -LogName Application -Source CustomEc2Config -EventId 1000 -EntryType Information -Message $message
    add-content -Path c:\logs\server.build.log -Value "$(get-date -Format 'yyyy-MM-dd HH:mm:ss') INFO $message"

}

Write-Output $message