require "spec_helper"

RSpec.describe JsonLogging::PayloadBuilder do
  describe ".build_base_payload" do
    it "wraps strings in message key" do
      payload = described_class.build_base_payload("hello")
      expect(payload[:message]).to eq("hello")
    end

    it "merges hash messages into payload" do
      payload = described_class.build_base_payload({event: "test"})
      expect(payload[:event]).to eq("test")
      expect(payload[:message]).to be_nil
    end

    it "includes severity when provided" do
      payload = described_class.build_base_payload("test", severity: "INFO")
      expect(payload[:severity]).to eq("INFO")
    end

    it "includes timestamp when provided" do
      ts = "2020-01-01T00:00:00.000Z"
      payload = described_class.build_base_payload("test", timestamp: ts)
      expect(payload[:timestamp]).to eq(ts)
    end
  end

  describe ".merge_context" do
    it "adds context to payload" do
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {user_id: 5}, tags: [])
      expect(result[:context][:user_id]).to eq(5)
    end

    it "includes tags in context" do
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {}, tags: ["REQUEST", "123"])
      expect(result[:context][:tags]).to eq(["REQUEST", "123"])
    end

    it "merges existing context" do
      payload = {context: {user_id: 5}, message: "test"}
      result = described_class.merge_context(payload, additional_context: {request_id: "abc"}, tags: [])
      expect(result[:context][:user_id]).to eq(5)
      expect(result[:context][:request_id]).to eq("abc")
    end

    it "does not override top-level keys with context" do
      payload = {message: "test", user_id: 10}
      result = described_class.merge_context(payload, additional_context: {user_id: 5}, tags: [])
      expect(result[:user_id]).to eq(10) # original value preserved
      expect(result[:context]).to be_nil # user_id is in top-level, so context doesn't get it
    end

    it "merges tags arrays" do
      payload = {context: {tags: ["A"]}, message: "test"}
      result = described_class.merge_context(payload, additional_context: {}, tags: ["B"])
      expect(result[:context][:tags]).to eq(["A", "B"])
    end
  end
end
