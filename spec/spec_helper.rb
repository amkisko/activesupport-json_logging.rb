require "simplecov"
require "simplecov-cobertura"

SimpleCov.start do
  track_files "{lib,app}/**/*.rb"
  add_filter "/lib/tasks/"
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ])
end

require "rspec"
require "json"
require_relative "../lib/json_logging"

Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require_relative f }

RSpec.configure do |config|
end
