require 'rake'
#require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

template_dir     = 'templates'
os_version       = $1
os_install       = $2 || 'core'            # validate(os_install, [ 'core', 'full' ])
os_edition       = $3 || 'standard'        # validate(os_edition, [ 'standard', 'datacenter', '...' ])
os_license       = $4 || 'eval'            # validate(os_license [ 'retail', 'msdn', 'eval', 'volume' ])
provisioner      = 'vmware'
vagrant_box      = "#{template}-#{provisioner}"
vagrant_provider = case provisioner
                     when 'vmware' then 'vmware_fusion'
                     when 'virtualbox' then 'virtualbox'
                     else raise ArgumentError, provisioner
                   end

def has_virtualbox?
  !%x(which VBoxManage).empty?
end

def has_vmware?
  File.exists? '/Applications/VMware Fusion.app/Contents/Library/vmrun'
end

desc "Builds a packer template"
task :build, [:os, :os_version, :os_install, :os_edition, :os_license, :provisioners] do |_task, _args|
  _args.with_defaults(os: 'windows', os_version: '2012R2', os_install: 'core', os_edition: 'standard', os_license: 'eval', provisioners: [])
  if _args[:provisioners].nil? || _args[:provisioners].empty?
    _args[:provisioners] = []
    _args[:provisioners] << 'virtualbox_iso' if has_virtualbox?
    _args[:provisioners] << 'vmware_iso'     if has_vmware?
  end
  template = "_args[:os]-#{_args[:os_version]}-#{_args[:os_install]}-#{_args[:os_edition]}"
  %x(packer build -only=#{_args[:provisioners].join(',')} #{template_dir}/#{template}/packer.json)
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
