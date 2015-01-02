$icadminpassword = "vagrant"

if($PSVersionTable.PSVersion.Major -lt 3){
    Write-Host "powershell version 3 required" -foreground "red"
    Write-host "Download it from http://www.microsoft.com/en-us/download/details.aspx?id=34595"
    return
}

$installFramework = test-path InteractionFirmware*msi
$installIcServer = test-path ICServer*msi

if( !$installFramework){
    write-host "Interaction Firmware install is not present in this directory" -ForegroundColor Red
    return
}

if( !$installIcServer){
    write-host "CIC server install is not present in this directory" -ForegroundColor Red
    return
}

function WaitForMsiToFinish
{
    $fullInstall = $false
    [System.Console]::Write("Waiting for install to finish...")
    do{
        sleep 10
        $procCount = @(Get-Process | ? { $_.ProcessName -eq "msiexec" }).Count

        if($procCount -gt 1){
            $fullInstall = $true
        }

        $isDone = $fullInstall -and ($procCount -le 1)
    }while ($isDone -ne $true)

    sleep 5
    #this is a hack.  msiexec doesn't full exit, so we need to kill it.
    Stop-Process -processname msiexec -erroraction 'silentlycontinue' -Force

    Write-Host "DONE" -foreground "green"
}

Write-Host "This install and setup process can take a long time, please do not interrupt the process"  -foregroundcolor cyan
write-host "When complete, you should not see any error in the console"  -foregroundcolor cyan

Write-Host "Installing CIC"
Invoke-Expression "msiexec /i ICServer_2015_R1.msi PROMPTEDUSER=$env:username PROMPTEDDOMAIN=$env:userdomain PROMPTEDPASSWORD=$icadminpassword INTERACTIVEINTELLIGENCE='c:\i3\ic' TRACING_LOGS='c:\i3\ic\logs' STARTEDBYEXEORIUPDATE=1 CANCELBIG4COPY=1 OVERRIDEKBREQUIREMENT=1 REBOOT=ReallySuppress /l*v icserver.log /qb! /norestart"
WaitForMsiToFinish

[System.Console]::Write("Installing Interaction Firmware...")
$args = "/i InteractionFirmware_2015_R1.msi STARTEDBYEXEORIUPDATE=1 REBOOT=ReallySuppress /l*v icfirmware.log /qb! /norestart"
Start-Process -FilePath "msiexec" -ArgumentList $args -Wait

Write-Host "DONE" -foreground "green"

write-host "INSTALL IS COMPLETE, PLEASE REBOOT THIS SERVER" -foreground Green
