@if not defined PACKER_DEBUG (@echo off) else (@echo on)
setlocal EnableDelayedExpansion EnableExtensions
title Installing imdisk...

set IMDISK_URL=http://www.ltr-data.se/files/imdiskinst.exe

:: strip off quotes
for %%i in (%IMDISK_URL%) do set IMDISK_EXE=%%~nxi
for %%i in (%IMDISK_URL%) do set IMDISK_URL=%%~i

set IMDISK_DIR=%TEMP%\imdisk
set IMDISK_PATH=%IMDISK_DIR%\%IMDISK_EXE%

echo ==^> Creating "%IMDISK_DIR%"
mkdir "%IMDISK_DIR%"
pushd "%IMDISK_DIR%"

if exist "%SystemRoot%\_download.cmd" (
  call "%SystemRoot%\_download.cmd" "%IMDISK_URL%" "%IMDISK_PATH%"
) else (
  echo ==^> Downloading "%IMDISK_URL%" to "%IMDISK_PATH%"
  powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%IMDISK_URL%', '%IMDISK_PATH%')" <NUL
)
if not exist "%IMDISK_PATH%" goto exit1

echo ==^> Installing ImDisk
SET IMDISK_SILENT_SETUP=1
"%IMDISK_PATH%" -y

:: wait for imdisk service to finish starting
timeout 2
