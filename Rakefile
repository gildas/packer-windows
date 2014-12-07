require 'rake'
#require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

template_dir     = 'templates'

def has_virtualbox?
  !%x(which VBoxManage).empty?
end

def has_vmware?
  File.exists? '/Applications/VMware Fusion.app/Contents/Library/vmrun'
end
def validate(argument, value, valid_values=[])
  raise ArgumentError, argument unless valid_values.include? value
end

desc "Builds a packer template"
task :build, [:template, :provisioners] do |_task, _args|
  _args.with_defaults(provisioners: [])
  if _args[:provisioners].nil? || _args[:provisioners].empty?
    _args[:provisioners] = []
    _args[:provisioners] << 'virtualbox_iso' if has_virtualbox?
    _args[:provisioners] << 'vmware_iso'     if has_vmware?
  end
  puts " Building #{_args[:template]} for #{_args[:provisioners].join(',')}"
  puts " Command line: packer build -only=#{_args[:provisioners].join(',')} #{template_dir}/#{_args[:template]}/packer.json"
  %x(packer build -only=#{_args[:provisioners].join(',')} #{template_dir}/#{_args[:template]}/packer.json)
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
