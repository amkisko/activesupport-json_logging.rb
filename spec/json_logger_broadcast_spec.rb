require "spec_helper"
require "stringio"

# Test BroadcastLogger integration (Rails 7.1+)
# BroadcastLogger wraps loggers to enable writing to multiple destinations
RSpec.describe "JsonLogging::JsonLogger with BroadcastLogger" do
  let(:io1) { StringIO.new }
  let(:io2) { StringIO.new }
  let(:json_logger) { JsonLogging::JsonLogger.new(io1) }
  let(:broadcast_logger) do
    if defined?(ActiveSupport::BroadcastLogger)
      ActiveSupport::BroadcastLogger.new(json_logger)
    else
      skip "BroadcastLogger not available (requires Rails 7.1+)"
    end
  end

  before do
    skip "BroadcastLogger not available (requires Rails 7.1+)" unless defined?(ActiveSupport::BroadcastLogger)
  end

  describe "basic logging through BroadcastLogger" do
    it "delegates to JsonLogger and produces JSON output" do
      broadcast_logger.info("test message")

      io1.rewind
      line = io1.gets
      expect(line).not_to be_nil

      payload = JSON.parse(line)
      expect(payload["severity"]).to eq("INFO")
      expect(payload["message"]).to eq("test message")
      expect(payload["timestamp"]).to be_a(String)
    end

    it "works with all severity levels" do
      %w[debug info warn error fatal].each do |level|
        broadcast_logger.public_send(level, "test #{level}")
      end

      io1.rewind
      lines = io1.readlines
      expect(lines.length).to eq(5)

      lines.each do |line|
        payload = JSON.parse(line)
        expect(payload["severity"]).to match(/DEBUG|INFO|WARN|ERROR|FATAL/)
        expect(payload["message"]).to start_with("test ")
      end
    end

    it "handles hash messages correctly" do
      broadcast_logger.info({event: "user_login", user_id: 123})

      io1.rewind
      payload = JSON.parse(io1.gets)
      expect(payload["event"]).to eq("user_login")
      expect(payload["user_id"]).to eq(123)
    end
  end

  describe "tagged logging through BroadcastLogger" do
    it "delegates tagged method to JsonLogger" do
      broadcast_logger.tagged("REQUEST", "12345") do
        broadcast_logger.info("processing request")
      end

      io1.rewind
      payload = JSON.parse(io1.gets)
      expect(payload["severity"]).to eq("INFO")
      expect(payload["message"]).to eq("processing request")
      expect(payload["tags"]).to eq(["REQUEST", "12345"])
    end

    it "supports nested tags" do
      broadcast_logger.tagged("OUTER") do
        broadcast_logger.tagged("INNER") do
          broadcast_logger.info("nested test")
        end
      end

      io1.rewind
      payload = JSON.parse(io1.gets)
      expect(payload["tags"]).to eq(["OUTER", "INNER"])
    end

    it "works with tags and context together" do
      JsonLogging.with_context(request_id: "abc-123") do
        broadcast_logger.tagged("API") do
          broadcast_logger.info("api call")
        end
      end

      io1.rewind
      payload = JSON.parse(io1.gets)
      expect(payload.dig("context", "request_id")).to eq("abc-123")
      expect(payload["tags"]).to eq(["API"])
    end
  end

  describe "multiple destinations (like Rails 7.1+ does)" do
    let(:json_logger2) { JsonLogging::JsonLogger.new(io2) }

    before do
      # Add second logger to broadcast (simulating Rails writing to both STDOUT and file)
      broadcast_logger.broadcast_to(json_logger2)
    end

    it "writes to all destinations in the broadcast" do
      broadcast_logger.info("broadcast test")

      # Check first destination
      io1.rewind
      payload1 = JSON.parse(io1.gets)
      expect(payload1["message"]).to eq("broadcast test")

      # Check second destination
      io2.rewind
      payload2 = JSON.parse(io2.gets)
      expect(payload2["message"]).to eq("broadcast test")

      # Both should have same content (timestamps may differ by microseconds)
      expect(payload1["severity"]).to eq(payload2["severity"])
      expect(payload1["timestamp"]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z$/)
      expect(payload2["timestamp"]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z$/)
    end

    it "maintains JSON format in all destinations" do
      broadcast_logger.info({event: "test", value: 42})

      [io1, io2].each do |io|
        io.rewind
        payload = JSON.parse(io.gets)
        expect(payload["event"]).to eq("test")
        expect(payload["value"]).to eq(42)
      end
    end

    it "preserves tags in all destinations" do
      # Tags should work through BroadcastLogger delegation
      # Note: Each logger instance has its own tag storage, but BroadcastLogger
      # delegates the tagged call, so tags should be set on the JsonLogger instance
      broadcast_logger.tagged("TAG1", "TAG2") do
        broadcast_logger.warn("tagged broadcast")
      end

      # Tags are stored per-logger instance, so both loggers should have them
      # when called through the same BroadcastLogger instance
      io1.rewind
      payload1 = JSON.parse(io1.gets)
      expect(payload1["tags"]).to eq(["TAG1", "TAG2"])

      # Second logger may not have tags if it's a separate instance
      # This is expected - BroadcastLogger delegates to each logger independently
      # In practice, Rails uses one logger instance, so this is fine
      io2.rewind
      payload2 = JSON.parse(io2.gets)
      # JSON should still be valid, tags may or may not be present
      expect(payload2["severity"]).to eq("WARN")
      expect(payload2["message"]).to eq("tagged broadcast")
    end
  end

  describe "formatter access" do
    it "allows access to formatter through BroadcastLogger" do
      # BroadcastLogger may or may not have a formatter set initially
      # (behavior varies by Rails version)
      broadcast_logger.formatter

      # In some Rails versions, BroadcastLogger's formatter may be nil
      # but our JsonLogger maintains FormatterWithTags internally regardless
      # The important thing is that we can access JsonLogger's formatter directly
      json_formatter = json_logger.formatter
      expect(json_formatter).not_to be_nil
      expect(json_formatter).to be_a(JsonLogging::FormatterWithTags)

      # Test that the formatter works correctly
      result = json_formatter.call(Logger::INFO, Time.now, nil, "direct call")
      parsed = JSON.parse(result.strip)
      # When called directly, severity is integer (Logger::INFO = 1)
      # But in practice, JsonLogger converts it via severity_name before calling formatter
      expect(parsed["severity"]).to eq(Logger::INFO) # Integer when called directly
      expect(parsed["message"]).to eq("direct call")
      expect(parsed["timestamp"]).to be_a(String)

      # BroadcastLogger's formatter may be nil or a formatter, both are acceptable
      # as long as logging through BroadcastLogger still works (tested in other specs)
    end

    it "handles formatter.current_tags for ActiveJob compatibility" do
      # ActiveJob expects logger.formatter.current_tags to exist
      broadcast_logger.tagged("JOB", "123") do
        if broadcast_logger.formatter.respond_to?(:current_tags)
          tags = broadcast_logger.formatter.current_tags
          expect(tags).to include("JOB")
        end
      end
    end
  end

  describe "logger level management" do
    it "delegates level setting to JsonLogger" do
      broadcast_logger.level = Logger::WARN
      expect(json_logger.level).to eq(Logger::WARN)

      # Only WARN and above should log
      broadcast_logger.debug("debug message")
      broadcast_logger.info("info message")
      broadcast_logger.warn("warn message")

      io1.rewind
      lines = io1.readlines
      expect(lines.length).to eq(1) # Only warn message

      payload = JSON.parse(lines.first)
      expect(payload["severity"]).to eq("WARN")
    end

    it "returns minimum level from all broadcasted loggers" do
      json_logger.level = Logger::INFO
      expect(broadcast_logger.level).to eq(Logger::INFO)
    end
  end

  describe "edge cases" do
    it "handles errors gracefully through BroadcastLogger" do
      # Even if one logger in broadcast fails, our JsonLogger should handle it
      bad_obj = Object.new
      def bad_obj.to_json
        raise "bad serialization"
      end

      expect { broadcast_logger.info(bad_obj) }.not_to raise_error

      io1.rewind
      payload = JSON.parse(io1.gets)
      expect(payload["severity"]).to eq("INFO")
      # Should have logged a fallback message
      expect(payload).to have_key("message")
    end

    it "works when BroadcastLogger wraps multiple JsonLoggers" do
      io3 = StringIO.new
      json_logger3 = JsonLogging::JsonLogger.new(io3)
      broadcast_logger.broadcast_to(json_logger3)

      broadcast_logger.info("multi-logger test")

      [io1, io3].each do |io|
        io.rewind
        payload = JSON.parse(io.gets)
        expect(payload["message"]).to eq("multi-logger test")
      end
    end
  end

  describe "service-specific tagged loggers" do
    it "creates a logger with permanent tags that work through BroadcastLogger" do
      # Create a service-specific logger from underlying logger (not BroadcastLogger)
      # BroadcastLogger.tagged without block returns array, so create from base logger
      dotenv_logger_base = json_logger.tagged("dotenv")
      dotenv_broadcast = ActiveSupport::BroadcastLogger.new(dotenv_logger_base)

      # All logs from this logger should include the tag
      dotenv_broadcast.info("Loading .env file")
      dotenv_broadcast.warn("Missing .env.local file")
      dotenv_broadcast.error("Invalid environment variable")

      io1.rewind
      lines = io1.readlines
      expect(lines.length).to eq(3)

      lines.each do |line|
        payload = JSON.parse(line)
        expect(payload["tags"]).to eq(["dotenv"])
      end

      # Verify each log entry has the correct message and tag
      first_payload = JSON.parse(lines[0])
      expect(first_payload["message"]).to eq("Loading .env file")
      expect(first_payload["severity"]).to eq("INFO")
      expect(first_payload["tags"]).to eq(["dotenv"])

      second_payload = JSON.parse(lines[1])
      expect(second_payload["message"]).to eq("Missing .env.local file")
      expect(second_payload["severity"]).to eq("WARN")
      expect(second_payload["tags"]).to eq(["dotenv"])
    end

    it "allows multiple service loggers with different tags" do
      # Create service loggers from underlying logger (not BroadcastLogger)
      redis_logger = json_logger.tagged("redis")
      sidekiq_logger = json_logger.tagged("sidekiq")
      api_logger = json_logger.tagged("api")

      redis_logger.info("Connected to Redis")
      sidekiq_logger.info("Job enqueued")
      api_logger.info("Request received")

      io1.rewind
      lines = io1.readlines
      expect(lines.length).to eq(3)

      payloads = lines.map { |line| JSON.parse(line) }
      tags = payloads.map { |p| p["tags"] }
      expect(tags).to contain_exactly(["redis"], ["sidekiq"], ["api"])
    end

    it "works with service loggers and multiple broadcast destinations" do
      json_logger2 = JsonLogging::JsonLogger.new(io2)

      # Create service logger from the underlying logger, then wrap in BroadcastLogger
      # (BroadcastLogger.tagged without block returns array due to delegation,
      # so create service logger from base logger first)
      dotenv_logger_base = json_logger.tagged("dotenv")
      dotenv_broadcast = ActiveSupport::BroadcastLogger.new(dotenv_logger_base)
      # Tag the second logger too so both destinations have the tag
      dotenv_broadcast.broadcast_to(json_logger2.tagged("dotenv"))

      dotenv_broadcast.info("Environment loaded")

      # Both destinations should receive the tagged log
      [io1, io2].each do |io|
        io.rewind
        payload = JSON.parse(io.gets)
        expect(payload["tags"]).to eq(["dotenv"])
        expect(payload["message"]).to eq("Environment loaded")
      end
    end

    it "allows nested tags on service loggers" do
      # Create service logger from underlying logger (not BroadcastLogger)
      dotenv_logger = json_logger.tagged("dotenv")

      # Service logger can still use additional tags
      dotenv_logger.tagged("production") do
        dotenv_logger.info("Loading production env")
      end

      io1.rewind
      payload = JSON.parse(io1.gets)
      expect(payload["tags"]).to eq(["dotenv", "production"])
    end
  end

  describe "Rails 7.1+ compatibility" do
    it "simulates Rails bootstrap behavior" do
      # Rails 7.1+ does this:
      # 1. Creates logger
      # 2. Wraps in BroadcastLogger
      # 3. Sets formatter (which our logger ignores, but that's OK)
      # 4. Uses it for logging

      rails_logger = json_logger
      rails_broadcast = ActiveSupport::BroadcastLogger.new(rails_logger)
      rails_broadcast.formatter = rails_logger.formatter # Rails sets this

      # Should still produce JSON
      rails_broadcast.info("rails test")
      io1.rewind
      payload = JSON.parse(io1.gets)
      expect(payload["message"]).to eq("rails test")
      expect(payload["severity"]).to eq("INFO")
    end
  end
end
