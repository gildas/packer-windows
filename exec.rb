require 'open3'

def shell(command)
  case RUBY_PLATFORM
    when 'x64-mingw32'
      stdin, stdout, stderr = Open3.popen3 "powershell.exe -NoLogo -ExecutionPolicy Bypass -Command #{command}" 
      stdin.close
      output=stdout.readlines.join.chomp
      error=stderr.readlines.join.chomp
      puts "Output: #{output.inspect}"
      puts "Error: #{error.inspect}"
      return error unless error.empty? #TODO: throw error in the futur?
      return output
    else
      system command
  end
end

status = shell(ARGV.first)
puts "Exit Status: #{status}"
