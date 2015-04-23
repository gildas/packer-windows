@if not defined PACKER_DEBUG (@echo off) else (@echo on)
setlocal EnableDelayedExpansion EnableExtensions
title Configuring Windows...

%SystemRoot%\System32\reg.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\Power\ /v HibernateFileSizePercent /t REG_DWORD /d 0 /f
%SystemRoot%\System32\reg.exe ADD HKLM\SYSTEM\CurrentControlSet\Control\Power\ /v HibernateEnabled /t REG_DWORD /d 0 /f

title Configuring User Accounts...
cmd.exe /c wmic useraccount where "name='packer'"  set PasswordExpires=FALSE
cmd.exe /c wmic useraccount where "name='vagrant'" set PasswordExpires=FALSE
