require 'logger'
require 'rake'
require 'fileutils'
require 'json'
require 'securerandom'
require 'benchmark'
require 'etc'
require 'erb'
require 'open3'
require 'ostruct'
require 'digest/sha1'
require 'rake/clean'
begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new
rescue LoadError
  #puts "Warning: Test Framework not loaded."
end


# An IO class to send logs to nowhere
class NullIO # {{{
  def write(*args) ; end
  def close        ; end
end # }}}

$logger = Logger.new(NullIO.new)

templates_dir  = 'templates'
boxes_dir      = 'boxes'
scripts_dir    = 'scripts'
log_dir        = 'log'
temp_dir       = 'tmp'
cache_dir      = ENV['DAAS_CACHE'] || case RUBY_PLATFORM
  when 'x64-mingw32' then File.join(ENV['PROGRAMDATA'], 'DaaS', 'cache')
  else File.join('/var', 'cache', 'daas')
end
cache_dir = cache_dir.gsub(/\\/, '/')
TEMPLATE_FILES = Rake::FileList.new("#{templates_dir}/**/{packer.json}")

$box_aliases = {
  'windows-10-enterprise-eval'        => [ 'windows-10' ],
  'windows-8.1-enterprise-eval'       => [ 'windows-8.1' ],
  'windows-2012R2-core-standard-eval' => [ 'windows-2012R2-core' ],
  'windows-2012R2-full-standard-eval' => [ 'windows-2012R2-full', 'windows-2012R2' ],
}

# Tools {{{
def verbose(message) # {{{
  puts message if $VERBOSE
end # }}}

def which(f) # {{{
  if RUBY_PLATFORM == 'x64-mingw32'
    path = ENV['PATH'].split(File::PATH_SEPARATOR).find do |p|
      ['.exe', '.bat', '.cmd', '.ps1'].find do |ext|
        File.exists? File.join(p,f + ext)
      end
    end
  else
    path = ENV['PATH'].split(File::PATH_SEPARATOR).find { |p| File.exist?(File.join(p,f)) }
  end
  return File.join(path, f) unless path.nil?
  nil
end # }}}

def shell(command) # {{{
  case RUBY_PLATFORM
    when 'x64-mingw32'
      stdin, stdout, stderr = Open3.popen3 "powershell.exe -NoLogo -ExecutionPolicy Bypass -Command \" #{command} \"" 
      stdin.close
      output=stdout.readlines.join.chomp
      error=stderr.readlines.join.chomp
      raise error unless error.empty?
      return output
    else
      system command
  end
end # }}}

def load_json(filename) # {{{
  return {} unless File.exist? filename
  return File.open(filename) { |file| JSON.parse(file.read) }
end # }}}

class Task # {{{
  def investigation # {{{
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
  end # }}}
end # }}}

class Binder # {{{
  def initialize(config = {}) # {{{
    self.class.class_eval { config.each {|key, value| define_method(key.to_sym){ value } } }
  end # }}}
  def get_binding ; binding() end
end # }}}

def sources_for_box(box_file, sources_root, scripts_root) # {{{
  # box_file should be like: boxes/#{box_name}/#{provider}/#{box_name}-#{box_version}.box
  verbose "box file: #{box_file}"
  box_name = box_file.pathmap("%2d").pathmap("%f")
  verbose "  Finding sources for box: #{box_name}"
  box_sources = Rake::FileList.new("#{sources_root}/#{box_name}/*")
  verbose "  ==> Box sources: #{box_sources.join(', ')}"
  raise Errno::ENOENT, "no source for #{box_file}" if box_sources.empty?
  current_builder = $builders.find { |builder| builder[1][:folder] == box_file.pathmap("%3d").pathmap("%f") }
  raise ArgumentError, box_name if current_builder.nil?
  current_builder = current_builder[1]
  verbose "  Collecting scripts for #{current_builder[:name]}"
  box_scripts = []
  box_sources.each do |source|
    next unless source =~ /.*packer\.json$/
    verbose "Checking config file: #{source}"
    config = load_json(source)
    config['builders'].each do |packer_builder|
      next unless packer_builder['type'] == current_builder[:packer_type]
      box_scripts += packer_builder['floppy_files'].find_all {|path| ['.cmd', '.ps1'].include? path.pathmap("%x") }
    end
    config['provisioners'].each do |provisioner|
      # TODO: support 'only', and 'except' from the JSON data
      case provisioner['type']
        when 'file'          then box_scripts << provisioner['source']
        when 'powershell', 'windows-shell', 'shell'
          box_scripts << provisioner['script'] if provisioner['script']
          box_scripts += provisioner['scripts'] if provisioner['scripts']
      end
    end
  end
  verbose "  Box scripts: #{box_scripts.join(', ')}"
  # TODO: What about the data folder?

  box_sources + box_scripts
