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
    Write-Error "IC Server Installation source not found, please provide a source via the command line arguments"
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
  if ((Test-Path "${source}\${Source_filename}") -and ($(C:\tools\sysinternals\Get-Checksum.ps1 -MD5 -Path ${source}\${Source_filename} -eq $Source_checksum)))
  {
    Write-Verbose "Installation has been downloaded already and is valid"
    $InstallSource = 'C:\Windows\Temp'
  }
  else
  {
    for ($i=0; $i -lt $Source_download_tries; $i++)
    {
      Write-Verbose "Downloading from $InstallSource, try: #${i}/${Source_download_tries}"
      Try
      {
        (New-Object System.Net.WebClient).DownloadFile("${InstallSource}/${Source_filename}", "${source}\${Source_filename}")
        if (Test-Path "${source}\${Source_filename}")
        {
          Write-Verbose "Downloaded install in $source, validating checksum"
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
    if ($i -lt $Source_download_tries)
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
    Write-Verbose "Found a valid install in ${InstallSource}"
  }
  else
  {
    Write-Error "Found an invalid source in ${InstallSource}"
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
# Prerequisites }}}

$InstalledProducts=0
$Product = 'Interaction Center Server 2015 R2'
if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -eq $Product)
{
  Write-Verbose "$Product is already installed"
}
else
{
  Write-Host "Installing $Product"
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
  $parms += '/qb!'
  $parms += '/norestart'

  # The ICServer MSI tends to not finish properly even if successful
  # And there is limit to the time a script can run over winrm/ssh
  # We will use other scripts to check if the install was successful
  Start-Process -FilePath msiexec -ArgumentList $parms
  Write-Verbose "$Product is installing"
}
Write-Verbose "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
