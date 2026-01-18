require "spec_helper"

# rubocop:disable RSpec/MultipleDescribes
RSpec.describe JsonLogging::Formatter do
  let(:formatter) { described_class.new }

  it "handles nil timestamp", :aggregate_failures do
    result = formatter.call("INFO", nil, nil, "test")
    payload = JSON.parse(result)
    expect(payload["timestamp"]).to be_a(String)
    expect(payload["severity"]).to eq("INFO")
  end

  it "handles errors in formatting", :aggregate_failures do
    # Mock an error in PayloadBuilder
    allow(JsonLogging::PayloadBuilder).to receive(:build_base_payload).and_raise(StandardError.new("builder error"))
    result = formatter.call("ERROR", Time.zone.now, nil, "test")
    payload = JSON.parse(result)
    expect(payload["severity"]).to eq("ERROR")
    expect(payload).to have_key("formatter_error")
    expect(payload["formatter_error"]["message"]).to include("builder error")
  end

  it "handles nil timestamp in error path", :aggregate_failures do
    allow(JsonLogging::PayloadBuilder).to receive(:build_base_payload).and_raise(StandardError.new("error"))
    result = formatter.call("WARN", nil, nil, "test")
    payload = JSON.parse(result)
    expect(payload["timestamp"]).to be_a(String)
    expect(payload).to have_key("formatter_error")
  end

  describe "#build_fallback_output" do
    it "creates fallback output with all required fields", :aggregate_failures do
      error = StandardError.new("test error")
      result = formatter.send(:build_fallback_output, "ERROR", Time.zone.now, "test message", error)
      payload = JSON.parse(result)

      expect(payload).to have_key("timestamp")
      expect(payload["severity"]).to eq("ERROR")
      expect(payload["message"]).to eq("test message")
      expect(payload).to have_key("formatter_error")
      expect(payload["formatter_error"]["class"]).to eq("StandardError")
      expect(payload["formatter_error"]["message"]).to include("test error")
    end

    it "handles nil timestamp in fallback", :aggregate_failures do
      error = StandardError.new("error")
      result = formatter.send(:build_fallback_output, "WARN", nil, "msg", error)
      payload = JSON.parse(result)
      expect(payload["timestamp"]).to be_a(String)
      expect(payload["severity"]).to eq("WARN")
    end

    it "handles nil message in fallback" do
      error = StandardError.new("error")
      result = formatter.send(:build_fallback_output, "INFO", Time.zone.now, nil, error)
      payload = JSON.parse(result)
      expect(payload["message"]).to eq("")
    end

    it "sanitizes error message in fallback", :aggregate_failures do
      error = StandardError.new("error\x00with\x01control")
      result = formatter.send(:build_fallback_output, "ERROR", Time.zone.now, "msg", error)
      payload = JSON.parse(result)
      expect(payload["formatter_error"]["message"]).not_to include("\x00")
      expect(payload["formatter_error"]["message"]).not_to include("\x01")
    end

    it "handles errors where message returns nil", :aggregate_failures do
      error = StandardError.new("initial message")
      # Make message return nil explicitly
      allow(error).to receive(:message).and_return(nil)

      # When message is nil, safe_string converts it to ""
      result = formatter.send(:build_fallback_output, "ERROR", Time.zone.now, "msg", error)
      payload = JSON.parse(result)
      expect(payload["formatter_error"]["message"]).to be_a(String)
      expect(payload["formatter_error"]["message"]).to eq("")
    end
  end
end

