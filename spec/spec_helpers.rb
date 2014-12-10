require 'serverspec'
require 'winrm'

include Serverspec::Helpers::Windows
include Serverspec::Helpers::WinRM

RSpec.configure do |config|
  config.before :suite do
    endpoint = 'http://localhost:5985/wsman'
    config.winrm = ::WinRM::WinRMWebService.new(endpoint, :plaintext, user: 'vagrant', pass: 'vagrant', disable_sspi: true)
    config.winrm.set_timeout 300
  end
end
