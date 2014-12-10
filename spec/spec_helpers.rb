require 'serverspec'
require 'winrm'

set :backend, :winrm

endpoint = 'http://localhost:5985/wsman'
winrm = ::WinRM::WinRMWebService.new(endpoint, user: 'vagrant', pass: 'vagrant', basic_auth_only: true)
#winrm = ::WinRM::WinRMWebService.new(endpoint, :plaintext, user: 'vagrant', pass: 'vagrant', disable_sspi: true)
winrm.set_timeout 300
Specinfra.configuration.winrm = winrm
