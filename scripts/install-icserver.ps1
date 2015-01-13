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
Write-Verbose "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Now = Get-Date -Format 'yyyyMMddHHmmss'

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
    exit 1
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
  exit 1
}
elseif (! $(C:\tools\sysinternals\Get-Checksum.ps1 -SHA1 -Path ${InstallSource}\ICServer_2015_R1.msi -eq '3D5F82A700E441498C12F930DB110865195B4A9B'))
{
  Write-Error "Cannot install $Product, MSI found in $InstallSource is corrupted"
  exit 1
}
else
{
  Write-Host "Installing $Product"
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

  # The ICServer MSI tends to not finish properly even if successful
  # And there is limit to the time a script can run over winrm/ssh
  # We will use other scripts to check if the install was successful
  Start-Process -FilePath msiexec -ArgumentList $parms
  Write-Verbose "$Product is installing"
}
Write-Verbose "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
