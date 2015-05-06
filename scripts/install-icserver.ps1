# IC Server Installation
#
#

<# # Documentation {{{
  .Synopsis
  Installs CIC
#> # }}}
[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)][string] $User               = 'vagrant',
  [Parameter(Mandatory=$false)][string] $Password           = 'vagrant',
  [Parameter(Mandatory=$false)][string] $InstallPath        = 'C:\I3\IC',
  [Parameter(Mandatory=$false)][string]  $SourceDriveLetter = 'Z',
  [Parameter(Mandatory=$false)][switch] $Wait,
  [Parameter(Mandatory=$false)][switch] $Reboot
)
Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Now = Get-Date -Format 'yyyyMMddHHmmss'

$Source_filename       = "ICServer_2015_R2.msi"
$Source_checksum       = "901AC9B42DD4EB454FF23B7B301A74A6"
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
if (! (Test-Path (Join-Path $InstallSource $Source_filename)))
{
  Write-Error "IC Server Installation source not found in ${SourceDriveLetter}:"
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
# Prerequisites }}}

$Product = 'Interaction Center Server 2015 R2'
if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -eq $Product)
{
  Write-Output "$Product is already installed"
}
else
{
  Write-Output "Installing $Product"
  #TODO: Capture the domain if it is in $User
  $Domain = $env:COMPUTERNAME

  $parms  = '/i',"${InstallSource}\${Source_filename}"
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
  $parms += '/qn'
  $parms += '/norestart'

  if ($Wait)
  {
    $stop_watch = [Diagnostics.StopWatch]::StartNew()
    $process    = Start-Process -PassThru -Wait -FilePath msiexec -ArgumentList $parms
    $stop_watch.Stop()
    $elapsed = ''
    if ($stop_watch.Elapsed.Days    -gt 0) { $elapsed = " $($stop_watch.Elapsed.Days) days" }
    if ($stop_watch.Elapsed.Hours   -gt 0) { $elapsed = " $($stop_watch.Elapsed.Hours) hours" }
    if ($stop_watch.Elapsed.Minutes -gt 0) { $elapsed = " $($stop_watch.Elapsed.Minutes) minutes" }
    if ($stop_watch.Elapsed.Seconds -gt 0) { $elapsed = " $($stop_watch.Elapsed.Seconds) seconds" }
    Write-Output "$Product installed successfully in $elapsed"
  }
  else
  {
    $process = Start-Process -PassThru -FilePath msiexec -ArgumentList $parms
  }
}
Start-Sleep 5
Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
