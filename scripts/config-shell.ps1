Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value 'Powershell.exe -NoExit -Command "$PSVersionTable; cd $env:userprofile"' -Force
