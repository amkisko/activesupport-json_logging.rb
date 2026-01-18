require "spec_helper"

RSpec.describe JsonLogging::PayloadBuilder do
  describe ".build_base_payload" do
    it "wraps strings in message key", :aggregate_failures do
      payload = described_class.build_base_payload("hello")
      expect(payload[:message]).to eq("hello")
    end

    it "merges hash messages into payload", :aggregate_failures do
      payload = described_class.build_base_payload({event: "test"})
      expect(payload[:event]).to eq("test")
      expect(payload[:message]).to be_nil
    end

    it "includes severity when provided", :aggregate_failures do
      payload = described_class.build_base_payload("test", severity: "INFO")
      expect(payload[:severity]).to eq("INFO")
    end

    it "includes timestamp when provided", :aggregate_failures do
      ts = "2020-01-01T00:00:00.000Z"
      payload = described_class.build_base_payload("test", timestamp: ts)
      expect(payload[:timestamp]).to eq(ts)
    end
  end

  describe ".merge_context" do
    it "adds context to payload", :aggregate_failures do
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {user_id: 5}, tags: [])
      expect(result[:context][:user_id]).to eq(5)
    end

    it "includes tags at root level", :aggregate_failures do
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {}, tags: ["REQUEST", "123"])
      expect(result[:tags]).to eq(["REQUEST", "123"])
      expect(result[:context]).to be_nil
    end

    it "merges existing context", :aggregate_failures do
      payload = {context: {user_id: 5}, message: "test"}
      result = described_class.merge_context(payload, additional_context: {request_id: "abc"}, tags: [])
      expect(result[:context][:user_id]).to eq(5)
      expect(result[:context][:request_id]).to eq("abc")
    end

    it "does not override top-level keys with context", :aggregate_failures do
      payload = {message: "test", user_id: 10}
      result = described_class.merge_context(payload, additional_context: {user_id: 5}, tags: [])
      expect(result[:user_id]).to eq(10) # original value preserved
      expect(result[:context]).to be_nil # user_id is in top-level, so context doesn't get it
    end

    it "merges tags arrays from payload root", :aggregate_failures do
      # Tags from message payload (e.g., logging a hash with tags: [...] at root)
      payload = {tags: ["A"], message: "test"}
      result = described_class.merge_context(payload, additional_context: {}, tags: ["B"])
      expect(result[:tags]).to eq(["A", "B"])
    end

    it "ignores tags key from user context - tags are at root level, separate from context", :aggregate_failures do
      # User context should not be able to set tags - tags are system-controlled at root level
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {tags: ["USER_TAG"], user_id: 5}, tags: ["SYSTEM_TAG"])
      # Only system tags should appear at root level
      expect(result[:tags]).to eq(["SYSTEM_TAG"])
      expect(result[:context][:user_id]).to eq(5)
      # User's tags key should not appear in context
      expect(result[:context].keys).to contain_exactly(:user_id)
    end

    it "only uses logger tags when user context has tags key", :aggregate_failures do
      # Even if user context has tags, only logger tags should be used at root level
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {tags: ["IGNORED"]}, tags: ["LOGGER_TAG"])
      expect(result[:tags]).to eq(["LOGGER_TAG"])
      expect(result[:context]).to be_nil
    end

    it "ignores tags key from user context even when using string keys", :aggregate_failures do
      # Handle both symbol and string keys
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {"tags" => ["IGNORED"], "user_id" => 5}, tags: ["SYSTEM_TAG"])
      expect(result[:tags]).to eq(["SYSTEM_TAG"])
      # Context may have string or symbol keys depending on sanitization
      user_id_value = result[:context][:user_id] || result[:context]["user_id"]
      expect(user_id_value).to eq(5)
    end
  end
end
