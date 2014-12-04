@if not defined PACKER_DEBUG (@echo off) else (@echo on)
setlocal EnableDelayedExpansion EnableExtensions
title Installing Virtualbox Guest Additions...

set DRIVE_LETTERS=C: D: E: F: G: H: I: J: K: L: M: N: O: P: Q: R: S: T: U: V: W: X: Y: Z:

echo "%PACKER_BUILDER_TYPE%" | findstr /I "vmware" > NUL
if not ERRORLEVEL 1 goto VMWare
echo "%PACKER_BUILDER_TYPE%" | findstr /I "virtualbox" > NUL
if not ERRORLEVEL 1 goto Virtualbox

echo ERROR Unknown Packer builder type: %PACKER_BUILDER_TYPE%
exit 1

:Virtualbox
echo ==^> Installing Virtualbox Guest Additions
for %%i in (%DRIVE_LETTERS%) do if exist "%%~i\VBoxWindowsAdditions.exe" set GUEST_DRIVE=%%~i
if "x%GUEST_DRIVE%" == "x" (
  echo ERROR: Cannot find Virtualbox additions
  exit 1
)
cmd /c certutil -addstore -f "TrustedPublisher" %GUEST_DRIVE%\cert\oracle-vbox.cer
@if errorlevel 1 echo ERROR %ERRORLEVEL% while adding Oracle certificate to the trusted publishers
cmd /c %GUEST_DRIVE%\VBoxWindowsAdditions.exe /S
@if errorlevel 1 echo ERROR %ERRORLEVEL% while installing Virtualbox Guest Additions
goto :end

:VMWare
echo ==^> Installing VMWare Guest Additions
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "Mount-DiskImage C:\Users\vagrant\windows.iso"
@if errorlevel 1 echo ERROR %ERRORLEVEL% while mounting the VMWare Guest Additions ISO
for %%i in (%DRIVE_LETTERS%) do if exist "%%~i\vmware\setup.exe" set GUEST_DRIVE=%%~i
if "x%GUEST_DRIVE%" == "x" (
  echo ERROR: Cannot find VMWare additions
  exit 1
)
cmd /c %GUEST_DRIVE%\vmware\setup.exe /S /v "/qn REBOOT=R ADDLOCAL=ALL"
@if errorlevel 1 echo ERROR %ERRORLEVEL% while installing VMWare Guest Additions
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "Dismount-DiskImage C:\Users\vagrant\windows.iso"
@if errorlevel 1 echo ERROR %ERRORLEVEL% while unmounting the VMWare Guest Additions ISO
goto :end

:end
exit 0
