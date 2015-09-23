<# # Documentation {{{
  .Synopsis
  Installs Extra software from Interaction Center
#> # }}}
[CmdletBinding()] 
Param(
  [Parameter(Mandatory=$false)]
  [string] $SourceDriveLetter
)
begin
{
  Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  $Now         = Get-Date -Format 'yyyyMMddHHmmss'
  $InstallPath = "${env:ProgramFiles(x86)}\Interactive Intelligence\GetHostID"
}
process
{
  function Show-Elapsed([Diagnostics.StopWatch] $watch) # {{{
  {
    $elapsed = ''
    if ($watch.Elapsed.Days    -gt 0) { $elapsed += " $($watch.Elapsed.Days) days" }
    if ($watch.Elapsed.Hours   -gt 0) { $elapsed += " $($watch.Elapsed.Hours) hours" }
    if ($watch.Elapsed.Minutes -gt 0) { $elapsed += " $($watch.Elapsed.Minutes) minutes" }
    if ($watch.Elapsed.Seconds -gt 0) { $elapsed += " $($watch.Elapsed.Seconds) seconds" }
    return $elapsed
  } # }}}

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
  if ([string]::IsNullOrEmpty($SourceDriveLetter))
  {
    if (Test-Path $env:USERPROFILE/mounted.info)
    {
      $SourceDriveLetter = Get-Content $env:USERPROFILE/mounted.info
    }
    else
    {
      $SourceDriveLetter = ls function:[d-z]: -n | ?{ Test-Path "$_\Additional_files\GetHostID" } | Select -First 1
      if ([string]::IsNullOrEmpty($SourceDriveLetter))
      {
        Write-Error "No drive containing installation was mounted"
        exit 3
      }
    }
  }
  $InstallSource = "${SourceDriveLetter}\Additional_files\GetHostID"
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

  Write-Output "Installing Interactive Intelligence Extras..."

  if (! (Test-Path $InstallPath))
  {
    New-Item -ItemType Directory -Path $InstallPath
  }

  Copy-Item "${InstallSource}\*" $InstallPath
  if (! $?)
  {
    Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Start-Sleep 2
    exit 1
  }
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  Start-Sleep 2
}

