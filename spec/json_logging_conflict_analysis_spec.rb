require "spec_helper"

RSpec.describe JsonLogging::PayloadBuilder do
  let(:io) { StringIO.new }
  let(:logger) { JsonLogging::JsonLogger.new(io) }

  describe "System-controlled fields" do
    # System-controlled fields: severity, timestamp, tags, message
    # User should not be able to override these via context
    it "system overrides severity from message payload", :aggregate_failures do
      logger.info({severity: "CUSTOM", event: "test"})
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["severity"]).to eq("INFO") # System value
      expect(payload["event"]).to eq("test")
    end

    it "system overrides timestamp from message payload", :aggregate_failures do
      custom_time = "2020-01-01T00:00:00.000000Z"
      logger.info({timestamp: custom_time, event: "test"})
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["timestamp"]).not_to eq(custom_time) # System value
      expect(payload["event"]).to eq("test")
    end

    it "user context cannot override severity", :aggregate_failures do
      JsonLogging.with_context(severity: "CUSTOM") do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["severity"]).to eq("INFO") # System value
      expect(payload["context"]).to be_nil # severity filtered out
    end

    it "user context cannot override timestamp", :aggregate_failures do
      JsonLogging.with_context(timestamp: "2020-01-01T00:00:00.000000Z") do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["timestamp"]).not_to eq("2020-01-01T00:00:00.000000Z") # System value
      expect(payload["context"]).to be_nil # timestamp filtered out
    end

    it "user context cannot override message if it exists in payload", :aggregate_failures do
      JsonLogging.with_context(message: "OVERRIDE") do
        logger.info("original")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["message"]).to eq("original") # Payload value preserved
      expect(payload["context"]).to be_nil # message filtered out
    end

    it "user context cannot override tags", :aggregate_failures do
      JsonLogging.with_context(tags: ["USER_TAG"]) do
        logger.tagged("SYSTEM_TAG") do
          logger.info("test")
        end
      end
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["tags"]).to eq(["SYSTEM_TAG"]) # System value
      expect(payload["context"]).to be_nil # tags filtered out
    end

    it "user context cannot override context key", :aggregate_failures do
      JsonLogging.with_context(context: {nested: "value"}) do
        logger.info("test")
      end
      io.rewind
      payload = JSON.parse(io.gets)
      # context key should be filtered out from user context
      expect(payload["context"]).to be_nil
    end
  end

  describe "Edge cases" do
    it "user logging hash with all system keys", :aggregate_failures do
      logger.info({
        severity: "CUSTOM",
        timestamp: "2020-01-01T00:00:00.000000Z",
        tags: ["CUSTOM_TAG"],
        message: "hash message",
        context: {from_hash: true},
        user_data: "preserved"
      })
      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["severity"]).to eq("INFO") # System override
      expect(payload["timestamp"]).not_to eq("2020-01-01T00:00:00.000000Z") # System override
      expect(payload["tags"]).to eq(["CUSTOM_TAG"]) # Merged (allowed from message)
      expect(payload["message"]).to eq("hash message") # From hash
      expect(payload.dig("context", "from_hash")).to be(true) # Merged
      expect(payload["user_data"]).to eq("preserved") # Preserved
    end
  end
end
