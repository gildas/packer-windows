require 'serverspec'
require 'winrm'

set :backend, :winrm
set :os, family: 'windows'

winrm = ::WinRM::WinRMWebService.new('http://localhost:5985/wsman', :ssl, user: 'vagrant', pass: 'vagrant', basic_auth_only: true)
winrm.set_timeout 300
Specinfra.configuration.winrm = winrm