# rubocop:enable RSpec/MultipleDescribes
RSpec.describe JsonLogging::FormatterWithTags do
  let(:io) { StringIO.new }
  let(:logger) { JsonLogging::JsonLogger.new(io) }
  let(:formatter) { described_class.new(logger) }

  it "delegates current_tags to logger" do
    logger.tagged("TEST") do
      expect(formatter.current_tags).to eq(["TEST"])
    end
  end

  it "includes tags in output" do
    logger.tagged("REQUEST") do
      result = formatter.call("INFO", Time.zone.now, nil, "test")
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
    result = formatter.call("ERROR", Time.zone.now, nil, "test")
    payload = JSON.parse(result)
    expect(payload).to have_key("formatter_error")
  end

  describe "#build_fallback_output" do
    it "creates fallback output with all required fields", :aggregate_failures do
      error = StandardError.new("test error")
      result = formatter.send(:build_fallback_output, "ERROR", Time.zone.now, "test message", error)
      payload = JSON.parse(result)

      expect(payload).to have_key("timestamp")
      expect(payload["severity"]).to eq("ERROR")
      expect(payload["message"]).to eq("test message")
      expect(payload).to have_key("formatter_error")
      expect(payload["formatter_error"]["class"]).to eq("StandardError")
      expect(payload["formatter_error"]["message"]).to include("test error")
    end

    it "handles nil timestamp in fallback", :aggregate_failures do
      error = StandardError.new("error")
      result = formatter.send(:build_fallback_output, "WARN", nil, "msg", error)
      payload = JSON.parse(result)
      expect(payload["timestamp"]).to be_a(String)
      expect(payload["severity"]).to eq("WARN")
    end

    it "handles nil message in fallback" do
      error = StandardError.new("error")
      result = formatter.send(:build_fallback_output, "INFO", Time.zone.now, nil, error)
      payload = JSON.parse(result)
      expect(payload["message"]).to eq("")
    end

    it "sanitizes error message in fallback", :aggregate_failures do
      error = StandardError.new("error\x00with\x01control")
      result = formatter.send(:build_fallback_output, "ERROR", Time.zone.now, "msg", error)
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
      result = formatter.send(:build_fallback_output, "ERROR", Time.zone.now, "msg", error)
      payload = JSON.parse(result)
      expect(payload["formatter_error"]["message"]).to eq("<unprintable>")
    end
  end

  describe "#tagged with LocalTagStorage" do
    let(:logger_with_local_tags) do
      logger = JsonLogging::JsonLogger.new(io)
      logger.formatter.extend(JsonLogging::LocalTagStorage)
      logger
    end
    let(:formatter_with_local_tags) { described_class.new(logger_with_local_tags) }

    it "handles nested tagged blocks correctly" do
      formatter_with_local_tags.tagged("OUTER") do
        formatter_with_local_tags.tagged("INNER") do
          logger_with_local_tags.info("test")
        end
      end
      io.rewind
      line = io.read
      payload = JSON.parse(line)
      expect(payload["tags"]).to eq(["OUTER", "INNER"])
    end

    it "prevents negative array size error when tags are popped elsewhere" do
      formatter_with_local_tags.tagged("TAG1") do
        logger_with_local_tags.formatter.tag_stack.pop_tags(1)
        expect {
          formatter_with_local_tags.tagged("TAG2") do
            logger_with_local_tags.info("test")
          end
        }.not_to raise_error
      end
    end

    it "handles case where current_count is less than previous_count" do
      formatter_with_local_tags.tagged("TAG1", "TAG2") do
        previous_count = logger_with_local_tags.formatter.tag_stack.tags.size
        logger_with_local_tags.formatter.tag_stack.pop_tags(2)
        expect {
          formatter_with_local_tags.tagged("TAG3") do
            logger_with_local_tags.info("test")
          end
        }.not_to raise_error
      end
    end

    it "handles pop_tags with negative count gracefully", :aggregate_failures do
      stack = JsonLogging::LocalTagStorage::LocalTagStack.new
      stack.push_tags(["TAG1", "TAG2"])

      # Should not raise when popping negative count
      expect { stack.pop_tags(-1) }.not_to raise_error
      expect(stack.tags).to eq(["TAG1", "TAG2"]) # Should not change
    end

    it "handles pop_tags with zero count gracefully", :aggregate_failures do
      stack = JsonLogging::LocalTagStorage::LocalTagStack.new
      stack.push_tags(["TAG1", "TAG2"])

      # Should not raise when popping zero
      expect { stack.pop_tags(0) }.not_to raise_error
      expect(stack.tags).to eq(["TAG1", "TAG2"]) # Should not change
    end

    it "handles pop_tags with count greater than available tags", :aggregate_failures do
      stack = JsonLogging::LocalTagStorage::LocalTagStack.new
      stack.push_tags(["TAG1"])

      # Should only pop what's available, not raise error
      result = stack.pop_tags(10)
      expect(result.size).to eq(1)
      expect(stack.tags).to be_empty
    end

    it "handles concurrent tag operations safely" do
      formatter_with_local_tags.tagged("GOOD_JOB", "THREAD_1") do
        # rubocop:disable ThreadSafety/NewThread
        thread = Thread.new do
          formatter_with_local_tags.tagged("NESTED") do
            logger_with_local_tags.info("nested log")
          end
        end
        # rubocop:enable ThreadSafety/NewThread
        thread.join

        logger_with_local_tags.info("main log")
      end

      # Should complete without ArgumentError
      expect(io.string).to include("main log")
    end
  end
end
