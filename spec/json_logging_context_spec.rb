require "spec_helper"
require "stringio"
require "active_support/logger"

RSpec.describe JsonLogging do
  describe ".with_context" do
    it "adds and clears context within block", :aggregate_failures do
      expect(described_class.additional_context).to eq({})
      described_class.with_context(user_id: 42) do
        expect(described_class.additional_context[:user_id]).to eq(42)
      end
      expect(described_class.additional_context).to eq({})
    end

    it "merges context when nested", :aggregate_failures do
      described_class.with_context(a: 1) do
        described_class.with_context(b: 2) do
          expect(described_class.additional_context).to eq({a: 1, b: 2})
        end
      end
    end

    it "handles non-hash arguments via safe_hash", :aggregate_failures do
      described_class.with_context(nil) do
        expect(described_class.additional_context).to eq({})
      end

      described_class.with_context("not a hash") do
        expect(described_class.additional_context).to eq({})
      end

      described_class.with_context([]) do
        expect(described_class.additional_context).to eq({})
      end
    end

    it "handles nested context with empty/nil values", :aggregate_failures do
      described_class.with_context(a: nil, b: "", c: false) do
        expect(described_class.additional_context).to eq({a: nil, b: "", c: false})

        described_class.with_context(d: nil) do
          expect(described_class.additional_context).to include(a: nil, b: "", c: false, d: nil)
        end
      end
    end

    it "handles objects that raise on is_a? check", :aggregate_failures do
      obj = Object.new
      def obj.is_a?(*)
        raise "error in is_a?"
      end

      # Should not raise and should return empty hash
      result = nil
      described_class.with_context(obj) do
        result = described_class.additional_context
      end
      expect(result).to eq({})
    end
  end

  describe ".additional_context" do
    it "returns empty hash when dup raises an error", :aggregate_failures do
      # Create a context that will raise on dup
      context_hash = {}
      def context_hash.dup
        raise StandardError.new("dup error")
      end

      # Set context manually using the same key the implementation uses
      key = :__json_logging_context
      Thread.current[key] = context_hash

      # Should rescue and return empty hash
      expect(described_class.additional_context).to eq({})

      # Clean up
      Thread.current[key] = nil
    end

    it "handles context with compact correctly", :aggregate_failures do
      described_class.with_context(a: 1, b: nil, c: "", d: false) do
        context = described_class.additional_context.compact
        # compact removes nil, but keeps false and empty string
        expect(context).to include(a: 1, c: "", d: false)
        expect(context).not_to have_key(:b)
      end
    end
  end

  describe ".safe_hash" do
    it "returns hash as-is when given a hash", :aggregate_failures do
      hash = {a: 1, b: 2}
      result = described_class.safe_hash(hash)
      expect(result).to eq({a: 1, b: 2})
    end

    it "returns empty hash for non-hash objects", :aggregate_failures do
      expect(described_class.safe_hash(nil)).to eq({})
      expect(described_class.safe_hash("string")).to eq({})
      expect(described_class.safe_hash([])).to eq({})
      expect(described_class.safe_hash(123)).to eq({})
    end

    it "handles objects that raise on is_a? check", :aggregate_failures do
      obj = Object.new
      def obj.is_a?(*)
        raise "error"
      end

      result = described_class.safe_hash(obj)
      expect(result).to eq({})
    end

    it "handles hash-like objects that respond to is_a?", :aggregate_failures do
      # Even if it responds to is_a?, if it's not actually a Hash, return {}
      obj = double(is_a?: false)
      result = described_class.safe_hash(obj)
      expect(result).to eq({})
    end
  end

  describe ".new" do
    let(:io) { StringIO.new }
    let(:base_logger) { ActiveSupport::Logger.new(io) }

    it "wraps a standard logger with JSON formatting", :aggregate_failures do
      logger = described_class.new(base_logger)
      logger.info("test message")

      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["severity"]).to eq("INFO")
      expect(payload["message"]).to eq("test message")
    end

    it "supports service-specific tagged loggers", :aggregate_failures do
      logger = described_class.new(base_logger)
      dotenv_logger = logger.tagged("dotenv")

      dotenv_logger.info("Loading .env file")
      dotenv_logger.warn("Missing .env.local file")

      io.rewind
      lines = io.readlines
      expect(lines.length).to eq(2)

      lines.each do |line|
        payload = JSON.parse(line)
        expect(payload["tags"]).to eq(["dotenv"])
      end
    end

    it "works with BroadcastLogger", :aggregate_failures do
      skip "BroadcastLogger not available (requires Rails 7.1+)" unless defined?(ActiveSupport::BroadcastLogger)

      logger = described_class.new(base_logger)
      broadcast_logger = ActiveSupport::BroadcastLogger.new(logger)

      # Service-specific logger through BroadcastLogger
      dotenv_logger = broadcast_logger.tagged("dotenv")
      dotenv_logger.info("Environment loaded")

      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["tags"]).to eq(["dotenv"])
      expect(payload["message"]).to eq("Environment loaded")
    end
  end

  describe ".logger" do
    let(:io) { StringIO.new }

    it "creates a logger and wraps it with JSON formatting", :aggregate_failures do
      logger = described_class.logger(io)
      logger.info("test message")

      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["severity"]).to eq("INFO")
      expect(payload["message"]).to eq("test message")
    end

    it "supports service-specific tagged loggers", :aggregate_failures do
      base_logger = described_class.logger(io)
      dotenv_logger = base_logger.tagged("dotenv")

      dotenv_logger.info("Loading .env file")
      dotenv_logger.warn("Missing .env.local file")

      io.rewind
      lines = io.readlines
      expect(lines.length).to eq(2)

      lines.each do |line|
        payload = JSON.parse(line)
        expect(payload["tags"]).to eq(["dotenv"])
      end
    end

    it "works with BroadcastLogger", :aggregate_failures do
      skip "BroadcastLogger not available (requires Rails 7.1+)" unless defined?(ActiveSupport::BroadcastLogger)

      logger = described_class.logger(io)
      broadcast_logger = ActiveSupport::BroadcastLogger.new(logger)

      # Service-specific logger through BroadcastLogger
      dotenv_logger = broadcast_logger.tagged("dotenv")
      dotenv_logger.info("Environment loaded")

      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["tags"]).to eq(["dotenv"])
      expect(payload["message"]).to eq("Environment loaded")
    end
  end
end
