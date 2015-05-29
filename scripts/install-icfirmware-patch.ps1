<# # Documentation {{{
  .Synopsis
  Installs CIC
#> # }}}
[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)][string] $User          = 'vagrant',
  [Parameter(Mandatory=$false)][string] $Password      = 'vagrant',
  [Parameter(Mandatory=$false)][string] $InstallPath   = 'C:\I3\IC',
  [Parameter(Mandatory=$false)][string] $SourceDriveLetter = 'I',
  [Parameter(Mandatory=$false)][switch] $Reboot
)
Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Now = Get-Date -Format 'yyyyMMddHHmmss'

$Product = 'Interaction Firmware'
$Source_filename = "InteractionFirmware_2015_R3_Patch2.msp"

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
if (! (Test-Path (Join-Path $InstallSource $Source_filename)))
{
  Write-Error "IC Server source not found in ${SourceDriveLetter}:"
  exit 1
}

Write-Output "Installing CIC from $InstallSource"
# 2}}}

# Prerequisite: Interaction Firmware {{{2
if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Wow6432Node\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
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

if (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayVersion -eq "15.3.2.28")
{
  Write-Output "$Product is already installed"
}
else
{
  Write-Output "Installing $Product"

  $parms  = '/update',"${InstallSource}\${Source_filename}"
  $parms += 'STARTEDBYEXEORIUPDATE=1'
  $parms += 'REBOOT=ReallySuppress'
  $parms += '/l*v'
  $parms += "C:\Windows\Logs\icfirmware-patch-${Now}.log"
  $parms += '/qn'
  $parms += '/norestart'

  Start-Process -FilePath msiexec -ArgumentList $parms -Wait -Verbose
  # TODO: Check for errors
  $InstalledProducts += 1
}

Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
