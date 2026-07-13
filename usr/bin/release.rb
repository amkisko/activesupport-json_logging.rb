#!/usr/bin/env ruby
# frozen_string_literal: true

# Repository release settings
VERSION_FILE = "lib/json_logging/version.rb"
POLYRUN_WORKERS = 5
RELEASE_INTEGRATION = false
POLYRUN_MERGE_FORMATS = nil

require "fileutils"
require_relative "../lib/release_version_check"

FileUtils.mkdir_p("tmp")

def execute_command(command)
  green = "\033[0;32m"
  red = "\033[1;31m"
  nc = "\033[0m"

  puts "#{green}#{command}#{nc}"
  shell_command = command.include?("|") ? "set -o pipefail; #{command}" : command
  unless system("bash", "-c", shell_command)
    puts "#{red}Command failed: #{command}#{nc}"
    exit 1
  end
end

gemspec = Dir.glob("*.gemspec").fetch(0)
gem_name = File.basename(gemspec, ".gemspec")

execute_command("bundle install")
execute_command("bundle exec appraisal install")
execute_command("ruby usr/bin/license_audit.rb") if File.exist?("usr/bin/license_audit.rb")
execute_command("bundle exec rubocop -a 2>&1 | tee tmp/rubocop.log")
execute_command("bundle exec rbs validate")

test_env = []
test_env << "INTEGRATION=1" if RELEASE_INTEGRATION
test_env << "POLYRUN_COVERAGE=1"
test_env << "POLYRUN_MERGE_FORMATS=#{POLYRUN_MERGE_FORMATS}" if POLYRUN_MERGE_FORMATS
test_command = "#{test_env.join(" ")} bundle exec polyrun parallel-rspec --workers #{POLYRUN_WORKERS} --merge-failures 2>&1 | tee tmp/polyrun-rspec.log"
execute_command(test_command)

puts "Tests passed. Checking git status..."

git_status = `git diff --shortstat 2>/dev/null`.strip
unless git_status.empty?
  puts "\033[1;31mgit working directory not clean, please commit your changes first \033[0m"
  puts "\033[1;33mNote: rubocop -a may have modified files. Review and commit changes before releasing.\033[0m"
  exit 1
end

version_content = File.read(VERSION_FILE)
version = version_content.match(/VERSION\s*=\s*"([0-9.]+)"/)[1]
gem_file = "#{gem_name}-#{version}.gem"

ReleaseVersionCheck.warn_if_already_released(version: version, package_name: gem_name, registry: :rubygems)

execute_command("gem build #{gemspec}")

puts "Ready to release #{gem_file} #{version}"
print "Continue? [Y/n] "
answer = $stdin.gets.chomp
unless ["Y", ""].include?(answer)
  puts "Exiting"
  exit 1
end

execute_command("gem push #{gem_file}")
execute_command("git tag #{version} && git push --tags")
execute_command("gh release create #{version} --generate-notes")
