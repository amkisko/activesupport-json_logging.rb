require "polyrun/reporting/rspec_junit"

# CI: RSpec JSON → JUnit XML (single-process runs). When Polyrun sets POLYRUN_SHARD_INDEX (parallel-rspec
# workers), emit JSON only to tmp/rspec-<shard>.json so the merge job can run report-junit on tmp/rspec-*.json.
if ENV["CI"]
  if ENV["POLYRUN_SHARD_INDEX"]
    require "fileutils"
    require "rspec/core"
    require "rspec/core/formatters/json_formatter"

    idx = ENV.fetch("POLYRUN_SHARD_INDEX")
    json_out = File.expand_path("../../tmp/rspec-#{idx}.json", __dir__)
    FileUtils.mkdir_p(File.dirname(json_out))
    RSpec.configure do |config|
      config.add_formatter(RSpec::Core::Formatters::JsonFormatter, json_out)
    end
  else
    Polyrun::Reporting::RspecJunit.install!
  end
end
