cmd /c certutil -addstore  "Root" C:\Windows\Temp\GeoTrust_Global_CA.pem
cmd /c del C:\Windows\Temp\GeoTrust_Global_CA.pem
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-windows
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-dism
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-inifile
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install gildas-firewall
