<# # Documentation {{{
  .Synopsis
  Installs CIC
#> # }}}
[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)][string] $User          = 'vagrant',
  [Parameter(Mandatory=$false)][string] $Password      = 'vagrant',
  [Parameter(Mandatory=$false)][string] $InstallPath   = 'C:\I3\IC',
  [Parameter(Mandatory=$false)][string] $InstallSource,
  [Parameter(Mandatory=$false)][switch] $Reboot
)
$Now = Get-Date -Format 'yyyyMMddHHmmss'

# Prerequisites: {{{
# Prerequisite: Powershell 3 {{{2
if($PSVersionTable.PSVersion.Major -lt 3)
{
    Write-Error "Powershell version 3 or more recent is required"
    #TODO: Should we return values or raise exceptions?
    return -1
}
# 2}}}

# Prerequisite: Find the source! {{{2
if (!$InstallSource)
{
  $sources  = @( 'C:\Windows\Temp' )

  $sources += (Get-Volume | Where { $_.DriveType -eq 'CD-ROM' -and $_.Size -gt 0 } | ForEach { $_.DriveLetter + ':\Installs\ServerComponents' })

  ForEach ($source in $sources)
  {
    Write-Debug "  Searching in $source"
    if (Test-Path "${source}\ICServer_2015_R1.msi")
    {
      $InstallSource = $source
      break
    }
  }
  if (!$InstallSource)
  {
    Write-Error "CIC Installation source not found, please provide a source via the command line arguments"
    return 1
  }
}
Write-Verbose "Installing CIC from $InstallSource"
# 2}}}

# Prerequisite: .Net 3.5 {{{2
if ((Get-WindowsFeature Net-Framework-Core -Verbose:$false).InstallState -ne 'Installed')
{
  Write-Verbose "Installing .Net 3.5"
  Install-WindowsFeature -Name Net-Framework-Core
  # TODO: Check for errors
}
# 2}}}
# Prerequisites }}}

$InstalledProducts=0
$Product = 'Interaction Center Server 2015 R1'
if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -eq $Product)
{
  Write-Verbose "$Product is already installed"
}
elseif (! (Test-Path "${InstallSource}\ICServer_2015_R1.msi"))
{
  #TODO: Should we return values or raise exceptions?
  Write-Error "Cannot install $Product, MSI not found in $InstallSource"
  return -1
}
else
{
  Write-Verbose "Installing $Product"
  #TODO: Capture the domain if it is in $User
  $Domain = $env:COMPUTERNAME

  $parms  = '/i',"${InstallSource}\ICServer_2015_R1.msi"
  $parms += "PROMPTEDUSER=$User"
  $parms += "PROMPTEDDOMAIN=$Domain"
  $parms += "PROMPTEDPASSWORD=$Password"
  $parms += "INTERACTIVEINTELLIGENCE=$InstallPath"
  $parms += "TRACING_LOGS=$InstallPath\Logs"
  $parms += 'STARTEDBYEXEORIUPDATE=1'
  $parms += 'CANCELBIG4COPY=1'
  $parms += 'OVERRIDEKBREQUIREMENT=1'
  $parms += 'REBOOT=ReallySuppress'
  $parms += '/l*v'
  $parms += "C:\Windows\Logs\icserver-${Now}.log"
  $parms += '/qb!'
  $parms += '/norestart'

  Start-Process -FilePath msiexec -ArgumentList $parms -Wait
  # TODO: Check for errors
  $InstalledProducts += 1
}

$Product = 'Interaction Firmware 2015 R1'
if (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -eq $Product)
{
  Write-Verbose "$Product is already installed"
}
elseif (! (Test-Path "${InstallSource}\InteractionFirmware_2015_R1.msi"))
{
  #TODO: Should we return values or raise exceptions?
  Write-Error "Cannot install $Product, MSI not found in $InstallSource"
  return -1
}
else
{
  Write-Verbose "Installing $Product"

  $parms  = '/i',"${InstallSource}\InteractionFirmware_2015_R1.msi"
  $parms += 'STARTEDBYEXEORIUPDATE=1'
  $parms += 'REBOOT=ReallySuppress'
  $parms += '/l*v'
  $parms += "C:\Windows\Logs\icfirmware-${Now}.log"
  $parms += '/qb!'
  $parms += '/norestart'

  Start-Process -FilePath msiexec -ArgumentList $parms -Wait
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
