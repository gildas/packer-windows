setlocal EnableDelayedExpansion EnableExtensions
title Installing Virtualbox Guest Additions...

if "%PACKER_BUILDER_TYPE%" = "virtualbox-iso" goto :Virtualbox
if "%PACKER_BUILDER_TYPE%" = "vmware-iso"     goto :VMWare

echo "ERROR Unknown Packer builder type: %PACKER_BUILDER_TYPE%"
exit 1

:Virtualbox
cmd /c certutil -addstore -f "TrustedPublisher" a:\oracle-cert.cer
@if errorlevel 1 echo "ERROR %ERRORLEVEL% while adding Oracle certificate to the trusted publishers"
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "Mount-DiskImage C:\Users\vagrant\VBoxGuestAdditions.iso"
@if errorlevel 1 echo "ERROR %ERRORLEVEL% while mounting the Virtualbox Guest Additions ISO"
cmd /c E:\VBoxWindowsAdditions.exe /S
@if errorlevel 1 echo "ERROR %ERRORLEVEL% while installing Virtualbox Guest Additions"
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "Dismount-DiskImage C:\Users\vagrant\VBoxGuestAdditions.iso"
@if errorlevel 1 echo "ERROR %ERRORLEVEL% while unmounting the Virtualbox Guest Additions ISO"
goto :end

:VMWare
goto :end

:end
exit 0
