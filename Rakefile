require 'rake'
require 'fileutils'
require 'json'
require 'erb'
require 'ostruct'
require 'digest/sha1'
require 'rake/clean'
begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new
rescue LoadError
  puts "Warning: Test Framework not loaded."
end

templates_dir = 'templates'
boxes_dir     = 'boxes'
temp_dir      = 'tmp'

def which(f)
  if RUBY_PLATFORM == 'x64-mingw32'
    path = ENV['PATH'].split(File::PATH_SEPARATOR).find do |p|
      ['.exe', '.bat', '.cmd', '.ps1'].find do |ext|
        File.exists? File.join(p,f + ext)
      end
    end
  else
    path = ENV['PATH'].split(File::PATH_SEPARATOR).find {|p| File.exists? File.join(p,f)}
  end
  return File.join(path, f) unless path.nil?
  nil
end

def verbose(message)
  puts message if $VERBOSE
end

class Task
  def investigation
    return unless Rake.application.options.trace == true
    result = "------------------------------\n"
    result << "Investigating #{name}\n"
    result << "class: #{self.class}\n"
    result <<  "task needed: #{needed?}\n"
    result <<  "timestamp: #{timestamp}\n"
    result << "pre-requisites: \n"
    prereqs = @prerequisites.collect {|name| Task[name]}
    prereqs.sort! {|a,b| a.timestamp <=> b.timestamp}
    prereqs.each do |p|
      result << "--#{p.name} (#{p.timestamp})\n"
    end
    latest_prereq = @prerequisites.collect{|n| Task[n].timestamp}.max
    result <<  "latest-prerequisite time: #{latest_prereq}\n"
    result << "................................\n\n"
    return result
  end
end

['packer'].each do |application|
  raise RuntimeError, "Program #{application} is not accessible via the command line" unless which(application)
end

builders = {
  hyperv:
  {
    name:         'hyperv',
    folder:       'hyperv',
    vagrant_type: 'hyperv',
    packer_type:  'hyperv-iso',
    supported:    lambda { RUBY_PLATFORM == 'y64-mingw32' }
  },
  kvm:
  {
    name:         'kvm',
    folder:       'libvirt',
    vagrant_type: 'libvirt',
    packer_type:  'qemu',
    supported:    lambda { RUBY_PLATFORM == 'x86_64-linux' && which('kvm') }
  },
  parallels:
  {
    name:         'parallels',
    folder:       'parallels',
    vagrant_type: 'parallels',
    packer_type:  'parallels-windows-iso',
    supported:    lambda { RUBY_PLATFORM =~ /.*darwin.*/ && which('prlctl') }
  },
  virtualbox:
  {
    name:         'virtualbox',
    folder:       'virtualbox',
    vagrant_type: 'virtualbox',
    packer_type:  'virtualbox-windows-iso',
    supported:    lambda {
      case RUBY_PLATFORM
      when 'x64-mingw32' then ! ENV['VBOX_INSTALL_PATH'].nil?
        else which('VBoxManage')
      end
    }
  },
  vmware:
  {
    name:         'vmware',
    folder:       'vmware',
    vagrant_type: 'vmware_desktop',
    packer_type:  'vmware-windows-iso',
    supported:    lambda { which('vmrun') || File.exists?('/Applications/VMware Fusion.app/Contents/Library/vmrun') }
  },
}

# We need to make sure packer.json is the first file seen per template, so _rule.source resolves to it later on
TEMPLATE_FILES = Rake::FileList.new("#{templates_dir}/**/{packer.json}") + Rake::FileList.new("#{templates_dir}/**/{config.json,Autounattend.xml}")

directory boxes_dir
directory temp_dir
task :folders => [ boxes_dir, temp_dir ]

def load_json(filename)
  return {} unless File.exist? filename
  return File.open(filename) { |file| JSON.parse(file.read) }
end

def sources_for_box(box_file)
  # box_file should be like: boxes/#{box_name}/#{provider}/#{box_name}-#{box_version}.box
  box_name = File.basename(File.dirname(box_file.pathmap("%d")))
  box_sources = TEMPLATE_FILES.select do |template_source|
    template_name = File.basename(File.dirname(template_source))
    box_name == template_name
  end
  raise Errno::ENOENT, "no source for #{box_file}" if box_sources.empty?
  box_scripts = []
  box_sources.each do |source|
    File.readlines(source).each do |line|
      if line =~ /.*(\.\/scripts\/.*)"/ && box_scripts.include?($1)
        box_scripts << $1
      end
    end
  end
  box_sources + box_scripts
end

