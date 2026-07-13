require "spec_helper"
require "stringio"
require "active_support/logger"

# Optional CPU/allocation profiles and IPS comparisons for local optimization work.
# rubocop:disable RSpec/DescribeClass, RSpec/NoExpectationExample, Rails/Output
RSpec.describe "Performance profiling", :benchmark do
  let(:iterations) { 5_000 }
  let(:io) { StringIO.new }

  describe "stackprof profiles" do
    before { skip "Set STACKPROF=1 to generate StackProf profiles" unless ENV["STACKPROF"] == "1" }

    it "profiles simple message logging on CPU", :aggregate_failures do
      json_logger = JsonLogging::JsonLogger.new(io)

      path = BenchmarkProfiler.profile_cpu(label: "stackprof_simple_message", iterations: iterations) do
        json_logger.info("request completed")
      end

      expect(File).to exist(path)
    end

    it "profiles hash message logging allocations", :aggregate_failures do
      json_logger = JsonLogging::JsonLogger.new(io)

      path = BenchmarkProfiler.profile_allocations(label: "stackprof_hash_message", iterations: iterations / 5) do
        json_logger.info({event: "test", value: 1, active: true})
      end

      expect(File).to exist(path)
    end
  end

  describe "benchmark-ips comparisons" do
    before { skip "Set BENCHMARK_IPS=1 to compare iterations per second" unless ENV["BENCHMARK_IPS"] == "1" }

    it "compares simple message throughput", :aggregate_failures do
      json_logger = JsonLogging::JsonLogger.new(io.dup)
      standard_logger = ActiveSupport::Logger.new(io.dup)

      path = BenchmarkProfiler.compare_ips do |comparison|
        comparison.config(time: 1, warmup: 1)

        comparison.report("json_logger") do
          json_logger.info("request completed")
        end

        comparison.report("standard_logger") do
          standard_logger.info("request completed")
        end

        comparison.compare!
      end

      expect(File).to exist(path)
    end
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/NoExpectationExample, Rails/Output
