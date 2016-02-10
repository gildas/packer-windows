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
    if (Get-Hotfix -id 2966828 -ErrorAction SilentlyContinue)
    {
      Write-Output "KB 2966828 was installed, we need to uninstall it"

      $install='NDPFixit-KB3005628-X64.exe'
      $source_url="http://download.microsoft.com/download/8/0/8/80894270-D665-4E7A-8A2C-814373FC25C1/$install"
      $dest=Join-Path $env:TEMP $install

      Write-Output "Downloading KB 3005628"
      #Start-BitsTransfer -Source $source_url -Destination $dest -ErrorAction Stop
      (New-Object System.Net.WebClient).DownloadFile($source_url, $dest)

      #& ${env:TEMP}\NDPFixit-KB3005628-X64.exe /Log C:\Windows\Logs\KB-3005628.log
      & ${env:TEMP}\NDPFixit-KB3005628-X64.exe
    }
    Write-Output "Installing .Net 3.5"
    $watch   = [Diagnostics.StopWatch]::StartNew()
    if ($PSCmdlet.ShouldProcess('.Net 3.5', "Running msiexec /install"))
    {
      $parms  = @{}
      $dvd_drives = Get-WmiObject Win32_LogicalDisk -Filter 'DriveType=5' | Select -ExpandProperty DeviceID
      foreach ($_ in $dvd_drives)
      {
        $sources = (Join-Path $_ (Join-Path 'sources' 'sxs'))
        if (Test-Path $sources)
        {
          $parms['Source'] = $sources
          Write-Output "Using $sources to install .Net"
          break
        }
      }

      $results = Install-WindowsFeature -Name Net-Framework-Core -LogPath C:\Windows\Logs\dotnet-3.5.log @parms -Verbose
      if (! $results.Success)
      {
        Write-Error "Failure while installing .Net 3.5, exit code: $($results.ExitCode)"
        Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Start-Sleep 10
        exit 1
      }
    }
    $watch.Stop()
    $elapsed = Show-Elapsed($watch)
    Write-Output ".Net 3.5 installed successfully in $elapsed!"
    Write-Output $results.FeatureResult
    switch($results.RestartNeeded)
    {
      [Microsoft.Windows.ServerManager.Commands.RestartState]::Yes
      {
        Write-Warning "The system will need to be restarted to be able to use the new features"
      }
      [Microsoft.Windows.ServerManager.Commands.RestartState]::Maybe
      {
        Write-Warning "The system might need to be restarted to be able to use the new features"
      }
      [Microsoft.Windows.ServerManager.Commands.RestartState]::No
      {
        Write-Output "The system does not need to be restarted to be able to use the new features"
      }
    }
  }
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  Start-Sleep 5
  exit 0
}
