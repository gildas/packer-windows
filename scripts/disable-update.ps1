$WindowsUpdateKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"

$Update_Never    = 1
$Update_Check    = 2
$Update_Download = 3
$Update_Auto     = 4

Set-ItemProperty -Path $WindowsUpdateKey -Name AUOptions       -Value $Update_Never -Force -Confirm:$false
Set-ItemProperty -Path $WindowsUpdateKey -Name CachedAUOptions -Value $Update_Never -Force -Confirm:$false