end # }}}
# }}}

['packer'].each do |application|
  raise RuntimeError, "Program #{application} is not accessible via the command line" unless which(application)
end

$builders = builders = { # {{{
  hyperv: # {{{
  {
    name:           'hyperv',
    folder:         'hyperv',
    vagrant_type:   'hyperv',
    packer_type:    'hyperv-iso',
    supported:      lambda {
      case RUBY_PLATFORM
        when 'x64-mingw32'
          shell("(Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).State") == "Enabled"
        else false
      end
    },
    preclean:       lambda { |box_name|  },
    share_user:     'packer',
    share_password: SecureRandom.urlsafe_base64(9)
  }, # }}}
  qemu: # {{{
  {
    name:         'qemu',
    folder:       'qemu',
    vagrant_type: 'libvirt',
    packer_type:  'qemu',
    supported:    lambda { RUBY_PLATFORM == 'x86_64-linux' && which('kvm') },
    preclean:     lambda { |box_name|  }
  }, # }}}
  parallels: # {{{
  {
    name:         'parallels',
    folder:       'parallels',
    vagrant_type: 'parallels',
    packer_type:  'parallels-iso',
    supported:    lambda { RUBY_PLATFORM =~ /.*darwin.*/ && which('prlctl') },
    preclean:     lambda { |box_name|
      puts "Cleaning #{box_name}"
      stdin, stdout, stderr = Open3.popen3 "prlctl list --info --json \"packer-#{box_name}\""
      status = $?
      errors = stderr.readlines
      if errors.nil?
        puts "  Deleting Virtual Machine in Virtualbox"
        stdin, stdout, stderr = Open3.popen3 "prlctl unregister \"packer-#{box_name}\""
        status = $?
        errors = stderr.readlines
        STDERR.puts "Errors while deleting the Virtual Machine: #{errors}" unless errors.nil?
      end

      stdin, stdout, stderr = Open3.popen3 "prlsrvctl user list"
      while line = stdout.gets
        next unless line =~ /^#{Etc.getlogin}/
        vm_dir = File.join(line.chomp.split.last, "packer-#{box_name}")
        break
      end
      if Dir.exist? vm_dir
        puts "  Deleting Virtual Machine folder"
        FileUtils.rm_rf vm_dir
      end
    }
  }, # }}}
  virtualbox: # {{{
  {
    name:         'virtualbox',
    folder:       'virtualbox',
    vagrant_type: 'virtualbox',
    packer_type:  'virtualbox-iso',
    supported:    lambda {
      case RUBY_PLATFORM
        when 'x64-mingw32'
          ENV['VBOX_MSI_INSTALL_PATH'] && File.exist?(File.join(ENV['VBOX_MSI_INSTALL_PATH'], 'VBoxManage.exe'))
        else which('VBoxManage')
      end
    },
    preclean:     lambda { |box_name|
      puts "Cleaning #{box_name}"
      case RUBY_PLATFORM
        when 'x64-mingw32'
          VBOXMGR=File.join(ENV['VBOX_MSI_INSTALL_PATH'], 'VBoxManage.exe')
        else
          VBOXMGR='VBoxManage'
      end
      stdin, stdout, stderr = Open3.popen3 "\"#{VBOXMGR}\" showvminfo \"packer-#{box_name}\" --machinereadable"
      status = $?
      errors = stderr.readlines
      if errors.empty?
        puts "  Deleting Virtual Machine in Virtualbox"
        stdin, stdout, stderr = Open3.popen3 "\"#{VBOXMGR}\" unregistervm \"packer-#{box_name}\" --delete"
        status = $?
        errors = stderr.readlines
        STDERR.puts "Errors while deleting the Virtual Machine: #{errors}" unless errors.empty?
      end

      vm_dir = nil
      stdin, stdout, stderr = Open3.popen3 "\"#{VBOXMGR}\" list systemproperties"
      errors = stderr.readlines
      STDERR.puts "Errors while querying Virtualbox configuration: #{errors}" unless errors.empty?
      stdout.readlines.each do |line|
        next unless line =~ /^Default machine folder/
        vm_dir = File.join(line.chomp.sub(/^[^:]+:\s+/, ''), "packer-#{box_name}")
        break
      end
      if !vm_dir.nil? && Dir.exist?(vm_dir)
        puts "  Deleting Virtual Machine folder"
        FileUtils.rm_rf vm_dir
      end
    }
  }, # }}}
  vmware: # {{{
  {
    name:         'vmware',
    folder:       'vmware',
    vagrant_type: 'vmware_desktop',
    packer_type:  'vmware-iso',
    supported:    lambda {
      case RUBY_PLATFORM
        when 'x64-mingw32'
          File.exist?(File.join(ENV['ProgramFiles(x86)'], 'VMWare', 'VMWare Workstation', 'vmrun.exe'))
        else which('vmrun') || File.exist?('/Applications/VMware Fusion.app/Contents/Library/vmrun')
      end
    },
    preclean:     lambda { |box_name|  }
  }, # }}}
} # }}}

