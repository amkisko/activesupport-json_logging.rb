#!/usr/bin/env ruby

require "fileutils"

def execute_command(command)
  green = "\033[0;32m"
  red = "\033[1;31m"
  nc = "\033[0m"
  
  puts "#{green}#{command}#{nc}"
  unless system(command)
    puts "#{red}Command failed: #{command}#{nc}"
    exit 1
  end
end

execute_command("bundle")
execute_command("bundle exec appraisal generate")
execute_command("bundle exec rubocop -a 2>&1 | tee tmp/rubocop.log")
execute_command("bundle exec rbs validate")
execute_command("bundle exec rspec 2>&1 | tee tmp/rspec.log")

puts "Tests passed. Checking git status..."

git_status = `git diff --shortstat 2>/dev/null`.strip
unless git_status.empty?
  puts "\033[1;31mgit working directory not clean, please commit your changes first \033[0m"
  puts "\033[1;33mNote: rubocop -a may have modified files. Review and commit changes before releasing.\033[0m"
  exit 1
end

gem_name = "activesupport-json_logging"
version_file = "lib/json_logging/version.rb"
version_content = File.read(version_file)
version = version_content.match(/VERSION\s*=\s*"([0-9.]+)"/)[1]
gem_file = "#{gem_name}-#{version}.gem"

execute_command("gem build #{gem_name}.gemspec")

puts "Ready to release #{gem_file} #{version}"
print "Continue? [Y/n] "
answer = $stdin.gets.chomp
unless answer == "Y" || answer.empty?
  puts "Exiting"
  exit 1
end

execute_command("gem push #{gem_file}")
execute_command("git tag #{version} && git push --tags")
execute_command("gh release create #{version} --generate-notes")

