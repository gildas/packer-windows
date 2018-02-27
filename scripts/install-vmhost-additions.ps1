<#
#>

function Eject-Drive  # {{{
{
<# {{{2
  .SYNOPSIS
    Eject the current CD-ROM from the given Drive
  .PARAMETER DriveLetter
    The drive letter to eject.
    Mandatory, no default.
  .EXAMPLE
    Eject-Drive D
  .EXAMPLE
    Eject-Drive -DriveLetter D
#> # }}}2
  [CmdletBinding()] 
  Param(
    [Parameter(Mandatory=$true)][string] $DriveLetter
  )
  $shellapp = new-object -com Shell.Application
  $shellapp.Namespace(17).ParseName("${DriveLetter}:").InvokeVerb("Eject")
  [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shellapp)
  Remove-Variable shellapp
} # }}}

if ($env:PACKER_BUILDER_TYPE -match 'vmware')
{
  $image  = $null
  $volume = Get-Volume | where FileSystemLabel -match 'VMWare Tools'
  if ($volume)
  {
    $drive=$volume.DriveLetter
    Write-Output "Found VMWare Tools mounted on ${drive}:"
  }
  else
  {
    $iso_path = Join-Path $env:USERPROFILE "windows.iso"
    if (Test-Path $iso_path)
    {
      Write-Host "Mounting ISO $iso_path"
      $image = Mount-DiskImage $iso_path -PassThru
      if (! $?)
      {
        Write-Error "ERROR $LastExitCode while mounting VMWare Guest Additions"
        Start-Sleep 10
        exit 2
      }
      $drive = (Get-Volume -DiskImage $image).DriveLetter
      Write-Host "ISO Mounted on $drive"
    }
    else
    {
      Write-Error "Could not find the VMWare Tools CD-ROM"
      Start-Sleep 10
      exit 3
    }
  }

  Write-Host "Installing VMWare Guest Additions"
  $process = Start-Process -Wait -PassThru -FilePath ${drive}:\setup64.exe -ArgumentList '/S /v"/qn REBOOT=ReallySuppress ADDLOCAL=ALL" /l C:\Windows\Logs\vmware-tools.log'
  if ($process.ExitCode -eq 0)
  {
    Write-Host "Installation was successful"
  }
  elseif ($process.ExitCode -eq 3010)
  {
    Write-Warning "Installation was successful, Rebooting is needed"
#    Write-Host "Restarting Virtual Machine"
#    Restart-Computer
#    Start-Sleep 30
  }
  else
  {
    Write-Error "Installation failed: Error= $($process.ExitCode), Logs=C:\Windows\Logs\vmware-tools.log"
    Start-Sleep 2; exit $process.ExitCode
  }
  if ($volume)
  {
    Eject-Drive -DriveLetter $drive
  }
  elseif ($image -ne $null)
  {
    Write-Host "Dismounting ISO"
    if (! (Dismount-DiskImage -ImagePath $image.ImagePath))
    {
      Write-Error "Cannot unmount $($image.ImagePath), error: $LastExitCode"
      exit $LastExitCode
    }
  }
  Start-Sleep 2
}
elseif ($env:PACKER_BUILDER_TYPE -match 'virtualbox')
{
  $volume = Get-Volume | where FileSystemLabel -match 'VBOXADDITIONS.*'

  if (! $volume)
  {
    Write-Error "Could not find the VirtualBox Guest Additions CD-ROM"
    Start-Sleep 10
    exit 3
  }

  $drive=$volume.DriveLetter
  if (Test-Path ${drive}:\cert\oracle-vbox.cer) {
    Write-Host "Adding Oracle as a trusted publisher"
    certutil -addstore -f "TrustedPublisher" ${drive}:\cert\oracle-vbox.cer
    if (! $?)
    {
      Write-Error "ERROR $LastExitCode while adding Oracle certificate to the trusted publishers"
      Start-Sleep 10
      exit 2
    }
  }
  if (Test-Path ${drive}:\cert\VBoxCertUtil.exe) {
    Write-Host "Adding Oracle as a trusted publisher"
    pushd ${drive}:\cert
    .\VBoxCertUtil.exe add-trusted-publisher .\vbox-sha1.cer      --root vbox-sha1.cer
    .\VBoxCertUtil.exe add-trusted-publisher .\vbox-sha256.cer    --root vbox-sha256.cer
    .\VBoxCertUtil.exe add-trusted-publisher .\vbox-sha256-r3.cer --root vbox-sha256-r3.cer
    if (! $?)
    {
      Write-Error "ERROR $LastExitCode while adding Oracle certificate to the trusted publishers"
      Start-Sleep 10
      exit 2
    }
    popd
  }
  Write-Host "Installing Virtualbox Guest Additions"
  $process = Start-Process -Wait -PassThru -FilePath ${drive}:\VBoxWindowsAdditions.exe -ArgumentList '/S /l C:\Windows\Logs\virtualbox-tools.log /v"/qn REBOOT=R"'
  if ($process.ExitCode -eq 0)
  {
    Write-Host "Installation was successful"
  }
  elseif ($process.ExitCode -eq 3010)
  {
    Write-Warning "Installation was successful, Rebooting is needed"
#    Write-Host "Restarting Virtual Machine"
#    Restart-Computer
#    Start-Sleep 30
  }
  else
  {
    Write-Error "Installation failed: Error= $($process.ExitCode), Logs=C:\Windows\Logs\virtualbox-tools.log"
    Start-Sleep 900; exit $process.ExitCode
  }
  Eject-Drive -DriveLetter $drive
  Start-Sleep 2
}
elseif ($env:PACKER_BUILDER_TYPE -match 'parallels')
{
  $volume = Get-Volume | where FileSystemLabel -eq 'Parallels Tools'

  if (! $volume)
  {
    Write-Error "Could not find the Parallels Desktop Tools CD-ROM"
    Start-Sleep 10
    exit 3
  }

  $drive=$volume.DriveLetter
  Write-Host "ISO Mounted on $drive"
  Write-Host "Installing Parallels Guest Additions"
  $process = Start-Process -Wait -PassThru -FilePath ${drive}:\PTAgent.exe -ArgumentList '/install_silent'
  if ($process.ExitCode -eq 0)
  {
    Write-Host "Installation was successful"
  }
  elseif ($process.ExitCode -eq 3010)
  {
    Write-Warning "Installation was successful, Rebooting is needed"
#    Write-Host "Restarting Virtual Machine"
#    Restart-Computer
#    Start-Sleep 30
  }
  else
  {
    Write-Error "Installation failed: Error= $($process.ExitCode)"
    Start-Sleep 2; exit $process.ExitCode
  }
  Start-Sleep 2
}
elseif ($env:PACKER_BUILDER_TYPE -match 'hyperv-iso')
{
  Write-Host "No guest software to install for Hyper-V"
}
else
{
  Write-Error "Ignoring unsupported Packer builder: $env:PACKER_BUILDER_TYPE"
  exit 1
}
