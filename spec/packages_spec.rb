require 'spec_helpers'

describe package('OpenSSH for Windows (remove only)') do
  it { should be_installed }
end

describe package('Puppet (64-bit)') do
  it { should be_installed }
end
