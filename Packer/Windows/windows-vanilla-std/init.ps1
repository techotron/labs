$files = (get-childitem c:\downloads).fullname

write-host "Starting script: " $Env:SCRIPT_NAME

foreach ($file in $files) {

    write-host "This is a file: $file"

}