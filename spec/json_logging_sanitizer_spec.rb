require "spec_helper"

RSpec.describe JsonLogging::Sanitizer do
  describe ".sanitize_string" do
    it "removes control characters" do
      str = "hello\x00\x01world"
      result = described_class.sanitize_string(str)
      expect(result).to eq("helloworld")
    end

    it "truncates very long strings" do
      long_str = "a" * 15_000
      result = described_class.sanitize_string(long_str)
      expect(result.length).to eq(10_000 + "...[truncated]".length)
      expect(result).to end_with("...[truncated]")
    end

    it "handles non-string input" do
      expect(described_class.sanitize_string(123)).to eq(123)
      expect(described_class.sanitize_string(nil)).to eq(nil)
    end

    it "handles errors gracefully" do
      obj = Object.new
      def obj.is_a?(*)
        raise "error"
      end
      result = described_class.sanitize_string(obj)
      expect(result).to eq("<sanitization_error>")
    end
  end

  describe ".sanitize_hash" do
    it "filters sensitive keys when Rails not available" do
      hash = {password: "secret", username: "user", api_key: "key123"}
      result = described_class.sanitize_hash(hash)
      expect(result).to have_key(:username)
      expect(result).not_to have_key(:password)
      expect(result).not_to have_key(:api_key)
      expect(result).to have_key("password_filtered")
      expect(result).to have_key("api_key_filtered")
    end

    it "limits hash size" do
      large_hash = (1..60).map { |i| ["key#{i}", "value#{i}"] }.to_h
      result = described_class.sanitize_hash(large_hash)
      expect(result.size).to eq(51) # MAX_CONTEXT_SIZE + 1 for _truncated flag
      expect(result).to have_key("_truncated")
    end

    it "prevents excessive nesting" do
      deep_hash = {a: {b: {c: {d: {e: {f: {g: {h: {i: {j: {k: 1}}}}}}}}}}}
      result = described_class.sanitize_hash(deep_hash, depth: 11)
      expect(result).to eq({"error" => "max_depth_exceeded"})
    end

    it "handles errors gracefully" do
      hash = Object.new
      def hash.is_a?(*)
        raise "error"
      end
      result = described_class.sanitize_hash(hash)
      expect(result).to eq({"sanitization_error" => true})
    end
  end

  describe ".sanitize_value" do
    it "handles arrays and truncates large ones" do
      large_array = (1..60).to_a
      result = described_class.sanitize_value(large_array)
      expect(result.size).to eq(51) # MAX_CONTEXT_SIZE + 1 for truncation marker
      expect(result.last).to eq("[truncated]")
    end

    it "handles exceptions" do
      ex = begin
        raise ArgumentError, "test error"
      rescue => e
        e
      end
      result = described_class.sanitize_value(ex)
      expect(result["error"]["class"]).to eq("ArgumentError")
      expect(result["error"]["message"]).to eq("test error")
    end

    it "preserves numeric and boolean types" do
      expect(described_class.sanitize_value(123)).to eq(123)
      expect(described_class.sanitize_value(45.67)).to eq(45.67)
      expect(described_class.sanitize_value(true)).to eq(true)
      expect(described_class.sanitize_value(false)).to eq(false)
      expect(described_class.sanitize_value(nil)).to eq(nil)
    end

    it "converts other types to strings" do
      result = described_class.sanitize_value(Object.new)
      expect(result).to be_a(String)
    end

    it "handles errors gracefully" do
      obj = Object.new
      def obj.to_s
        raise "error"
      end
      result = described_class.sanitize_value(obj)
      expect(result).to eq("<unprintable>")
    end
  end

  describe ".sanitize_exception" do
    it "sanitizes exception with backtrace" do
      ex = begin
        raise "test"
      rescue => e
        e
      end
      result = described_class.sanitize_exception(ex)
      expect(result["error"]["class"]).to eq("RuntimeError")
      expect(result["error"]["message"]).to eq("test")
      expect(result["error"]["backtrace"]).to be_an(Array)
    end

    it "handles exceptions in sanitization" do
      ex = Object.new
      def ex.class
        raise "error"
      end
      result = described_class.sanitize_exception(ex)
      expect(result["error"]["class"]).to eq("Exception")
      expect(result["error"]["message"]).to eq("<sanitization_failed>")
    end
  end

  describe ".sanitize_backtrace" do
    it "sanitizes backtrace array" do
      backtrace = ["line1", "line2", "line3"]
      result = described_class.sanitize_backtrace(backtrace)
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
    end

    it "limits backtrace to 20 lines" do
      long_backtrace = (1..30).map { |i| "line#{i}" }
      result = described_class.sanitize_backtrace(long_backtrace)
      expect(result.size).to eq(20)
    end

    it "handles non-array input" do
      expect(described_class.sanitize_backtrace(nil)).to eq([])
      expect(described_class.sanitize_backtrace("string")).to eq([])
    end

    it "handles errors gracefully" do
      obj = Object.new
      def obj.is_a?(*)
        raise "error"
      end
      result = described_class.sanitize_backtrace(obj)
      expect(result).to eq([])
    end
  end

  describe ".sensitive_key?" do
    it "detects sensitive keys" do
      expect(described_class.sensitive_key?("password")).to be true
      expect(described_class.sensitive_key?("api_key")).to be true
      expect(described_class.sensitive_key?("access_token")).to be true
      expect(described_class.sensitive_key?("username")).to be false
    end
  end

  describe ".rails_parameter_filter" do
    it "returns nil when Rails is not available" do
      # In test environment without Rails loaded
      result = described_class.rails_parameter_filter
      expect(result).to be_nil
    end

    context "when Rails is available" do
      before do
        # Mock Rails if not already defined
        unless defined?(Rails)
          rails_module = Module.new
          rails_app = double("application")
          rails_config = double("config")

          allow(rails_config).to receive(:filter_parameters).and_return([:password, :secret, /token/i])

          allow(rails_app).to receive(:config).and_return(rails_config)
          allow(rails_module).to receive(:application).and_return(rails_app)

          stub_const("Rails", rails_module)
        end
      end

      it "returns ParameterFilter when filter_parameters is configured" do
        skip "ActiveSupport::ParameterFilter not available" unless defined?(ActiveSupport::ParameterFilter)

        # Ensure Rails is set up with filter_parameters
        if defined?(Rails) && Rails.respond_to?(:application)
          Rails.application.config.filter_parameters = [:password, :secret, /token/i]
          result = described_class.rails_parameter_filter
          expect(result).to be_a(ActiveSupport::ParameterFilter)
        else
          skip "Rails.application not properly mocked"
        end
      end

      it "returns nil when filter_parameters is empty" do
        skip "ActiveSupport::ParameterFilter not available" unless defined?(ActiveSupport::ParameterFilter)

        if defined?(Rails) && Rails.respond_to?(:application)
          Rails.application.config.filter_parameters = []
          result = described_class.rails_parameter_filter
          expect(result).to be_nil
        else
          skip "Rails.application not properly mocked"
        end
      end

      it "uses Rails ParameterFilter in sanitize_hash when available" do
        skip "ActiveSupport::ParameterFilter not available" unless defined?(ActiveSupport::ParameterFilter)
        skip "Cannot test without Rails properly configured" unless defined?(Rails) && Rails.respond_to?(:application)

        # Set up Rails filter
        Rails.application.config.filter_parameters = [:password, :secret]

        hash = {password: "secret123", username: "user", api_token: "token123"}
        result = described_class.sanitize_hash(hash)

        # Rails ParameterFilter should filter password and secret
        # The result should have filtered values (Rails filters them to [FILTERED] or similar)
        expect(result).not_to have_key(:password)
        expect(result).to have_key(:username)
        # api_token may or may not be filtered depending on exact filter config
      end

      it "rescue errors and returns nil" do
        if defined?(Rails)
          allow(Rails).to receive(:application).and_raise(StandardError.new("error"))
          result = described_class.rails_parameter_filter
          expect(result).to be_nil
        else
          skip "Rails not available to test error handling"
        end
      end
    end
  end
end
