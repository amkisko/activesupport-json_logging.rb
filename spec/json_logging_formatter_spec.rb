require "spec_helper"

RSpec.describe JsonLogging::Formatter do
  let(:formatter) { described_class.new }

  it "serializes simple string messages", :aggregate_failures do
    line = formatter.call("INFO", Time.utc(2020, 1, 1), nil, "hello")
    payload = JSON.parse(line)
    expect(payload["message"]).to eq("hello")
    expect(payload["severity"]).to eq("INFO")
  end

  it "serializes hashes as-is (without message wrapper)", :aggregate_failures do
    line = formatter.call("WARN", Time.utc(2020, 1, 1), nil, {foo: "bar"})
    payload = JSON.parse(line)
    expect(payload["foo"]).to eq("bar")
    expect(payload["severity"]).to eq("WARN")
  end

  it "handles JSON string messages", :aggregate_failures do
    json_msg = '{"event":"test","value":123}'
    line = formatter.call("INFO", Time.utc(2020, 1, 1), nil, json_msg)
    payload = JSON.parse(line)
    expect(payload["event"]).to eq("test")
    expect(payload["value"]).to eq(123)
  end

  it "never raises on unprintable objects", :aggregate_failures do
    obj = Object.new
    def obj.to_s
      raise "nope"
    end
    line = formatter.call("INFO", Time.utc(2020, 1, 1), nil, obj)
    payload = JSON.parse(line)
    expect(payload["message"]).to eq("<unprintable>")
  end
end
