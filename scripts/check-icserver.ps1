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

$Product = 'Interaction Center Server'
if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
{
  Write-Host "$Product is installed"
}
else
{
  # The script can run roughly 6 minutes before the winrm/ssh link with packer goes stale,
  # And we pause for 10 seconds in each iteration
  $sleep = 10
  $max   = 60 * 5 / $sleep
  $iter  = 0

  while ($iter -lt $max)
  {
    if (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object DisplayName -match "${Product}.*")
    {
      Write-Host "$Product is installed"
      return
    }
    Write-Host "  #${iter}/${max} Installation is still running [$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]"
    Start-Sleep $sleep
    $iter += 1
  }
  #TODO: Should we return values or raise exceptions?
  Write-Error "Failed to install $Product"
  return -2
}
Write-Verbose "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
