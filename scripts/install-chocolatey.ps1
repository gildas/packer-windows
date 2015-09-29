
#iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
(new-object net.webclient).DownloadFile('https://chocolatey.org/install.ps1', 'C:\Windows\Temp\install.ps1')

for($try = 0; $try -lt 5; $try++)
{
  & C:/Windows/Temp/install.ps1
  if ($?) { exit 0 }
}
Write-Error "Chocolatey failed to install, please re-build your machine again"
exit 2
