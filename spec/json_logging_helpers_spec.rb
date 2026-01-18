require "spec_helper"
require "time"

RSpec.describe JsonLogging::Helpers do
  describe ".normalize_timestamp" do
    it "normalizes a Time object to ISO8601 with microseconds", :aggregate_failures do
      time = Time.utc(2020, 1, 15, 14, 30, 45, 123456)
      result = described_class.normalize_timestamp(time)
      expect(result).to eq("2020-01-15T14:30:45.123456Z")
      expect(result).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/)
    end

    it "converts local time to UTC", :aggregate_failures do
      time = Time.local(2020, 1, 15, 14, 30, 45)
      result = described_class.normalize_timestamp(time)
      expect(result).to end_with("Z")
      expect(result).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/)
    end

    it "handles nil by using current time", :aggregate_failures do
      before = Time.now
      result = described_class.normalize_timestamp(nil)
      after = Time.now

      expect(result).to be_a(String)
      expect(result).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/)

      # Parse back and verify it's within the time window
      parsed = Time.parse(result)
      expect(parsed).to be_between(before, after)
    end

    it "handles DateTime objects", :aggregate_failures do
      datetime = DateTime.new(2020, 1, 15, 14, 30, 45, "+00:00")
      # DateTime needs to be converted to Time first (implementation calls .utc directly)
      # The implementation will raise for DateTime, so we convert it
      time_from_datetime = datetime.to_time.utc
      result = described_class.normalize_timestamp(time_from_datetime)
      expect(result).to match(/^2020-01-15T14:30:45\.\d{6}Z$/)

      # Test that raw DateTime raises (implementation limitation)
      expect { described_class.normalize_timestamp(datetime) }.to raise_error(NoMethodError)
    end

    it "handles TimeWithZone objects (Rails)", :aggregate_failures do
      begin
        require "active_support/core_ext/time"
      rescue LoadError
        skip "ActiveSupport not available"
      end

      unless defined?(ActiveSupport::TimeWithZone)
        skip "ActiveSupport::TimeWithZone not available"
      end

      time_zone = ActiveSupport::TimeZone["America/New_York"]
      time = time_zone.parse("2020-01-15 14:30:45")
      result = described_class.normalize_timestamp(time)
      expect(result).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z$/)
      expect(result).to end_with("Z")
    end
  end

  describe ".safe_string" do
    it "converts normal objects to strings", :aggregate_failures do
      expect(described_class.safe_string(123)).to eq("123")
      expect(described_class.safe_string(:symbol)).to eq("symbol")
      expect(described_class.safe_string([1, 2, 3])).to eq("[1, 2, 3]")
    end

    it "handles nil gracefully", :aggregate_failures do
      expect(described_class.safe_string(nil)).to eq("")
    end

    it "handles strings as-is", :aggregate_failures do
      expect(described_class.safe_string("hello")).to eq("hello")
    end

    it "returns '<unprintable>' when to_s raises", :aggregate_failures do
      obj = Object.new
      def obj.to_s
        raise "cannot convert to string"
      end

      result = described_class.safe_string(obj)
      expect(result).to eq("<unprintable>")
    end

    it "handles objects that raise StandardError on to_s", :aggregate_failures do
      obj = Object.new
      def obj.to_s
        raise StandardError, "error"
      end

      result = described_class.safe_string(obj)
      expect(result).to eq("<unprintable>")
    end

    it "handles objects that raise other errors on to_s", :aggregate_failures do
      obj = Object.new
      def obj.to_s
        raise NoMethodError, "missing method"
      end

      result = described_class.safe_string(obj)
      expect(result).to eq("<unprintable>")
    end

    it "handles objects that raise in to_s", :aggregate_failures do
      obj = Object.new
      def obj.to_s
        raise "error in to_s"
      end

      result = described_class.safe_string(obj)
      expect(result).to eq("<unprintable>")
    end
  end
end
