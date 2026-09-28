require "spec_helper"
require "stringio"

RSpec.describe JsonLogging, ".max_line_bytes" do
  let(:io) { StringIO.new }
  let(:logger) { described_class.logger(io) }
  let(:formatter) { JsonLogging::Formatter.new }
  let(:oversized_hash) { {path: "/webhooks/events", params: "p" * 6_000, body: "b" * 5_000} }

  around do |example|
    example.run
  ensure
    described_class.max_line_bytes = nil
  end

  def written_lines
    io.rewind
    io.readlines
  end

  it "leaves lines uncapped by default", :aggregate_failures do
    line = formatter.call("INFO", Time.utc(2020, 1, 1), nil, oversized_hash)

    expect(described_class.max_line_bytes).to be_nil
    expect(line.bytesize).to be > 11_000
    expect(JSON.parse(line)).not_to have_key("truncated")
  end

  it "rejects a budget too small to hold the overflow notice", :aggregate_failures do
    expect { described_class.max_line_bytes = 100 }.to raise_error(ArgumentError, /at least 256/)
    expect { described_class.max_line_bytes = "9500" }.to raise_error(ArgumentError)
    expect(described_class.max_line_bytes).to be_nil
  end

  context "when set" do
    before { described_class.max_line_bytes = 1_000 }

    it "shrinks the longest strings so the formatter line stays valid JSON within budget", :aggregate_failures do
      line = formatter.call("WARN", Time.utc(2020, 1, 1), nil, oversized_hash)
      payload = JSON.parse(line)

      expect(line).to end_with("\n")
      expect(line.chomp.bytesize).to be <= 1_000
      expect(payload).to include("path" => "/webhooks/events", "severity" => "WARN", "truncated" => true)
      expect(payload["params"]).to end_with("...[truncated]")
    end

    it "caps lines written through the logger", :aggregate_failures do
      logger.info(oversized_hash)
      lines = written_lines

      expect(lines.size).to eq(1)
      expect(lines.first.chomp.bytesize).to be <= 1_000
      expect(JSON.parse(lines.first)).to include("path" => "/webhooks/events", "truncated" => true)
    end

    it "caps plain string messages", :aggregate_failures do
      logger.error("x" * 5_000)
      payload = JSON.parse(written_lines.first)

      expect(written_lines.first.chomp.bytesize).to be <= 1_000
      expect(payload).to include("severity" => "ERROR", "truncated" => true)
      expect(payload["message"]).to start_with("xxx")
    end

    it "caps event subscriber lines", :aggregate_failures do
      JsonLogging::EventSubscriber.new(io: io).emit({name: "webhook.received", payload: oversized_hash, tags: {}, context: {}, timestamp: 1})
      line = written_lines.first

      expect(line.chomp.bytesize).to be <= 1_000
      expect(JSON.parse(line)).to include("name" => "webhook.received", "truncated" => true)
    end

    it "keeps multibyte text valid when cutting inside a character", :aggregate_failures do
      logger.info({note: "x#{"ä" * 3_000}"})
      line = written_lines.first

      expect(line.chomp.bytesize).to be <= 1_000
      expect(line).to be_valid_encoding
      expect(JSON.parse(line)["note"]).to match(/\Axä+\.\.\.\[truncated\]\z/)
    end

    it "replaces a line with no string long enough to shrink by an overflow notice", :aggregate_failures do
      logger.warn({ids: (1..1_000).to_a})
      payload = JSON.parse(written_lines.first)

      expect(payload.keys).to contain_exactly("severity", "timestamp", "truncated", "message")
      expect(payload).to include("severity" => "WARN", "message" => "log line exceeded 1000 bytes")
    end

    it "leaves lines within budget unchanged" do
      line = formatter.call("INFO", Time.utc(2020, 1, 1), nil, {path: "/health"})

      expect(JSON.parse(line)).not_to have_key("truncated")
    end
  end
end
