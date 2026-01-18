require "spec_helper"

RSpec.describe JsonLogging::MessageParser do
  it "returns hash as-is", :aggregate_failures do
    expect(described_class.parse_message({foo: "bar"})).to eq({foo: "bar"})
  end

  it "converts objects with to_hash", :aggregate_failures do
    obj = double(to_hash: {a: 1})
    expect(described_class.parse_message(obj)).to eq({a: 1})
  end

  it "parses JSON strings", :aggregate_failures do
    expect(described_class.parse_message('{"x":1}')).to eq({"x" => 1})
  end

  it "returns string if JSON parse fails", :aggregate_failures do
    expect(described_class.parse_message('{"invalid":}')).to eq('{"invalid":}')
  end

  it "returns non-JSON strings as-is", :aggregate_failures do
    expect(described_class.parse_message("plain text")).to eq("plain text")
  end

  it "handles arrays", :aggregate_failures do
    expect(described_class.parse_message("[1,2,3]")).to eq([1, 2, 3])
  end

  describe ".json_string?" do
    # Test json_string? indirectly through parse_message behavior
    # JSON strings are parsed, while non-JSON strings are passed through
    it "identifies JSON object strings starting with { and ending with }", :aggregate_failures do
      # These should be parsed as JSON
      expect(described_class.parse_message('{"key":"value"}')).to be_a(Hash)
      expect(described_class.parse_message("{}")).to be_a(Hash)
      expect(described_class.parse_message('{"nested":{"deep":true}}')).to be_a(Hash)
    end

    it "identifies JSON array strings starting with [ and ending with ]", :aggregate_failures do
      # These should be parsed as JSON arrays
      expect(described_class.parse_message("[1,2,3]")).to be_a(Array)
      expect(described_class.parse_message("[]")).to be_a(Array)
      expect(described_class.parse_message('[{"a":1}]')).to be_a(Array)
    end

    it "does not identify strings that start with { but don't end with }", :aggregate_failures do
      # These should NOT be parsed as JSON
      result = described_class.parse_message('{"incomplete')
      expect(result).to be_a(String)
      expect(result).to eq('{"incomplete')
    end

    it "does not identify strings that end with } but don't start with {", :aggregate_failures do
      result = described_class.parse_message("incomplete}")
      expect(result).to be_a(String)
      expect(result).to eq("incomplete}")
    end

    it "does not identify strings that start with [ but don't end with ]", :aggregate_failures do
      result = described_class.parse_message("[incomplete")
      expect(result).to be_a(String)
      expect(result).to eq("[incomplete")
    end

    it "does not identify strings that end with ] but don't start with [", :aggregate_failures do
      result = described_class.parse_message("incomplete]")
      expect(result).to be_a(String)
      expect(result).to eq("incomplete]")
    end

    it "handles JSON strings with whitespace", :aggregate_failures do
      # JSON.parse handles whitespace correctly
      result = described_class.parse_message('{"key":"value"}')
      expect(result).to be_a(Hash)

      # However, strings that have whitespace at the start won't match start_with?
      # So they won't be treated as JSON strings by json_string?
      result2 = described_class.parse_message(' {"key":"value"} ')
      # This won't match start_with("{"), so it's treated as a plain string
      expect(result2).to be_a(String)
    end

    it "does not treat strings containing { or } as JSON", :aggregate_failures do
      expect(described_class.parse_message("some { text } here")).to be_a(String)
      expect(described_class.parse_message("some [ text ] here")).to be_a(String)
      expect(described_class.parse_message("prefix{key:value}suffix")).to be_a(String)
    end
  end
end
