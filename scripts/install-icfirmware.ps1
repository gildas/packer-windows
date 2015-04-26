<# # Documentation {{{
  .Synopsis
  Installs CIC
#> # }}}
[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)][string] $User          = 'vagrant',
  [Parameter(Mandatory=$false)][string] $Password      = 'vagrant',
  [Parameter(Mandatory=$false)][string] $InstallPath   = 'C:\I3\IC',
  [Parameter(Mandatory=$true)][string]  $SourceDriveLetter = 'Z',
  [Parameter(Mandatory=$false)][switch] $Reboot
)
Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Now = Get-Date -Format 'yyyyMMddHHmmss'

$Source_filename       = "InteractionFirmware_2015_R2.msi"
$Source_checksum       = "E8B6903CD42E6C3600E85f979BD6D6C9"
$Source_download_tries = 3

# Prerequisites: {{{
# Prerequisite: Powershell 3 {{{2
if($PSVersionTable.PSVersion.Major -lt 3)
{
    Write-Error "Powershell version 3 or more recent is required"
    #TODO: Should we return values or raise exceptions?
    exit 1
}
# 2}}}

# Prerequisite: Find the source! {{{2
$InstallSource = ${SourceDriveLetter} + ':\Installs\ServerComponents'
if (! (Test-Path (Join-Path $InstallSource $Source_filename)i))
{
  Write-Error "IC Firmware Installation source not found in ${SourceDriveLetter}:"
  exit 1
}

Write-Output "Installing CIC from $InstallSource"
# 2}}}

# Prerequisite: .Net 3.5 {{{2
if ((Get-WindowsFeature Net-Framework-Core -Verbose:$false).InstallState -ne 'Installed')
{
  Write-Output "Installing .Net 3.5"
  Install-WindowsFeature -Name Net-Framework-Core
  # TODO: Check for errors
}
# 2}}}

# Prerequisite: Interaction Center Server {{{2
$Product = 'Interaction Center Server'
if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
{
  Write-Output "$Product is installed"
}
else
{
  #TODO: Should we return values or raise exceptions?
  Write-Error "$Product is not installed, aborting."
  exit 1
}
# 2}}}
# Prerequisites }}}

$InstalledProducts=0
$Product = 'Interaction Firmware'
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
  $parms += '/qb!'
  $parms += '/norestart'

  Start-Process -FilePath msiexec -ArgumentList $parms -Wait -Verbose
  # TODO: Check for errors
  $InstalledProducts += 1
}

if ($InstalledProducts -ge 1)
{
  if ($Reboot)
  {
    Restart-Computer
  }
  else
  {
    Write-Warning "Do not forget to reboot the computer once"
  }
}
Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
