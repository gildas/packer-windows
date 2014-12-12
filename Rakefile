require 'rake'
require 'json'
require 'erb'
require 'ostruct'
require 'digest/sha1'
require 'rake/clean'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

templates_dir = 'templates'
boxes_dir     = 'boxes'
temp_dir      = 'tmp'

builders = {
  virtualbox: { name: 'virtualbox', folder: 'virtualbox', vagrant_type: 'virtualbox', packer_type: 'virtualbox-iso', supported: lambda { ! %x(which VBoxManage).empty? } },
  vmware:     { name: 'vmware',     folder: 'vmware',     vagrant_type: 'vmware',     packer_type: 'vmware-iso',     supported: lambda { File.exists? '/Applications/VMware Fusion.app/Contents/Library/vmrun' } },
}

TEMPLATE_FILES = Rake::FileList.new("#{templates_dir}/**/packer.json")

directory boxes_dir
directory temp_dir

def load_json(filename)
  return {} unless File.exist? filename
  return File.open(filename) { |file| JSON.parse(file.read) }
end

def source_for_box(box_file)
  # box_file should be like: boxes/#{box_name}/#{provider}/#{box_name}-#{box_version}.box
  box_name = File.basename(File.dirname(box_file.pathmap("%d")))
  box_source = TEMPLATE_FILES.detect do |template_source|
    template_name = File.basename(File.dirname(template_source))
    box_name == template_name
  end
  raise Errno::ENOENT, "no source for #{box_file}" if box_source.nil?
  box_source
end

rule '.box' => [->(box) { source_for_box(box) }, boxes_dir] do |_rule|
  builder = builders[File.basename(_rule.name.pathmap("%d")).to_sym]
  mkdir_p _rule.name.pathmap("%d")
  puts "Building #{_rule.name.pathmap("%f")} using #{builder[:name]}"
  sh "packer build -only=#{builder[:packer_type]} -var-file=#{_rule.source.pathmap("%d")}/config.json #{_rule.source}"
end

class Binder
  def initialize(config = {})
    self.class.class_eval { config.each {|key, value| define_method(key.to_sym){value}}}
  end
  def get_binding ; binding() end
end

rule 'metadata.json' => ["#{templates_dir}/metadata.json.erb"] do |_rule|
  template = File.basename(_rule.name.pathmap("%d"))
  puts "Generating metadata.json for template #{template}"
  current_dir = %x(pwd).split.first
  providers   = _rule.prerequisites.reject {|p| p == _rule.source}.collect do |p|
    provider      = File.basename(p.pathmap("%d"))
    url           = "file://#{current_dir}/#{p}"
    checksum_type = 'sha1'
    print "  Calculating SHA1 checksum for provider #{provider}..."
    checksum      = Digest::SHA1.file(p).hexdigest
    puts '.'
    OpenStruct.new name: provider, url: url, checksum: checksum, checksum_type: checksum_type
  end
  config = load_json("#{templates_dir}/#{template}/config.json")
  binds  = Binder.new(config.merge(providers: providers))

  renderer = File.open(_rule.source) { |file| ERB.new(file.read, 0, '-') }
  File.open(_rule.name, 'w') { |output| output.puts renderer.result(binds.get_binding) }
end

current_dir = %x(pwd).split.first
builders.each do |builder_name, builder|
  if builder[:supported][]
    TEMPLATE_FILES.each do |template_file|
      config        = load_json(template_file.pathmap("%d/config.json"))
      version       = config['version'] || '0.1.0'
      box_name      = template_file.pathmap("%{templates/,}d")
      box_file      = "#{boxes_dir}/#{box_name}/#{builder[:folder]}/#{box_name}-#{version}.box"
      box_url       = "file://#{current_dir}/#{box_file}"
      metadata_file = "#{boxes_dir}/#{box_name}/metadata.json"

      file metadata_file => box_file

      namespace :build do
        namespace builder_name.to_sym do
          desc "Build box #{box_name} version #{version} with #{builder_name}"
          task box_name => box_file

          desc "Build all boxes for #{builder_name}"
          task :all => box_name
        end

        desc "Build all boxes for all providers"
        task :all => "#{builder_name}:all"
      end

      namespace :metadata do
        desc "Generate the metadata for box #{box_name}"
        task box_name => [metadata_file, "build:#{builder_name}:#{box_name}"]

        desc "Generate the metadata for all boxes"
        task :all => box_name
      end

      namespace :load do
        namespace builder_name.to_sym do
          desc "Load box #{box_name} version #{version} in vagrant for #{builder_name}"
          task box_name => ["build:#{builder_name}:#{box_name}", "metadata:#{box_name}"] do
            sh "vagrant box add --force #{box_name} #{box_file}"
          end

          desc "Load all boxes in vagrant for #{builder_name}"
          task :all => box_name
        end

        desc "Load all boxes in vagrant"
        task :all => "#{builder_name}:all"
      end

      namespace :up do
        namespace builder_name.to_sym do
          desc "Start a Virtual Machine after the box #{box_name} in #{builder_name}"
          task box_name => "load:#{builder_name}:#{box_name}" do
            sh "cd spec ; BOX=\"#{box_name}\" BOX_URL=\"#{box_url}\" vagrant up --provider=#{builder[:vagrant_type]} --provision"
          end
        end
      end

      namespace :halt do
        namespace builder_name.to_sym do
          desc "Stop the Virtual Machine from the box #{box_name} in #{builder_name}"
          task box_name do
            sh "cd spec ; BOX=\"#{box_name}\" BOX_URL=\"#{box_url}\" vagrant halt"
          end

          desc "Stop all boxes in #{builder_name}"
          task :all => box_name
        end

        desc "Stop all boxes in all providers"
        task :all => "#{builder_name}:all"
      end

      namespace :destroy do
        namespace builder_name.to_sym do
          desc "Destroy the Virtual Machine from the box #{box_name} from #{builder_name}"
          task box_name do
            sh "cd spec ; BOX=\"#{box_name}\" BOX_URL=\"#{box_url}\" vagrant destroy -f"
          end

          desc "Destroy all Virtual Machines from all boxes from #{builder_name}"
          task :all => box_name
        end

        desc "Destroy all Virtual Machines from all boxes from all providers"
        task :all => "#{builder_name}:all"
      end

      namespace :remove do
        namespace builder_name.to_sym do
          desc "Remove box #{box_name} from #{builder_name}"
          task box_name => "destroy:#{builder_name}:#{box_name}" do
            sh "vagrant box remove -f #{box_name}"
          end

          desc "Remove all boxes from #{builder_name}"
          task :all => box_name
        end

        desc "Remove all boxes from all providers"
        task :all => "#{builder_name}:all"
      end

      CLOBBER << box_file
      CLOBBER << metadata_file
    end
  end
end

task :default => ['build:all', 'metadata:all']