directory boxes_dir
directory temp_dir
directory log_dir
task :folders => [ boxes_dir, temp_dir, log_dir ]

rule '.box' => [->(box) { sources_for_box(box, templates_dir, scripts_dir) }, boxes_dir, log_dir] do |_rule| # {{{
  box_filename  = _rule.name.pathmap("%f")
  box_name      = _rule.source.pathmap("%2d").pathmap("%f")
  box_version   = /.*-(\d+\.\d+\.\d+)\.box/i =~ box_filename ? $1 : '0.1.0'
  template_path = _rule.source.pathmap("%d")
  builder       = builders[File.basename(_rule.name.pathmap("%d")).to_sym]
  raise ArgumentError, File.basename(_rule.name.pathmap("%d")) if builder.nil?
  mkdir_p _rule.name.pathmap("%d")
  builder[:preclean].call(box_name)
  puts "Building box #{box_name} in #{box_filename} using #{builder[:name]}"
  verbose "  Rule source: #{_rule.source}"
  FileUtils.rm_rf "output-#{builder[:packer_type]}-#{box_name}"
  packer_log    = File.join(log_dir, "packer-build-#{builder[:name]}-#{box_filename}.log")
  config_file   = File.join(template_path, 'config.json')
  template_file = File.join(template_path, 'packer.json')
  File.open(packer_log, "a") { |f| f.puts "==== BEGIN %s %s" % ['=' * 60, Time.now.to_s] }
  ENV['PACKER_LOG']='1'               # Set up child processes environment
  ENV['PACKER_LOG_PATH']=packer_log   # Set up child processes environment
  packer_args=''
  case builder[:name]
    when 'hyperv'
      # Make sure password is complex enough
      share_password = builder[:share_password]
      good=0
      while good < 3
        good = 0
        good +=1 if share_password !~ /[a-zA-Z0-9]/
        good +=1 if share_password =~ /[0-9]/
        good +=1 if share_password =~ /[a-z]/
        good +=1 if share_password =~ /[A-Z]/
        puts "Generating a new password (#{share_password} does not meet Windows complexity requirements)" unless good >= 3
        share_password = SecureRandom.urlsafe_base64(9) unless good >= 3
      end
      # Create a temp user
      puts "Creating temporary user: #{builder[:share_user]}"
      system "net user #{builder[:share_user]} /DEL >NUL"  if system("net user #{builder[:share_user]} 2>NUL >NUL")
      system "net user #{builder[:share_user]} #{share_password} /ADD" 
      # Share log, full permission the temp user
      puts "Creating share: log at #{Dir.pwd}/log"
      shell "if (Get-SmbShare log -ErrorAction SilentlyContinue) { Remove-SmbShare log -Force }" 
      shell "New-SmbShare -Name log -Path '#{Dir.pwd}/log' -FullAccess '#{builder[:share_user]}'"
      # Share daas/cache, read permission the temp user
      puts "Creating share: daas-cache at #{cache_dir}"
      shell "if (Get-SmbShare daas-cache -ErrorAction SilentlyContinue) { Remove-SmbShare daas-cache -Force }" 
      shell "New-SmbShare -Name daas-cache -Path '#{cache_dir}' -ReadAccess '#{builder[:share_user]}'"
      host_ip=shell("Get-NetIPConfiguration | Where InterfaceAlias -like '*Bridged Switch*' | Select -ExpandProperty IPv4Address | Select -ExpandProperty IPAddress")
      packer_args += " -var \"share_host=#{host_ip}\""
      packer_args += " -var \"share_username=#{builder[:share_user]}\""
      packer_args += " -var \"share_password=#{builder[:share_password]}\""
    when 'vmware'
      case RUBY_PLATFORM
        when 'x64-mingw32'
          vmware_iso_dir  = File.join(ENV['ProgramFiles(x86)'], 'VMWare', 'VMWare Workstation')
          packer_args    += " -var \"vmware_iso_dir=#{vmware_iso_dir}\""
        when /.*darwin[0-9]+/
          packer_args += " -var \"vmware_iso_dir=/Applications/VMware Fusion.app/Contents/Library/isoimages\""
      end
  end
  packer_args += " -var \"cache_dir=#{cache_dir}\" -var \"version=#{box_version}\""
  begin
  build_time = Benchmark.measure {
    sh "packer build -only=#{builder[:packer_type]} -var-file=\"#{config_file}\" #{packer_args} \"#{template_file}\""
  }
  puts "Build time: #{build_time.real} seconds"
  ensure
    case builder[:name]
      when 'hyperv'
        # Unshare log
        puts "Removing share: log"
        shell "Remove-SmbShare log -Force" 
        # Unshare daas/cache
        puts "Removing share: daas-cache"
        shell "Remove-SmbShare daas-cache -Force" 
        # Delete the temp user
        puts "Deleting temporary user: #{builder[:share_user]}"
        sh "net user #{builder[:share_user]} /DEL"
    end
    File.open(packer_log, "a") { |f|
      f.puts "Build time: #{build_time.real} seconds"
      f.puts "==== END   %s %s" % ['=' * 60, Time.now.to_s]
    }
  end
