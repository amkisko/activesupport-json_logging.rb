require "spec_helper"

RSpec.describe JsonLogging::Formatter do
  let(:formatter) { described_class.new }

  it "handles nil timestamp" do
    result = formatter.call("INFO", nil, nil, "test")
    payload = JSON.parse(result)
    expect(payload["timestamp"]).to be_a(String)
    expect(payload["severity"]).to eq("INFO")
  end

  it "handles errors in formatting" do
    # Mock an error in PayloadBuilder
    allow(JsonLogging::PayloadBuilder).to receive(:build_base_payload).and_raise(StandardError.new("builder error"))
    result = formatter.call("ERROR", Time.now, nil, "test")
    payload = JSON.parse(result)
    expect(payload["severity"]).to eq("ERROR")
    expect(payload).to have_key("formatter_error")
    expect(payload["formatter_error"]["message"]).to include("builder error")
  end

  it "handles nil timestamp in error path" do
    allow(JsonLogging::PayloadBuilder).to receive(:build_base_payload).and_raise(StandardError.new("error"))
    result = formatter.call("WARN", nil, nil, "test")
    payload = JSON.parse(result)
    expect(payload["timestamp"]).to be_a(String)
    expect(payload).to have_key("formatter_error")
  end

  describe "#build_fallback_output" do
    it "creates fallback output with all required fields" do
      error = StandardError.new("test error")
      result = formatter.send(:build_fallback_output, "ERROR", Time.now, "test message", error)
      payload = JSON.parse(result)

      expect(payload).to have_key("timestamp")
      expect(payload["severity"]).to eq("ERROR")
      expect(payload["message"]).to eq("test message")
      expect(payload).to have_key("formatter_error")
      expect(payload["formatter_error"]["class"]).to eq("StandardError")
      expect(payload["formatter_error"]["message"]).to include("test error")
    end

    it "handles nil timestamp in fallback" do
      error = StandardError.new("error")
      result = formatter.send(:build_fallback_output, "WARN", nil, "msg", error)
      payload = JSON.parse(result)
      expect(payload["timestamp"]).to be_a(String)
      expect(payload["severity"]).to eq("WARN")
    end

    it "handles nil message in fallback" do
      error = StandardError.new("error")
      result = formatter.send(:build_fallback_output, "INFO", Time.now, nil, error)
      payload = JSON.parse(result)
      expect(payload["message"]).to eq("")
    end

    it "sanitizes error message in fallback" do
      error = StandardError.new("error\x00with\x01control")
      result = formatter.send(:build_fallback_output, "ERROR", Time.now, "msg", error)
      payload = JSON.parse(result)
      expect(payload["formatter_error"]["message"]).not_to include("\x00")
      expect(payload["formatter_error"]["message"]).not_to include("\x01")
    end

    it "handles errors where message returns nil" do
      error = StandardError.new("initial message")
      # Make message return nil explicitly
      allow(error).to receive(:message).and_return(nil)

      # When message is nil, safe_string converts it to ""
      result = formatter.send(:build_fallback_output, "ERROR", Time.now, "msg", error)
      payload = JSON.parse(result)
      expect(payload["formatter_error"]["message"]).to be_a(String)
      expect(payload["formatter_error"]["message"]).to eq("")
    end
  end
end

RSpec.describe JsonLogging::FormatterWithTags do
  let(:io) { StringIO.new }
  let(:logger) { JsonLogging::JsonLogger.new(io) }
  let(:formatter) { JsonLogging::FormatterWithTags.new(logger) }

  it "delegates current_tags to logger" do
    logger.tagged("TEST") do
      expect(formatter.current_tags).to eq(["TEST"])
    end
  end

  it "includes tags in output" do
    logger.tagged("REQUEST") do
      result = formatter.call("INFO", Time.now, nil, "test")
      payload = JSON.parse(result)
      expect(payload["tags"]).to eq(["REQUEST"])
    end
  end

  it "handles nil timestamp" do
    result = formatter.call("INFO", nil, nil, "test")
    payload = JSON.parse(result)
    expect(payload["timestamp"]).to be_a(String)
  end

  it "handles errors gracefully" do
    allow(JsonLogging::PayloadBuilder).to receive(:build_base_payload).and_raise(StandardError.new("error"))
    result = formatter.call("ERROR", Time.now, nil, "test")
    payload = JSON.parse(result)
    expect(payload).to have_key("formatter_error")
  end

  describe "#build_fallback_output" do
    it "creates fallback output with all required fields" do
      error = StandardError.new("test error")
      result = formatter.send(:build_fallback_output, "ERROR", Time.now, "test message", error)
      payload = JSON.parse(result)

      expect(payload).to have_key("timestamp")
      expect(payload["severity"]).to eq("ERROR")
      expect(payload["message"]).to eq("test message")
      expect(payload).to have_key("formatter_error")
      expect(payload["formatter_error"]["class"]).to eq("StandardError")
      expect(payload["formatter_error"]["message"]).to include("test error")
    end

    it "handles nil timestamp in fallback" do
      error = StandardError.new("error")
      result = formatter.send(:build_fallback_output, "WARN", nil, "msg", error)
      payload = JSON.parse(result)
      expect(payload["timestamp"]).to be_a(String)
      expect(payload["severity"]).to eq("WARN")
    end

    it "handles nil message in fallback" do
      error = StandardError.new("error")
      result = formatter.send(:build_fallback_output, "INFO", Time.now, nil, error)
      payload = JSON.parse(result)
      expect(payload["message"]).to eq("")
    end

    it "sanitizes error message in fallback" do
      error = StandardError.new("error\x00with\x01control")
      result = formatter.send(:build_fallback_output, "ERROR", Time.now, "msg", error)
      payload = JSON.parse(result)
      expect(payload["formatter_error"]["message"]).not_to include("\x00")
      expect(payload["formatter_error"]["message"]).not_to include("\x01")
    end

    it "handles errors that raise in message.to_s" do
      error = StandardError.new("normal error")
      # Make error.message return something that raises on to_s
      message_obj = Object.new
      def message_obj.to_s
        raise "cannot stringify"
      end
      allow(error).to receive(:message).and_return(message_obj)

      # The formatter uses Helpers.safe_string which catches this
      result = formatter.send(:build_fallback_output, "ERROR", Time.now, "msg", error)
      payload = JSON.parse(result)
      expect(payload["formatter_error"]["message"]).to eq("<unprintable>")
    end
  end
end
