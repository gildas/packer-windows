require 'serverspec'
require 'winrm'

include Serverspec::Helpers::Windows
include Serverspec::Helpers::WinRM

RSpec.configure do |config|
  config.before :suite do
    config.winrm = ::WinRM::WinRMWebService.new(endpoint, :plaintext, user: 'Administrator', pass: 'vagrant', disable_sspi: true)
    config.winrm.set_timeout 300
  end
end
