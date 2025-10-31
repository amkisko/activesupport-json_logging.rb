require "rake"
begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # RSpec not installed yet
end

begin
  require "standard/rake"
rescue LoadError
  # Standard not installed yet
end

begin
  require "appraisal"
  Appraisal::Task.new
rescue LoadError
  # Appraisal not installed yet
end

task default: :spec
