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
    $process = Start-Process -Wait -PassThru -FilePath ${drive}:\setup64.exe -ArgumentList '/S /v"/qn REBOOT=ReallySuppress ADDLOCAL=ALL" /l C:\Windows\Logs\vmware-tools.log'
    #cmd /c "${drive}:\setup64.exe /S /v`"/qn REBOOT=ReallySuppress ADDLOCAL=ALL`" /l C:\Windows\Logs\vmware-tools.log"
    if ($process.ExitCode -eq 0)
    {
      Write-Host "Installation was successful"
      Write-Host "Dismounting ISO"
      if (! (Dismount-DiskImage -ImagePath $image.ImagePath))
      {
        Write-Error "Cannot unmount $($image.ImagePath), error: $LastExitCode"
        exit $LastExitCode
      }
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
    Start-Sleep 2
  }
  else
  {
    Write-Host "ISO was not loaded [$iso_path], nothing will happen"
  }
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
  # cd ${drive}:\cert ; VBoxCertUtil add-trusted-publisher oracle-vbox.cer --root oracle-vbox.cer
  certutil -addstore -f "TrustedPublisher" ${drive}:\cert\oracle-vbox.cer
  if (! $?)
  {
    Write-Error "ERROR $LastExitCode while adding Oracle certificate to the trusted publishers"
    Start-Sleep 10
    exit 2
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
    Write-Error "Installation failed: Error= $($process.ExitCode), Logs=C:\Windows\Logs\vmware-tools.log"
    Start-Sleep 2; exit $process.ExitCode
  }
  $discMaster = New-Object -ComObject IMAPI2.MsftDiscMaster2
  foreach ($dm in $discMaster)
  {
    $discRecorder = New-Object -ComObject IMAPI2.MsftDiscRecorder2
    $discRecorder.InitializeDiscRecorder($dm)

    Write-Host "Analyzing Media $($discRecorder.VolumePathNames)"
    foreach ($pathname in $discRecorder.VolumePathNames)
    {
      Write-Host "Analyzing pathname $pathname"
      if ($pathname -eq "${drive}:\")
      {
        Write-Host "Ejecting Media ${pathname}"
        $discRecorder.EjectMedia()
        break
      }
      Write-Host "next..."
    }
  }
  Start-Sleep 2
}
elseif ($env:PACKER_BUILDER_TYPE -match 'parallels')
{
  $volume = Get-Volume | where FileSystemLabel -eq 'Parallels Tools'

  if (! $volume)
  {
    Write-Error "Could not find the VirtualBox Guest Additions CD-ROM"
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
    Write-Error "Installation failed: Error= $($process.ExitCode), Logs=C:\Windows\Logs\vmware-tools.log"
    Start-Sleep 2; exit $process.ExitCode
  }
  Start-Sleep 2
#    Write-Host "Restarting Virtual Machine"
#    Restart-Computer
#    Start-Sleep 30
}
else
{
  Write-Error "Unsupported Packer builder: $env:PACKER_BUILDER_TYPE"
  exit 1
}
