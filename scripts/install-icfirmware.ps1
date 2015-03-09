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
if (!$InstallSource)
{
  $sources  = @( 'C:\Windows\Temp' )
  $sources += (Get-Volume | Where { $_.DriveType -eq 'CD-ROM' -and $_.Size -gt 0 } | ForEach { $_.DriveLetter + ':\Installs\ServerComponents' })

  ForEach ($source in $sources)
  {
    Write-Debug "  Searching in $source"
    if (Test-Path "${source}\${Source_filename}")
    {
      Write-Verbose "Found install in $source, validating checksum"
      if ($(C:\tools\sysinternals\Get-Checksum.ps1 -MD5 -Path ${source}\${Source_filename} -eq $Source_checksum))
      {
        Write-Verbose "Found a valid install in $source"
        $InstallSource = $source
        break
      }
      Write-Debug "Found an invalid source in $source"
    }
  }
  if (!$InstallSource)
  {
    Write-Error "IC Firmware Installation source not found, please provide a source via the command line arguments"
    exit 1
  }
}
elseif ($InstallSource -match 'http://.*')
{
  $source = 'C:\Windows\Temp'
  if ($InstallSource -match 'http://\*:([0-9]+)')
  {
    $port    = $matches[1]
    $address = ((Get-NetIPConfiguration).IPv4DefaultGateway).NextHop
    $InstallSource = "http://${address}:${port}"
  }
  if (Test-Path "${source}\${Source_filename}" -and $(C:\tools\sysinternals\Get-Checksum.ps1 -MD5 -Path ${source}\${Source_filename} -eq $Source_checksum))
  {
    Write-Verbose "Installation has been downloaded already and is valid"
    $InstallSource = 'C:\Windows\Temp'
  }
  else
  {
    for ($i=0; $i < $Source_download_tries; $i++)
    {
      Write-Verbose "Downloading from $InstallSource, try: #${i}/${Source_download_tries}"
      Try
      {
        (New-Object System.Net.WebClient).DownloadFile("${InstallSource}/${Source_filename}", "${source}\${Source_filename}")
        if (Test-Path "${source}\${Source_filename}")
        {
          Write-Verbose "Found install in $source, validating checksum"
          if ($(C:\tools\sysinternals\Get-Checksum.ps1 -MD5 -Path ${source}\${Source_filename} -eq $Source_checksum))
          {
            Write-Verbose "Downloaded a valid install in $source"
            $InstallSource = $source
            break
          }
          Write-Warning "Downloaded source is corrupted, trying again"
        }
      }
      Catch
      {
        Write-Warning "Cannot download source from $source, trying again"
      }
    }
    if ($i < $Source_download_tries)
    {
      $InstallSource = 'C:\Windows\Temp'
    }
    else
    {
      Write-Error "Installation was not downloaded properly"
      exit 1
    }
  }
}
elseif (Test-Path "${InstallSource}\${Source_filename}")
{
  Write-Verbose "Found install in ${InstallSource}, validating checksum"
  if ($(C:\tools\sysinternals\Get-Checksum.ps1 -MD5 -Path ${InstallSource}\${Source_filename} -eq $Source_checksum))
  {
    Write-Verbose "Found a valid install in $source"
  }
  else
  {
    Write-Error "Found an invalid source in $source"
    exit 1
  }
}
else
{
  Write-Error "Source not found in $source"
  exit 1
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

# Prerequisite: Interaction Center Server {{{2
$Product = 'Interaction Center Server'
if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
{
  Write-Verbose "$Product is installed"
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
  Write-Verbose "$Product is already installed"
}
else
{
  Write-Host "Installing $Product"

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
Write-Verbose "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