rule '.box' => [->(box) { sources_for_box(box) }, boxes_dir] do |_rule|
  builder = builders[File.basename(_rule.name.pathmap("%d")).to_sym]
  mkdir_p _rule.name.pathmap("%d")
  puts "Building #{_rule.name.pathmap("%f")} using #{builder[:name]}"
  FileUtils.rm_rf "output-#{builder[:packer_type]}"
  packer_log="$HOME/Downloads/packer-build-#{builder[:name]}-#{_rule.name.pathmap("%f")}.log"
  sh "echo '================================================================================' >> \"#{packer_log}\""
  sh "PACKER_LOG=1 PACKER_LOG_PATH=\"#{packer_log}\" packer build -only=#{builder[:packer_type]} -var-file=#{_rule.source.pathmap("%d")}/config.json #{_rule.source}"
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
  providers   = _rule.prerequisites.reject {|p| p == _rule.source}.collect do |p|
    provider      = File.basename(p.pathmap("%d"))
    url           = "file://#{Dir.pwd}/#{p}"
    checksum_type = 'md5'
    print "  Calculating MD5 checksum for provider #{provider}..."
    checksum      = Digest::MD5.file(p).hexdigest
    puts '.'
    OpenStruct.new name: provider, url: url, checksum: checksum, checksum_type: checksum_type
  end
  config = load_json("#{templates_dir}/#{template}/config.json")
  binds  = Binder.new(config.merge(providers: providers))

  renderer = File.open(_rule.source) { |file| ERB.new(file.read, 0, '-') }
  File.open(_rule.name, 'w') { |output| output.puts renderer.result(binds.get_binding) }
end

builders_in_use=0
builders.each do |builder_name, builder|
  if builder[:supported][]
    builders_in_use += 1
    TEMPLATE_FILES.each do |template_file|
      config        = load_json(template_file.pathmap("%d/config.json"))
      version       = config['version'] || '0.1.0'
      box_name      = template_file.pathmap("%{templates/,}d")
      box_file      = "#{boxes_dir}/#{box_name}/#{builder[:folder]}/#{box_name}-#{version}.box"
      box_url       = "file://#{Dir.pwd}/#{box_file}"
      metadata_file = "#{boxes_dir}/#{box_name}/metadata.json"

      file metadata_file => box_file

      namespace :validate do
        namespace builder_name.to_sym do
          desc "Validate template #{box_name} version #{version} with #{builder_name}"
          task box_name do
            sh "packer validate -only=#{builder[:packer_type]} -var-file=#{template_file.pathmap("%d")}/config.json #{template_file}"
          end

          desc "Validate all templates for #{builder_name}"
          task :all => box_name
        end

        desc "Validate all templates for all providers"
        task :all => "#{builder_name}:all"
      end

      namespace :build do
        namespace builder_name.to_sym do
          desc "Build box #{box_name} version #{version} with #{builder_name}"
          task box_name => [ :folders, box_file ]

          desc "Build all boxes for #{builder_name}"
          task :all => box_name
        end

        desc "Build all boxes for all providers"
        task :all => "#{builder_name}:all"
      end

      namespace :metadata do
        desc "Generate the metadata for box #{box_name}"
        task box_name => [metadata_file]

        desc "Generate the metadata for all boxes"
        task :all => box_name
      end

      namespace :load do
        namespace builder_name.to_sym do
          desc "Load box #{box_name} version #{version} in vagrant for #{builder_name}"
          box_root = "#{ENV['VAGRANT_HOME'] || (ENV['HOME'] + '/.vagrant.d')}/boxes/#{box_name}"
          vagrant_provider = builders[builder_name][:vagrant_type]
          loaded_box_marker = "#{box_root}/#{version}/#{vagrant_provider}/metadata.json"

          file loaded_box_marker => box_file do |_task|
            verbose _task.investigation

            if Dir.exist? "#{box_root}/#{version}"
              verbose "removing #{box_root}/#{version}/#{vagrant_provider}"
              FileUtils.rm_r "#{box_root}/#{version}/#{vagrant_provider}", force: true
            else
              verbose "removing #{box_root}/#{version}"
              FileUtils.mkdir_p "#{box_root}/#{version}"
            end
            verbose "adding #{box_file} as #{box_name}"
            sh "vagrant box add --force #{box_name} #{box_file}"
            # Now move the new box in the proper version folder
            verbose "moving #{box_root}/0/#{vagrant_provider} to #{box_root}/#{version}"
            FileUtils.mv   "#{box_root}/0/#{vagrant_provider}", "#{box_root}/#{version}"
            verbose "removing #{box_root}/0"
            FileUtils.rm_r "#{box_root}/0", force: true
            puts "==> box: Successfully updated box '#{box_name}' version to #{version} for '#{vagrant_provider}'"
          end

          task box_name => loaded_box_marker

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
            if File.exists?("spec/.vagrant/machines/default/#{builder[:vagrant_type]}/id")
              sh "cd spec ; BOX=\"#{box_name}\" BOX_URL=\"#{box_url}\" vagrant destroy -f"
            end
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
            sh "vagrant box remove -f --provider #{builder[:vagrant_type]} #{box_name}"
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

unless builders_in_use > 0
    STDERR.puts "Error: could not find any virtualization builder!"
end

task :default => ['build:all', 'metadata:all']
