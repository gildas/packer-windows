setlocal EnableDelayedExpansion EnableExtensions
title Configuring Powershell Execution Policy...

cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force" <NUL
@if errorlevel 1 echo "ERROR %ERRORLEVEL% while setting execution policy for powershell"
if exist %SystemRoot%\SysWOW64\cmd.exe (
  %SystemRoot%\SysWOW64\cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force" <NUL
  @if errorlevel 1 echo "ERROR %ERRORLEVEL% while setting execution policy for powershell 64 bits"
)

