require_relative "lib/json_logging/version"

Gem::Specification.new do |spec|
  spec.name          = "activesupport-json_logging"
  spec.version       = JsonLogging::VERSION
  spec.authors       = ["Andrei Makarov"]
  spec.email         = ["contact@kiskolabs.com"]

  spec.summary       = "Structured JSON logging for Rails/ActiveSupport with safe, single-line entries."
  spec.description   = "Lightweight JSON logger and formatter integrating with Rails/ActiveSupport. No extra deps beyond Rails/Activesupport. Compatible with Rails 6–8."
  spec.homepage      = "https://github.com/amkisko/activesupport-json_logging.rb"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "README.md", "LICENSE*", "CHANGELOG.md"].select { |f| File.file?(f) }
  end
  spec.required_ruby_version = ">= 2.7"

  spec.metadata = {
    "source_code_uri" => "https://github.com/amkisko/activesupport-json_logging.rb",
    "changelog_uri" => "https://github.com/amkisko/activesupport-json_logging.rb/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/amkisko/activesupport-json_logging.rb/issues"
  }

  spec.add_runtime_dependency "activesupport", ">= 6.0", "< 9.0"
  spec.add_runtime_dependency "railties", ">= 6.0", "< 9.0"

  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "webmock", "~> 3"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "rspec_junit_formatter", "~> 0.6"
  spec.add_development_dependency "simplecov-cobertura", "~> 3"
  spec.add_development_dependency "standard", "~> 1"
  spec.add_development_dependency "appraisal", "~> 2"
  spec.add_development_dependency "memory_profiler", "~> 1"
  spec.add_development_dependency "rbs", "~> 3"
end


