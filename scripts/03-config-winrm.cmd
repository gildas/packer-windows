@if not defined PACKER_DEBUG (@echo off) else (@echo on)
setlocal EnableDelayedExpansion EnableExtensions
title Configuring Windows Remote Management...

cmd /c net stop winrm
cmd /c winrm quickconfig -q
cmd /c winrm quickconfig -transport:http
cmd /c winrm set winrm/config @{MaxTimeoutms="1800000"}
cmd /c winrm set winrm/config/winrs @{MaxMemoryPerShellMB="2048"}
cmd /c winrm set winrm/config/service @{AllowUnencrypted="true"}
cmd /c winrm set winrm/config/service/auth @{Basic="true"}
cmd /c winrm set winrm/config/listener?Address=*+Transport=HTTP @{Port="5985"}
cmd /c sc config winrm start= auto
cmd /c net start winrm

cmd /c netsh firewall set service type=remoteadmin mode=enable
cmd /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
cmd /c netsh advfirewall firewall add rule name="Port 5985" dir=in action=allow protocol=TCP localport=5985
