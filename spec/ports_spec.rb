require 'spec_helpers'

describe port(5985) do
  it { should be_listening }
end

describe port(3389) do
  it { should be_listening }
end
