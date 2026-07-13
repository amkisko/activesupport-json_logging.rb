require "spec_helper"
require "stringio"

RSpec.describe "JsonLogging hot-path optimizations" do
  describe JsonLogging::Sanitizer do
    describe ".sanitize_string" do
      it "returns the same string object for clean ASCII text", :aggregate_failures do
        message = "request completed"
        result = described_class.sanitize_string(message)
        expect(result).to eq(message)
        expect(result).to be(message)
      end

      it "still strips control characters when present" do
        result = described_class.sanitize_string("hello\x00world")
        expect(result).to eq("helloworld")
      end
    end

    describe ".rails_parameter_filter" do
      it "reuses the same filter instance for unchanged filter_parameters", :aggregate_failures do
        skip "ActiveSupport::ParameterFilter not available" unless defined?(ActiveSupport::ParameterFilter)

        filter_parameters = [:password]
        rails_module = Module.new
        rails_application = instance_double("Rails::Application")
        rails_configuration = instance_double("Rails::Application::Configuration", filter_parameters: filter_parameters)

        allow(rails_application).to receive(:config).and_return(rails_configuration)
        stub_const("Rails", rails_module)
        allow(Rails).to receive(:respond_to?).with(:application).and_return(true)
        allow(Rails).to receive(:application).and_return(rails_application)

        described_class.reset_rails_parameter_filter_cache!

        first_filter = described_class.rails_parameter_filter
        second_filter = described_class.rails_parameter_filter

        expect(first_filter).to be_a(ActiveSupport::ParameterFilter)
        expect(second_filter).to equal(first_filter)
      end
    end
  end

  describe JsonLogging do
    after do
      described_class.send(:context_storage)[described_class::THREAD_CONTEXT_KEY] = nil
      described_class.send(:context_storage)[described_class::SANITIZED_CONTEXT_CACHE_KEY] = nil
      described_class.additional_context = nil
      JsonLogging::Sanitizer.reset_rails_parameter_filter_cache!
    end

    describe ".additional_context_for_payload" do
      it "sanitizes context once per with_context scope across multiple log lines", :aggregate_failures do
        io = StringIO.new
        logger = described_class::JsonLogger.new(io)
        sanitize_calls = 0

        allow(JsonLogging::Sanitizer).to receive(:sanitize_hash).and_wrap_original do |original, *args, **kwargs|
          sanitize_calls += 1
          original.call(*args, **kwargs)
        end

        described_class.with_context(user_id: 42, password: "secret") do
          logger.info("first")
          logger.info("second")
        end

        expect(sanitize_calls).to eq(1)

        io.rewind
        lines = io.readlines
        expect(lines.length).to eq(2)
        lines.each do |line|
          payload = JSON.parse(line)
          expect(payload.dig("context", "user_id")).to eq(42)
          expect(payload.dig("context", "password_filtered")).to eq("[FILTERED]")
        end
      end

      it "re-sanitizes when a transformer is configured", :aggregate_failures do
        io = StringIO.new
        logger = described_class::JsonLogger.new(io)
        counter = 0

        described_class.additional_context = lambda do |context|
          counter += 1
          context.merge(sequence: counter)
        end

        described_class.with_context(user_id: 1) do
          logger.info("first")
          logger.info("second")
        end

        io.rewind
        payloads = io.readlines.map { |line| JSON.parse(line) }
        expect(payloads.map { |payload| payload.dig("context", "sequence") }).to eq([1, 2])
      end
    end
  end

  describe "tag sanitization at push time" do
    it "strips control characters from tags before they reach the payload", :aggregate_failures do
      io = StringIO.new
      logger = JsonLogging::JsonLogger.new(io)

      logger.tagged("REQUEST\x00ID") do
        logger.info("done")
      end

      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["tags"]).to eq(["REQUESTID"])
    end
  end

  describe JsonLogging::LineEncoder do
    describe ".to_json_line" do
      it "skips deep_stringify_keys when payload already uses string keys", :aggregate_failures do
        payload = {"message" => "hello", "context" => {"user_id" => 1}}

        expect(payload).not_to receive(:deep_stringify_keys)

        line = described_class.to_json_line(payload)
        expect(JSON.parse(line)).to eq(payload)
      end

      it "still stringifies symbol keys when present", :aggregate_failures do
        line = described_class.to_json_line({message: "hello"})
        expect(JSON.parse(line)).to eq("message" => "hello")
      end
    end
  end
end
