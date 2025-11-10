require "spec_helper"
require "stringio"

RSpec.describe JsonLogging::JsonLogger do
  let(:io) { StringIO.new }
  let(:logger) { described_class.new(io) }

  it "writes single-line JSON per call" do
    logger.info("hello")
    io.rewind
    line = io.gets
    expect { JSON.parse(line) }.not_to raise_error
    expect(io.gets).to be_nil
  end

  it "includes context when present" do
    JsonLogging.with_context(user_id: 5) { logger.info("x") }
    io.rewind
    payload = JSON.parse(io.gets)
    expect(payload.dig("context", "user_id")).to eq(5)
  end

  it "supports tagged logging" do
    logger.tagged("REQUEST", "123") do
      logger.info("test")
    end
    io.rewind
    payload = JSON.parse(io.gets)
    expect(payload["tags"]).to eq(["REQUEST", "123"])
  end

  it "supports nested tags" do
    logger.tagged("OUTER") do
      logger.tagged("INNER") do
        logger.info("test")
      end
    end
    io.rewind
    payload = JSON.parse(io.gets)
    expect(payload["tags"]).to eq(["OUTER", "INNER"])
  end

  it "merges tags with context" do
    JsonLogging.with_context(user_id: 42) do
      logger.tagged("REQUEST") do
        logger.info("test")
      end
    end
    io.rewind
    payload = JSON.parse(io.gets)
    expect(payload.dig("context", "user_id")).to eq(42)
    expect(payload["tags"]).to eq(["REQUEST"])
  end

  it "supports service-specific tagged loggers (tagged without block)" do
    # Create a service-specific logger with permanent tags
    dotenv_logger = logger.tagged("dotenv")

    # All logs from this logger should include the tag
    dotenv_logger.info("Loading .env file")
    dotenv_logger.warn("Missing .env.local file")
    dotenv_logger.error("Invalid environment variable")

    io.rewind
    lines = io.readlines
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
    redis_logger = logger.tagged("redis")
    sidekiq_logger = logger.tagged("sidekiq")
    api_logger = logger.tagged("api")

    redis_logger.info("Connected to Redis")
    sidekiq_logger.info("Job enqueued")
    api_logger.info("Request received")

    io.rewind
    lines = io.readlines
    expect(lines.length).to eq(3)

    payloads = lines.map { |line| JSON.parse(line) }
    tags = payloads.map { |p| p["tags"] }
    expect(tags).to contain_exactly(["redis"], ["sidekiq"], ["api"])
  end

  it "allows nested tags on service loggers" do
    dotenv_logger = logger.tagged("dotenv")

    # Service logger can still use additional tags
    dotenv_logger.tagged("production") do
      dotenv_logger.info("Loading production env")
    end

    io.rewind
    payload = JSON.parse(io.gets)
    expect(payload["tags"]).to eq(["dotenv", "production"])
  end

  it "ignores tags key from user context - tags are at root level, separate from context" do
    # User context should not be able to set tags - tags are system-controlled at root level
    JsonLogging.with_context(tags: ["USER_TAG"], user_id: 42) do
      logger.tagged("SYSTEM_TAG") do
        logger.info("test")
      end
    end
    io.rewind
    payload = JSON.parse(io.gets)
    # Only system tags should appear at root level
    expect(payload["tags"]).to eq(["SYSTEM_TAG"])
    expect(payload.dig("context", "user_id")).to eq(42)
    # User's tags key should not appear in context
    expect(payload["context"].keys).to match_array(["user_id"])
  end

  it "handles hash messages" do
    logger.info({event: "test", value: 123})
    io.rewind
    payload = JSON.parse(io.gets)
    expect(payload["event"]).to eq("test")
    expect(payload["value"]).to eq(123)
  end

  it "never raises from add method" do
    # Test that even problematic objects get logged safely
    # The sanitizer converts objects to strings, so JSON serialization succeeds
    bad_obj = Object.new
    def bad_obj.to_json
      raise "bad"
    end

    # Should not raise - sanitization handles it
    expect { logger.info(bad_obj) }.not_to raise_error

    io.rewind
    payload = JSON.parse(io.gets)

    # Should have logged something (even if sanitized)
    expect(payload).to have_key("severity")
    expect(payload).to have_key("timestamp")

    # Test circular reference (depth limiting handles it)
    circular = {a: 1}
    circular[:self] = circular

    expect { logger.info(circular) }.not_to raise_error
    io.rewind
    io.gets # Skip first entry
    payload2 = JSON.parse(io.gets)
    # Should have logged successfully (depth limit applied)
    expect(payload2).to have_key("severity")
    expect(payload2).to have_key("timestamp")
  end

  describe "tag edge cases" do
    it "handles empty tag arrays after flattening/compacting" do
      logger.tagged([]) do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      # Empty tags should not appear
      expect(payload["tags"]).to be_nil
    end

    it "handles tags with only empty strings and nil" do
      logger.tagged("", nil, "", []) do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      # All tags filtered out, so no tags
      expect(payload["tags"]).to be_nil
    end

    it "handles tags with special characters" do
      logger.tagged("tag-with-dashes", "tag_with_underscores", "tag.with.dots") do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["tags"]).to eq(["tag-with-dashes", "tag_with_underscores", "tag.with.dots"])
    end

    it "sanitizes tags with control characters" do
      logger.tagged("tag\x00with\x01control") do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      tags = payload["tags"]
      expect(tags).to be_an(Array)
      # Control characters should be removed by sanitizer
      expect(tags.first).not_to include("\x00")
      expect(tags.first).not_to include("\x01")
    end

    it "handles very large tag arrays" do
      large_tags = (1..100).map { |i| "TAG#{i}" }
      logger.tagged(*large_tags) do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      tags = payload["tags"]
      expect(tags.length).to eq(100)
      expect(tags).to include("TAG1", "TAG50", "TAG100")
    end

    it "handles Unicode characters in tags" do
      logger.tagged("tag-中文", "tag-🎉", "tag-Русский") do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      tags = payload["tags"]
      expect(tags).to include("tag-中文", "tag-🎉", "tag-Русский")
    end

    it "handles numeric tags" do
      logger.tagged(123, 456.789) do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      tags = payload["tags"]
      expect(tags).to eq(["123", "456.789"])
    end

    it "handles boolean tags" do
      logger.tagged(true, false) do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      tags = payload["tags"]
      expect(tags).to eq(["true", "false"])
    end
  end
end
