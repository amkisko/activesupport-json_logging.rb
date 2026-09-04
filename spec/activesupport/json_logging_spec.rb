require "spec_helper"
require "activesupport/json_logging"
require "stringio"

RSpec.describe JsonLogging::JsonLogger do
  it "writes a single JSON log line through the gem entry", :aggregate_failures do
    io = StringIO.new
    logger = described_class.new(io)
    logger.info("public-entry")
    payload = JSON.parse(io.string.lines.first)

    expect(payload["message"]).to eq("public-entry")
    expect(payload["severity"]).to eq("INFO")
    expect(io.string.lines.size).to eq(1)
  end
end
