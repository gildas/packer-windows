setlocal EnableDelayedExpansion EnableExtensions
title Installing Chocolatey...

@powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))"
