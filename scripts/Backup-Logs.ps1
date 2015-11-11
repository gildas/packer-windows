<#
#>


if ($env:PACKER_BUILDER_TYPE -match 'vmware')
{
  $log_dir = "\\vmware-host\Shared Folders\log"
}
elseif ($env:PACKER_BUILDER_TYPE -match 'virtualbox')
{
  $log_dir = "\\vboxsrv\log"
}
elseif ($env:PACKER_BUILDER_TYPE -match 'parallels')
{
  $log_dir = Join-Path $share_name "\\psf\log"
}
elseif ($env:PACKER_BUILDER_TYPE -match 'hyperv-iso')
{
  if ([string]::IsNullOrEmpty($env:SMBHOST))  { Write-Error "Environment variable SMBHOST is empty"  ; exit 1 }
  if ([string]::IsNullOrEmpty($env:SMBSHARE)) { Write-Error "Environment variable SMBSHARE is empty" ; exit 1 }
  if ([string]::IsNullOrEmpty($env:SMBUSER))  { Write-Error "Environment variable SMBUSER is empty"  ; exit 1 }
  if ([string]::IsNullOrEmpty($env:SMBPASS))  { Write-Error "Environment variable SMBPASS is empty"  ; exit 1 }
  $DriveLetter = ls function:[d-z]: -n | ?{ !(Test-Path $_) } | Select -Last 1
  Write-Output "Mounting $($env:SMBSHARE) from $($env:SMBHOST) on $DriveLetter as $($env:SMBUSER)"
  $Drive = New-PSDrive -Name $DriveLetter.Substring(0,1) -PSProvider FileSystem -Root \\${env:SMBHOST}\${env:SMBSHARE} -Credential (New-Object System.Management.Automation.PSCredential("${env:SMBHOST}\${env:SMBUSER}", ($env:SMBPASS | ConvertTo-SecureString -AsPlainText -Force)))
  $log_dir = $DriveLetter
}
else
{
  Write-Warning "Unknown Packer builder ${env:PACKER_BUILDER_TYPE}, ignoring"
  exit 0
}

$log_dir = Join-Path $share_name "log"

if (Test-Path "C:\ProgramData\chocolatey\logs\chocolatey.log")
{
  Copy-Item C:\ProgramData\chocolatey\logs\chocolatey.log (Join-Path $log_dir "packer-build-${env:PACKER_BUILDER_TYPE}-${env:PACKER_BUILD_NAME}-chocolatey.log")
}

if (Test-Path "C:\Windows\Logs\icserver-*.log")
{
  Copy-Item C:\Windows\Logs\icserver-*.log (Join-Path $log_dir "packer-build-${env:PACKER_BUILDER_TYPE}-${env:PACKER_BUILD_NAME}-icserver.log")
}

if (Test-Path "C:\Windows\Logs\icfirmware-*.log")
{
  Copy-Item C:\Windows\Logs\icfirmware-*.log (Join-Path $log_dir "packer-build-${env:PACKER_BUILDER_TYPE}-${env:PACKER_BUILD_NAME}-icfirmware.log")
}

Start-Sleep 5
