<# # Documentation {{{
  .Synopsis
  Installs Interaction Center Firmware
#> # }}}
[CmdletBinding(SupportsShouldProcess=$true)]
Param(
  [Parameter(Mandatory=$false)]
  [string] $SourceDriveLetter,
  [Parameter(Mandatory=$false)]
  [switch] $Reboot
)
begin
{
  Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  $Now        = Get-Date -Format 'yyyyMMddHHmmss'
  $Product    = 'Interaction Firmware'
  $msi_prefix = 'InteractionFirmware'
  $Log        = "C:\Windows\Logs\${msi_prefix}-${Now}.log"
}
process
{
  function Show-Elapsed([Diagnostics.StopWatch] $watch) # {{{
  {
    $elapsed = ''
        if ($watch.Elapsed.Days    -gt 1) { $elapsed += " $($watch.Elapsed.Days) days" }
    elseif ($watch.Elapsed.Days    -gt 0) { $elapsed += " $($watch.Elapsed.Days) day"  }
        if ($watch.Elapsed.Hours   -gt 1) { $elapsed += " $($watch.Elapsed.Hours) hours" }
    elseif ($watch.Elapsed.Hours   -gt 0) { $elapsed += " $($watch.Elapsed.Hours) hour"  }
        if ($watch.Elapsed.Minutes -gt 1) { $elapsed += " $($watch.Elapsed.Minutes) minutes" }
    elseif ($watch.Elapsed.Minutes -gt 0) { $elapsed += " $($watch.Elapsed.Minutes) minute"  }
        if ($watch.Elapsed.Seconds -gt 0) { $elapsed += " $($watch.Elapsed.Seconds) seconds" }
    return $elapsed
  } # }}}

# Prerequisites: {{{
# Prerequisite: Product is not installed {{{2
  if (Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
  {
    Write-Output "$Product is already installed"
    exit
  }
  if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
  {
    Write-Output "$Product is already installed"
    exit
  }
# 2}}}

# Prerequisite: Powershell 3 {{{2
  if($PSVersionTable.PSVersion.Major -lt 3)
  {
      Write-Error "Powershell version 3 or more recent is required"
      Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
      Start-Sleep 2
      exit 1
  }
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

# Prerequisite: Find the source! {{{2
  if ([string]::IsNullOrEmpty($SourceDriveLetter))
  {
    if (Test-Path $env:USERPROFILE/mounted.info)
    {
      $SourceDriveLetter = Get-Content $env:USERPROFILE/mounted.info
      Write-Verbose "Got drive letter from a previous mount: $SourceDriveLetter"
    }
    else
    {
      $SourceDriveLetter = ls function:[d-z]: -n | ?{ Test-Path "$_\Installs\ServerComponents" } | Select -First 1
      if ([string]::IsNullOrEmpty($SourceDriveLetter))
      {
        Write-Error "No drive containing installation for $Product was mounted"
        exit 3
      }
      Write-Verbose "Calculated drive letter: $SourceDriveLetter"
    }
  }
  Write-Verbose "Searching for $msi_prefix in $(Get-ChildItem -Path ${SourceDriveLetter}\Installs\ServerComponents)"
  $InstallSource = (Get-ChildItem -Path "${SourceDriveLetter}\Installs\ServerComponents" -Filter "${msi_prefix}_*.msi").FullName
  if (! (Test-Path $InstallSource))
  {
    Write-Error "$Product Installation source not found in $SourceDriveLetter"
    Start-Sleep 2
    Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    exit 2
  }
  Write-Output "Installing from $InstallSource"
# 2}}}

# Prerequisites }}}

  Write-Output "Installing $Product"
  $parms  = '/i',"${InstallSource}"
  $parms += 'STARTEDBYEXEORIUPDATE=1'
  $parms += 'REBOOT=ReallySuppress'
  $parms += '/l*v'
  $parms += "$Log"
  $parms += '/qn'
  $parms += '/norestart'

  Write-Verbose "Arguments: $($parms -join ',')"

  if ($PSCmdlet.ShouldProcess($Product, "Running msiexec /install"))
  {
    $watch   = [Diagnostics.StopWatch]::StartNew()
    $process = Start-Process -FilePath msiexec -ArgumentList $parms -Wait -PassThru
    $watch.Stop()
    $elapsed = Show-Elapsed($watch)
    if ($process.ExitCode -eq 0)
    {
      Write-Output "$Product installed successfully in $elapsed!"
      $exit_code = 0
    }
    elseif ($process.ExitCode -eq 3010)
    {
      Write-Output "$Product installed successfully in $elapsed!"
      $exit_code = 0
      if ($Reboot)
      {
        Write-Output "Restarting..."
        Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Restart-Computer
        Start-Sleep 30
      }
      else
      {
        Write-Warning "Rebooting is needed before using $Product"
      }
    }
    else
    {
      Write-Error "Failure: Error= $($process.ExitCode), Logs=$Log, Execution time=$elapsed"
      $exit_code = $process.ExitCode
    }
  }
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  Start-Sleep 2
  exit $exit_code
}
