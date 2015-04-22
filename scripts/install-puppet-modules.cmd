cmd /c certutil -addstore  "Root" C:\Windows\Temp\GeoTrust_Global_CA.pem
cmd /c del C:\Windows\Temp\GeoTrust_Global_CA.pem
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-stdlib
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-registry
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-dism
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-acl
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-reboot
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-inifile
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install puppetlabs-powershell
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install chocolatey-chocolatey
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install gildas-sqlserver
cmd /c "C:\Program Files\Puppet Labs\Puppet\bin\puppet.bat" module install PierrickL-cicserver
