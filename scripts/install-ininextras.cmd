@if not defined PACKER_DEBUG (@echo off) else (@echo on)
setlocal EnableDelayedExpansion EnableExtensions
title Installing Interactive Intelligence Extra...

mkdir "C:\Program Files (x86)\Interactive Intelligence\GetHostID"

@powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null ; [System.IO.Compression.ZipFile]::ExtractToDirectory('C:\Windows\Temp\inin-extras.zip', 'C:\Program Files (x86)\Interactive Intelligence\GetHostID')"
@if errorlevel 1 (
  echo ERROR %ERRORLEVEL% Error while uncompressing
  exit 1
)

del /F C:\Windows\Temp\inin-extras.zip
exit 0
