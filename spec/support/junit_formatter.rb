if ENV["CI"]
  require "rspec_junit_formatter"
  RSpec.configure do |config|
    config.add_formatter RspecJunitFormatter, "coverage/junit-coverage.xml"
  end
end
