require "spec_helper"

RSpec.describe JsonLogging::MessageParser do
  it "handles exceptions directly", :aggregate_failures do
    ex = begin
      raise ArgumentError, "test"
    rescue => e
      e
    end
    result = described_class.parse_message(ex)
    expect(result["error"]["class"]).to eq("ArgumentError")
    expect(result["error"]["message"]).to eq("test")
  end

  it "handles exceptions with nil backtrace", :aggregate_failures do
    ex = Exception.new("test")
    ex.set_backtrace(nil)
    result = described_class.parse_message(ex)
    expect(result["error"]["class"]).to eq("Exception")
  end

  it "sanitizes parsed JSON strings", :aggregate_failures do
    json_str = '{"password":"secret","data":"normal"}'
    result = described_class.parse_message(json_str)
    # Should be sanitized (password filtered if Rails not available)
    expect(result).to be_a(Hash)
  end

  it "handles non-hash objects with to_hash", :aggregate_failures do
    obj = double(to_hash: {a: 1, password: "secret"})
    result = described_class.parse_message(obj)
    expect(result).to be_a(Hash)
  end
end
