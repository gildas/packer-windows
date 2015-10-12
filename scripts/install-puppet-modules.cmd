cmd /c certutil -addstore  "Root" C:\Windows\Temp\GeoTrust_Global_CA.pem
cmd /c del C:\Windows\Temp\GeoTrust_Global_CA.pem
puppet.bat module install puppetlabs-windows
puppet.bat module install puppetlabs-dism
puppet.bat module install puppetlabs-inifile
puppet.bat module install gildas-firewall
