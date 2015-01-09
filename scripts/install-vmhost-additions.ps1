<#
#>

if ($env:PACKER_BUILDER_TYPE -match 'vmware')
{
  $iso_path="C:\Users\vagrant\windows.iso"
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
    Write-Host "Installing VMWare Guest Additions"
    Start-Process ${drive}:\setup.exe -ArgumentList '/S','/v','"/qn /norestart /l*v C:\Windows\Logs\vmware-tools.log REBOOT=ReallySuppress ADDLOCAL=ALL"' -Wait
    if (! $?)
    {
      Write-Error "ERROR $LastExitCode while installing VMWare Guest Additions"
      Start-Sleep 10
      exit 2
    }
#    Write-Host "Restarting Virtual Machine"
#    Restart-Computer
#    Start-Sleep 30
  }
  else
  {
    Write-Host "ISO was not loaded [$iso_path], nothing will happen"
  }
}
elseif ($env:PACKER_BUILDER_TYPE -match 'virtualbox')
{
  $iso_path="C:\Users\vagrant\VBoxGuestAdditions.iso"
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
    # cd ${drive}:\cert ; VBoxCertUtil add-trusted-publisher oracle-vbox.cer --root oracle-vbox.cer
    certutil -addstore -f "TrustedPublisher" ${drive}:\cert\oracle-vbox.cer
    if (! $?)
    {
      Write-Error "ERROR $LastExitCode while adding Oracle certificate to the trusted publishers"
      Start-Sleep 10
      exit 2
    }
    Write-Host "Installing Virtualbox Guest Additions"
    Start-Process ${drive}:\VBoxWindowsAdditions.exe -ArgumentList '/S' -Wait
    if (! $?)
    {
      Write-Error "ERROR $LastExitCode while installing Virtualbox Guest Additions"
      Start-Sleep 10
      exit 2
    }
    Write-Host "Dismounting ISO"
    Dismount-DiskImage -ImagePath $image.ImagePath
#    Write-Host "Restarting Virtual Machine"
#    Restart-Computer
#    Start-Sleep 30
  }
  else
  {
    Write-Host "ISO was not loaded [$iso_path], nothing will happen"
  }
}
else
{
  Write-Error "Unsupported Packer builder: $env:PACKER_BUILDER_TYPE"
  exit 1
}
