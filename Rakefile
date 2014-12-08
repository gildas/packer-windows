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

def source_for_box(box_file)
  TEMPLATE_FILES.detect do |template_source|
    template_name = File.basename(File.dirname(template_source))
    File.basename(box_file) =~ /^#{template_name}-\d+\.\d+\.\d+\.box/
  end
end

rule '.box' => [->(box) { source_for_box(box) }, boxes_dir] do |_rule|
  builder = builders[File.basename(_rule.name.pathmap("%d")).to_sym]
  mkdir_p _rule.name.pathmap("%d")
  puts "Building #{_rule.name} from #{_rule.source} using #{builder[:name]}"
  puts " build_metadata(template: \"#{_rule.source.pathmap("%d")}/metadata.json\", builder: _args[:builder])"
  puts " Command line: packer build -only=#{builder[:packer_type]} -var-file=#{_rule.source.pathmap("%d")}}/config.json #{_rule.source}"
#  sh "packer build -only=#{builder[:packer_type]} -var-file=#{_rule.source.pathmap("%d")}}/config.json #{_rule.source}"
end

builders.each do |builder_name, builder|
  if builder[:supported][]
    TEMPLATE_FILES.each do |template_file|
      config   = load_json(template_file.pathmap("%d/config.json"))
      version  = config['version'] || '0.1.0'
      box_name = template_file.pathmap("%{templates/,}d")
      box_file = "#{boxes_dir}/#{builder[:folder]}/#{box_name}-#{version}.box"

      namespace :build do
        desc "Build box #{box_name} version #{version}"
        task box_name => box_file
      end

      desc "Build all templates"
      task :build_all => "build:#{box_name}"

      namespace :load do
        desc "Load box #{box_name} version #{version} in vagrant"
        task box_name => "build:#{box_name}" do
          puts "vagrant box add --force --name #{box_name} #{box_file}"
        end
      end

      desc "Load all boxes in vagrant"
      task :load_all => "load:#{box_name}"
    end
  end
end

desc "Start a packer template"
task :start do
  %x(BOX="#{vagrant_box} TEMPLATE="#{template} vagrant up --provider=#{provider} --provision)
end

desc "Stop a packer template"
task :stop do
  %x(BOX="#{vagrant_box} TEMPLATE="#{template} vagrant halt --provider=#{provider})
end

desc "Delete a packer template"
task :delete do
  %x(BOX="#{vagrant_box} TEMPLATE="#{template} vagrant destroy -f)
end

task :default => :build_all
