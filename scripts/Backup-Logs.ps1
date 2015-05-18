<#
#>


if ($env:PACKER_BUILDER_TYPE -match 'vmware')
{
  $share_name = "\\vmware-host\Shared Folders"
}
elseif ($env:PACKER_BUILDER_TYPE -match 'virtualbox')
{
  $share_name = "\\vboxsrv"
}
elseif ($env:PACKER_BUILDER_TYPE -match 'parallels')
{
  $share_name = "\\psf"
}
else
{
  Write-Warning "Unknown Packer builder ${env:PACKER_BUILDER_TYPE}, ignoring"
  exit 0
}

$log_dir = Join-Path $share_name "log"

Copy-Item C:\ProgramData\chocolatey\logs\chocolatey.log (Join-Path $log_dir "packer-build-${env:PACKER_BUILDER_TYPE}-${env:PACKER_BUILD_NAME}-chocolatey.log")

if (Test-Path "C:\Windows\Logs\icserver-*.log")
{
  Copy-Item C:\Windows\Logs\icserver-*.log (Join-Path $log_dir "packer-build-${env:PACKER_BUILDER_TYPE}-${env:PACKER_BUILD_NAME}-icserver.log")
}

if (Test-Path "C:\Windows\Logs\icfirmware-*.log")
{
  Copy-Item C:\Windows\Logs\icfirmware-*.log (Join-Path $log_dir "packer-build-${env:PACKER_BUILDER_TYPE}-${env:PACKER_BUILD_NAME}-icfirmware.log")
}

Start-Sleep 5
