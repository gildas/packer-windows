require 'rake'
require 'json'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

templates_dir = 'templates'
boxes_dir     = 'box'
temp_dir      = 'tmp'

builders = {
  virtualbox: { name: 'virtualbox', folder: 'virtualbox', packer_type: 'virtualbox-iso', supported: lambda { ! %x(which VBoxManage).empty? } },
  vmware:     { name: 'vmware',     folder: 'vmware',     packer_type: 'vmware-iso',     supported: lambda { File.exists? '/Applications/VMware Fusion.app/Contents/Library/vmrun' } },
}

TEMPLATE_FILES = Rake::FileList.new("#{templates_dir}/**/packer.json")

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
directory temp_dir

builders.each do |name, builder|
  if builder[:supported][]
    directory "#{boxes_dir}/#{builder[:folder]}" => boxes_dir
  end
end

task :box_folders => [boxes_dir, "#{boxes_dir}/virtualbox", "#{boxes_dir}/vmware"]

desc "Builds a packer template"
task :build, [:template, :builder] => [temp_dir, :box_folders] do |_task, _args|
  puts " Building #{_args[:template]} for #{_args[:builder]}"
  build_metadata(template: "#{templates_dir}/#{_args[:template]}/metadata.json", builder: _args[:builder])
  puts " Command line: packer build -only=#{_args[:builder]} -var-file=#{templates_dir}/#{_args[:template]}/config.json #{templates_dir}/#{_args[:template]}/packer.json"
#  sh "packer build -only=#{_args[:builder]} -var-file=#{templates_dir}/#{_args[:template]}/config.json #{templates_dir}/#{_args[:template]}/packer.json"
end

TEMPLATE_FILES.each do |filename|
  template_dir = File.dirname(filename)
  template     = File.basename(template_dir)
  config       = load_json("#{template_dir}/config.json")
  version      = config['version'] || '0.1.0'
  
  builders.each do |name, builder|
    if builder[:supported][]
      box = "#{boxes_dir}/#{builder[:folder]}/#{template}-#{version}.box"
      file box => [ "#{boxes_dir}/#{builder[:folder]}", temp_dir, filename] do
        Rake::Task[:build].invoke(template, builder[:packer_type])
      end

      desc "Build #{builder[:name]} #{template} version #{version}" 
      task "build_#{builder[:name]}_#{template}".to_sym => box
     
      desc "Builds all templates"
      task :build_all => box
    end
  end
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