end # }}}

# builders tasks {{{
builders_in_use=0
builders.each do |builder_name, builder|
  if builder[:supported][]
    builders_in_use += 1
    TEMPLATE_FILES.each do |template_file|
      config        = load_json(template_file.pathmap("%d/config.json"))
      $logger.info "Processing Template: #{config['template']}"
      version       = config['version'] || case config['template']
        when 'cic'
          $logger.debug "  Calculating version..."
          $logger.debug "  Search cache in #{cache_dir}"
          cic_iso = Rake::FileList.new(File.join(cache_dir, 'CIC_*.iso')).sort.last
          $logger.debug "  Using ISO: #{cic_iso}"
          /CIC_(\d+)_R(\d+)(?:_Patch(\d+))?\.iso/i =~ cic_iso ? "#{$1[2..-1]}.#{$2}.#{$3 || 0}" : '0.1.0'
        else '0.1.0'
      end
      $logger.info "  Version: #{version}"
      box_name      = template_file.pathmap("%{templates/,}d")
      box_file      = "#{boxes_dir}/#{box_name}/#{builder[:folder]}/#{box_name}-#{version}.box"
      box_url       = "file://#{Dir.pwd}/#{box_file}"
      metadata_file = "#{boxes_dir}/#{box_name}/metadata.json"

      namespace :validate do # {{{
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
      end # }}}

      namespace :build do # {{{
        namespace builder_name.to_sym do
          desc "Build box #{box_name} version #{version} with #{builder_name}"
          task box_name => [ :folders, box_file ]

          $box_aliases[box_name].each do |box_alias|
            desc "Alias to build box #{box_name} in vagrant for #{builder_name}"
            task box_alias => [ :folders, box_file ]
          end if $box_aliases[box_name]

          desc "Build all boxes for #{builder_name}"
          task :all => box_name
        end

        desc "Build all boxes for all providers"
        task :all => "#{builder_name}:all"
      end # }}}

      namespace :load do # {{{
        namespace builder_name.to_sym do
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
            load_time = Benchmark.measure {
              sh "vagrant box add --force #{box_name} #{box_file}"
            }
            puts "Load time: #{load_time.real} seconds"
            # Now move the new box in the proper version folder
            verbose "moving #{box_root}/0/#{vagrant_provider} to #{box_root}/#{version}"
            FileUtils.mv   "#{box_root}/0/#{vagrant_provider}", "#{box_root}/#{version}"
            verbose "removing #{box_root}/0"
            FileUtils.rm_r "#{box_root}/0", force: true
            puts "==> box: Successfully updated box '#{box_name}' version to #{version} for '#{vagrant_provider}'"
          end

          desc "Load box #{box_name} in vagrant for #{builder_name}"
          task box_name => loaded_box_marker

          $box_aliases[box_name].each do |box_alias|
            desc "Alias to load box #{box_name} in vagrant for #{builder_name}"
            task box_alias => loaded_box_marker
          end if $box_aliases[box_name]

          desc "Load all boxes in vagrant for #{builder_name}"
          task :all => box_name
        end

        desc "Load all boxes in vagrant"
        task :all => "#{builder_name}:all"
      end # }}}

      namespace :up do # {{{
        namespace builder_name.to_sym do
          desc "Start a Virtual Machine after the box #{box_name} in #{builder_name}"
          task box_name => "load:#{builder_name}:#{box_name}" do
            sh "cd spec ; BOX=\"#{box_name}\" BOX_URL=\"#{box_url}\" vagrant up --provider=#{builder[:vagrant_type]} --provision"
          end
        end
      end # }}}

      namespace :halt do # {{{
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
      end # }}}

      namespace :destroy do # {{{
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
      end # }}}

      namespace :remove do # {{{
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
      end # }}}

      CLOBBER << box_file
      CLOBBER << metadata_file
    end
  end
end # }}}

unless builders_in_use > 0
    STDERR.puts "Error: could not find any virtualization builder!"
end

desc "Turn on verbose mode"
task :verbose do
  $logger = Logger.new(STDOUT)
  $logger.level = Logger::INFO
end

desc "Turn on debug mode"
task :debug => [:verbose] do
  $logger.level = Logger::DEBUG
end

task :default => ['build:all', 'metadata:all']
