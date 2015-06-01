# .Net 3.5 Installation
#
#

<# # Documentation {{{
  .Synopsis
  Installs .Net 3.5
#> # }}}
[CmdletBinding()] 
Param(
)
Write-Output "Script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
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

# Prerequisite: .Net 3.5 {{{2
if ((Get-WindowsFeature Net-Framework-Core -Verbose:$false).InstallState -ne 'Installed')
{
  Write-Output "Installing .Net 3.5"
  Install-WindowsFeature -Name Net-Framework-Core
  if (! $?)
  {
    Write-Error "ERROR $LastExitCode while installing .Net 3.5"
    Start-Sleep 10
    exit $LastExitCode
  }
}
# 2}}}
# Prerequisites }}}

Start-Sleep 5
Write-Output "Script ended at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
