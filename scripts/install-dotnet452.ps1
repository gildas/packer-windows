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

  Write-Output "Checking if .Net 4.5.2 or more is installed"
  $dotnet_info = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction SilentlyContinue
  if ($dotnet_info -eq $null -or $dotnet_info.Release -lt 379893)
  {
    if (Test-Path $env:USERPROFILE/mounted.info)
    {
      $SourceDriveLetter = Get-Content $env:USERPROFILE/mounted.info
      Write-Verbose "Got drive letter from a previous mount: $SourceDriveLetter"
      if (Test-Path "${SourceDriveLetter}\ThirdPartyInstalls\Microsoft\DotNET4.5.2\dotNetFx452_Full_x86_x64.exe")
      {
        Write-Output "Installing .Net 4.5.2 from the ISO ($SourceDriveLetter)"
        & ${SourceDriveLetter}ThirdPartyInstalls\Microsoft\DotNET4.5.2\dotNetFx452_Full_x86_x64.exe /Passive /norestart /Log C:\Windows\Logs\dotnet-4.5.2.log.txt
        Start-Sleep 60
        Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Start-Sleep 5
       exit
      }
    }
    $install='NDP452-KB2901907-x86-x64-AllOS-ENU.exe'
    $source_url="https://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/$install"
    $dest=Join-Path $env:TEMP $install

    Write-Output "Downloading .Net 4.5.2"
    #Start-BitsTransfer -Source $source_url -Destination $dest -ErrorAction Stop
    (New-Object System.Net.WebClient).DownloadFile($source_url, $dest)


    Write-Output "Installing .Net 4.5.2"
    & ${env:TEMP}\NDP452-KB2901907-x86-x64-AllOS-ENU.exe /Passive /norestart /Log C:\Windows\Logs\dotnet-4.5.2.log.txt
    Start-Sleep 60
  }
}
end
{
  Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
  Start-Sleep 5
  exit $LastExitCode
}
