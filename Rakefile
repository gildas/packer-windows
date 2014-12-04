require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

template_dir     = 'templates'
os_version       = $1
os_install       = $2 || 'core'            # validate(os_install, [ 'core', 'full' ])
os_edition       = $3 || 'standard'        # validate(os_edition, [ 'standard', 'datacenter', '...' ])
os_license       = $4 || 'eval'            # validate(os_license [ 'retail', 'msdn', 'eval', 'volume' ])
provisioner      = $2
template         = "windows-#{os_version}-#{os_install}-#{os_edition}"
vagrant_box      = "#{template}-#{provisioner}"
vagrant_provider = case provisioner
                     when 'vmware' then 'vmware_fusion'
                     when 'virtualbox' then 'virtualbox'
                     else raise ArgumentError, provisioner
                   end

desc "Builds a packer template"
task :build, [:provisioner] do
%x(packer build -only=#{provisioner}-iso #{template_dir}/#{template}/packer.json})
end

desc "Loads a packer template"
task :load do
  %x(vagrant box add --force --name #{template} #{vagrant_box})
end

desc "Starts a packer template"
task :start do
  %x(BOX="#{vagrant_box} TEMPLATE="#{template} vagrant up --provider=#{provider})
end

desc "Stops a packer template"
task :stop do
  %x(BOX="#{vagrant_box} TEMPLATE="#{template} vagrant halt --provider=#{provider})
end

desc "Starts a packer template"
task :delete do
  %x(BOX="#{vagrant_box} TEMPLATE="#{template} vagrant destroy -f)
end

desc "Runs the RSpec tests"
task :test => [:build, :load, :start, :spec, :delete]
