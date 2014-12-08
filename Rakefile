require 'rake'
require 'json'
#require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

templates_dir = 'templates'
boxes_dir     = 'box'
temp_dir      = 'tmp'

def has_virtualbox?
  !%x(which VBoxManage).empty?
end

def has_vmware?
  File.exists? '/Applications/VMware Fusion.app/Contents/Library/vmrun'
end

def validate(argument, value, valid_values=[])
  raise ArgumentError, argument unless valid_values.include? value
end

def load_json(filename)
  return {} unless File.exist? filename
  return File.open(filename) { |file| JSON.parse(file.read) }
end

def build_metadata(template:, builder:)
  if File.exist?(template)
    config = load_json("#{File.dirname(template)}/config.json")
    config['Provider'] = builder
    File.open("./tmp/metadata.json", "w") do |output|
      File.open(template) do |file|
        while line = file.gets do
          line.chomp!
          while (match = /{{\s*user `(?<key>[^`]+)`\s*}}/i.match(line) || /{{\s*\.(?<key>\w+)\s*}}/i.match(line)) != nil
            line.gsub!(/{{[^}]+}}/, config[match['key']])
          end
          output.puts line
        end
      end
    end
  end
end

directory boxes_dir
directory "#{boxes_dir}/virtualbox"
directory "#{boxes_dir}/vmware"
directory temp_dir

task :box_folders => [boxes_dir, "#{boxes_dir}/virtualbox", "#{boxes_dir}/vmware"]

desc "Builds a packer template"
task :build, [:template, :builder] => [temp_dir, :box_folders] do |_task, _args|
  puts " Building #{_args[:template]} for #{_args[:builder]}"
  build_metadata(template: "#{templates_dir}/#{_args[:template]}/metadata.json", builder: _args[:builder])
  puts " Command line: packer build -only=#{_args[:builder]} -var-file=#{templates_dir}/#{_args[:template]}/config.json #{templates_dir}/#{_args[:template]}/packer.json"
#  sh "packer build -only=#{_args[:builder]} -var-file=#{templates_dir}/#{_args[:template]}/config.json #{templates_dir}/#{_args[:template]}/packer.json"
end

Dir.glob("#{templates_dir}/*/packer.json") do |filename|
  template_dir = File.dirname(filename)
  template     = File.basename(template_dir)
  config       = load_json("#{template_dir}/config.json")
  version      = config['version'] || '0.1.0'
  puts "template: #{template}, folder: #{template_dir}"
  if has_virtualbox?
    file "#{boxes_dir}/virtualbox/#{template}-#{version}.box" => filename do
      Rake::Task[:build].invoke(template, 'virtualbox-iso')
    end
  end
  if has_vmware?
    file "#{boxes_dir}/vmware/#{template}-#{version}.box" => filename do
      Rake::Task[:build].invoke(template, 'vmware-iso')
    end
  end
end

desc "Builds all packer templates"
task :build_all do |_task, _args|
end

desc "Loads a packer template"
task :load do
  %x(vagrant box add --force --name #{template} #{vagrant_box})
end

desc "Starts a packer template"
task :start do
  %x(BOX="#{vagrant_box} TEMPLATE="#{template} vagrant up --provider=#{provider} --provision)
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
