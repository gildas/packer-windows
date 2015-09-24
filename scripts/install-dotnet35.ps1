<# # Documentation {{{
  .Synopsis
  Installs .Net 3.5
#> # }}}
[CmdletBinding(SupportsShouldProcess=$true)]
Param(
)
begin
{
  Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  $Now = Get-Date -Format 'yyyyMMddHHmmss'
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
# Prerequisites }}}

  if ((Get-WindowsFeature Net-Framework-Core -Verbose:$false).InstallState -ne 'Installed')
  {
    Write-Output "Installing .Net 3.5"
    $watch   = [Diagnostics.StopWatch]::StartNew()
    if ($PSCmdlet.ShouldProcess('.Net 3.5', "Running msiexec /install"))
    {
      Install-WindowsFeature -Name Net-Framework-Core
      if (! $?)
      {
        Write-Error "ERROR $LastExitCode while installing .Net 3.5"
        Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Start-Sleep 10
        exit $LastExitCode
      }
    }
    $watch.Stop()
    $elapsed = Show-Elapsed($watch)
    Write-Output ".Net 3.5 installed successfully in $elapsed!"
  }
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  Start-Sleep 5
}
