require "spec_helper"

RSpec.describe JsonLogging::PayloadBuilder do
  describe ".merge_context" do
    it "handles non-hash additional_context" do
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: nil, tags: [])
      expect(result[:message]).to eq("test")
    end

    it "handles empty additional_context" do
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {}, tags: [])
      expect(result[:message]).to eq("test")
    end

    it "handles empty tags" do
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {}, tags: [])
      expect(result[:context]).to be_nil
    end

    it "sanitizes tag values" do
      payload = {message: "test"}
      result = described_class.merge_context(payload, additional_context: {}, tags: ["tag\x00with\x01control"])
      expect(result.dig(:context, :tags).first).not_to include("\x00")
    end
  end

  describe ".build_base_payload" do
    it "handles nil message" do
      result = described_class.build_base_payload(nil)
      expect(result[:message]).to be_nil
    end

    it "handles empty string message" do
      result = described_class.build_base_payload("")
      expect(result[:message]).to eq("")
    end
  end
end
