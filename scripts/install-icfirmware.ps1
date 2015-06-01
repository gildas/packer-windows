<# # Documentation {{{
  .Synopsis
  Installs CIC
#> # }}}
[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)][string] $SourceDriveLetter = 'I',
  [Parameter(Mandatory=$false)][switch] $Reboot
)
Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Now = Get-Date -Format 'yyyyMMddHHmmss'

$Product = 'Interaction Firmware'
$Source_filename = "InteractionFirmware_2015_R3.msi"

# Prerequisites: {{{
# Prerequisite: Powershell 3 {{{2
if($PSVersionTable.PSVersion.Major -lt 3)
{
    Write-Error "Powershell version 3 or more recent is required"
    Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Start-Sleep 2
    exit 1
}
# 2}}}

# Prerequisite: Find the source! {{{2
$InstallSource = ${SourceDriveLetter} + ':\Installs\ServerComponents'
if (! (Test-Path (Join-Path $InstallSource $Source_filename)))
{
  Write-Error "$Product Installation source not found in ${SourceDriveLetter}:"
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  Start-Sleep 2
  exit 2
}

Write-Output "Installing from $InstallSource"
# 2}}}

# Prerequisite: Interaction Center Server {{{2
if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "Interaction Center Server.*")
{
  Write-Output "Interaction Center Server is installed, we can proceed"
}
else
{
  Write-Error "Interaction Center Server is not installed, aborting."
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  Start-Sleep 2
  exit 3
}
# 2}}}
# Prerequisites }}}

if (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
{
  Write-Output "$Product is already installed"
}
else
{
  Write-Output "Installing $Product"

  $parms  = '/i',"${InstallSource}\${Source_filename}"
  $parms += 'STARTEDBYEXEORIUPDATE=1'
  $parms += 'REBOOT=ReallySuppress'
  $parms += '/l*v'
  $parms += "C:\Windows\Logs\icfirmware-${Now}.log"
  $parms += '/qn'
  $parms += '/norestart'

  $process = Start-Process -FilePath msiexec -ArgumentList $parms -Wait -PassThru
  if ($process.ExitCode -eq 0)
  {
    Write-Output "Success!"
  }
  elseif ($process.ExitCode -eq 3010)
  {
    if ($Reboot)
    {
      Write-Output "Restarting..."
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      Restart-Computer
      Start-Sleep 30
    }
    else
    {
      Write-Warning "Success, but rebooting is needed"
    }
  }
  else
  {
    Write-Error "Failure: Error= $($process.ExitCode), Logs=C:\Windows\Logs\vmware-tools.log"
    $exit_code = $process.ExitCode
  }
}
Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Start-Sleep 2
exit $exit_code
