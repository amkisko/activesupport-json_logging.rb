require "spec_helper"
require "stringio"

RSpec.describe JsonLogging::JsonLogger do
  let(:io) { StringIO.new }

  describe "initialization" do
    it "initializes with logdev only" do
      logger = described_class.new(io)
      expect(logger).to be_a(described_class)
    end

    it "initializes with logdev and shift_age" do
      logger = described_class.new(io, 7)
      expect(logger).to be_a(described_class)
    end

    it "initializes with logdev, shift_age, and shift_size" do
      logger = described_class.new(io, 7, 1_048_576)
      expect(logger).to be_a(described_class)
    end

    it "uses default stdout when no args" do
      logger = described_class.new
      expect(logger.instance_variable_get(:@logdev).dev).to eq($stdout)
    end
  end

  describe "formatter" do
    it "returns FormatterWithTags" do
      logger = described_class.new(io)
      expect(logger.formatter).to be_a(JsonLogging::FormatterWithTags)
    end

    it "ignores attempts to set formatter" do
      logger = described_class.new(io)
      original_formatter = logger.formatter
      logger.formatter = Object.new
      expect(logger.formatter).to eq(original_formatter)
    end
  end

  describe "#add" do
    let(:logger) { described_class.new(io) }

    it "skips logging when severity is below level" do
      logger.level = Logger::ERROR
      logger.info("test")
      io.rewind
      expect(io.read).to be_empty
    end

    it "uses block when message is nil" do
      logger.info { "block message" }
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["message"]).to eq("block message")
    end

    it "uses progname when message is nil and no block" do
      logger.add(Logger::INFO, nil, "progname message")
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["message"]).to eq("progname message")
    end

    it "handles all severity levels", :aggregate_failures do
      %w[debug info warn error fatal].each do |level|
        logger.public_send(level, "test #{level}")
      end
      io.rewind
      lines = io.readlines
      expect(lines.size).to eq(5)
      lines.each do |line|
        payload = JSON.parse(line)
        expect(payload["severity"]).to be_a(String)
      end
    end

    it "handles unknown severity" do
      logger.add(999, "unknown severity")
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["severity"]).to eq("999")
    end

    it "uses severity_name for all standard severity levels", :aggregate_failures do
      logger = described_class.new(io)

      # Test all standard severities
      expect(logger.send(:severity_name, Logger::DEBUG)).to eq("DEBUG")
      expect(logger.send(:severity_name, Logger::INFO)).to eq("INFO")
      expect(logger.send(:severity_name, Logger::WARN)).to eq("WARN")
      expect(logger.send(:severity_name, Logger::ERROR)).to eq("ERROR")
      expect(logger.send(:severity_name, Logger::FATAL)).to eq("FATAL")
      expect(logger.send(:severity_name, Logger::UNKNOWN)).to eq("UNKNOWN")
    end

    it "converts unknown severity to string", :aggregate_failures do
      logger = described_class.new(io)
      expect(logger.send(:severity_name, 999)).to eq("999")
      expect(logger.send(:severity_name, -1)).to eq("-1")
    end
  end

  describe "#stringify_keys" do
    let(:logger) { described_class.new(io) }

    it "converts symbol keys to strings" do
      hash = {symbol_key: "value", another: 123}
      result = logger.send(:stringify_keys, hash)
      expect(result).to eq({"symbol_key" => "value", "another" => 123})
    end

    it "converts string keys (keeps as strings)" do
      hash = {"string_key" => "value", "another" => 456}
      result = logger.send(:stringify_keys, hash)
      expect(result).to eq({"string_key" => "value", "another" => 456})
    end

    it "handles nested hashes" do
      hash = {outer: {inner: "value", nested: {deep: 123}}}
      result = logger.send(:stringify_keys, hash)
      expect(result).to eq({"outer" => {"inner" => "value", "nested" => {"deep" => 123}}})
    end

    it "handles arrays" do
      hash = {items: [{id: 1}, {id: 2}]}
      result = logger.send(:stringify_keys, hash)
      expect(result).to eq({"items" => [{"id" => 1}, {"id" => 2}]})
    end

    it "handles arrays with nested structures" do
      array = [{key: "value"}, {nested: {deep: 123}}]
      result = logger.send(:stringify_keys, array)
      expect(result).to eq([{"key" => "value"}, {"nested" => {"deep" => 123}}])
    end

    it "preserves non-hash, non-array values" do
      hash = {string: "value", number: 123, boolean: true, nil_value: nil}
      result = logger.send(:stringify_keys, hash)
      expect(result).to eq({"string" => "value", "number" => 123, "boolean" => true, "nil_value" => nil})
    end

    it "handles empty hash" do
      result = logger.send(:stringify_keys, {})
      expect(result).to eq({})
    end

    it "handles empty array" do
      result = logger.send(:stringify_keys, [])
      expect(result).to eq([])
    end

    it "handles mixed key types", :aggregate_failures do
      hash = {:symbol => "a", "string" => "b", 123 => "c", Symbol => "d"}
      result = logger.send(:stringify_keys, hash)
      expect(result.keys).to all(be_a(String))
      expect(result["symbol"]).to eq("a")
      expect(result["string"]).to eq("b")
      expect(result["123"]).to eq("c")
    end
  end

  describe "#format_message" do
    let(:logger) { described_class.new(io) }

    it "uses formatter for formatting", :aggregate_failures do
      result = logger.format_message("INFO", Time.zone.now, nil, "test")
      expect(result).to be_a(String)
      payload = JSON.parse(result)
      expect(payload["severity"]).to eq("INFO")
    end
  end

  describe "#tagged" do
    let(:logger) { described_class.new(io) }

    it "returns new logger when no block given (TaggedLogging-compatible)", :aggregate_failures do
      result = logger.tagged("TAG")
      expect(result).not_to eq(logger)
      expect(result).to be_a(described_class)
      # Original logger should not have tags modified
      expect(logger.send(:current_tags)).to eq([])
      # New logger should have tags
      expect(result.formatter.current_tags).to eq(["TAG"])
    end

    it "handles empty tags gracefully when no block given", :aggregate_failures do
      result = logger.tagged("", nil, [])
      expect(result).not_to eq(logger)
      # Empty tags should result in empty tags array
      expect(result.formatter.current_tags).to eq([])
    end

    it "handles nested arrays in tags when no block given", :aggregate_failures do
      result = logger.tagged(["A", "B"], "C")
      expect(result).not_to eq(logger)
      expect(result.formatter.current_tags).to eq(["A", "B", "C"])
    end

    it "modifies tags in place when block is given", :aggregate_failures do
      logger.tagged("TAG") do
        expect(logger.send(:current_tags)).to eq(["TAG"])
      end
      # Tags should be cleared after block
      expect(logger.send(:current_tags)).to eq([])
    end
  end

  describe "error handling in add" do
    let(:logger) { described_class.new(io) }

    it "handles JSON serialization errors", :aggregate_failures do
      # Force an error in stringify_keys
      allow(logger).to receive(:stringify_keys).and_raise(StandardError.new("json error"))
      logger.info("test")
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload).to have_key("logger_error")
      expect(payload["logger_error"]["message"]).to include("json error")
    end

    it "handles uninitialized msg in error path" do
      # Force error before msg is set - use add directly
      allow(logger).to receive(:build_payload).and_raise(StandardError.new("error"))
      logger.add(Logger::INFO, nil, nil)
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["message"]).to eq("<uninitialized>")
    end
  end
end
