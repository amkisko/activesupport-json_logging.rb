require "spec_helper"

RSpec.describe JsonLogging do
  describe ".with_context" do
    it "adds and clears context within block" do
      expect(JsonLogging.additional_context).to eq({})
      JsonLogging.with_context(user_id: 42) do
        expect(JsonLogging.additional_context[:user_id]).to eq(42)
      end
      expect(JsonLogging.additional_context).to eq({})
    end

    it "merges context when nested" do
      JsonLogging.with_context(a: 1) do
        JsonLogging.with_context(b: 2) do
          expect(JsonLogging.additional_context).to eq({a: 1, b: 2})
        end
      end
    end

    it "handles non-hash arguments via safe_hash" do
      JsonLogging.with_context(nil) do
        expect(JsonLogging.additional_context).to eq({})
      end

      JsonLogging.with_context("not a hash") do
        expect(JsonLogging.additional_context).to eq({})
      end

      JsonLogging.with_context([]) do
        expect(JsonLogging.additional_context).to eq({})
      end
    end

    it "handles nested context with empty/nil values" do
      JsonLogging.with_context(a: nil, b: "", c: false) do
        expect(JsonLogging.additional_context).to eq({a: nil, b: "", c: false})

        JsonLogging.with_context(d: nil) do
          expect(JsonLogging.additional_context).to include(a: nil, b: "", c: false, d: nil)
        end
      end
    end

    it "handles objects that raise on is_a? check" do
      obj = Object.new
      def obj.is_a?(*)
        raise "error in is_a?"
      end

      # Should not raise and should return empty hash
      result = nil
      JsonLogging.with_context(obj) do
        result = JsonLogging.additional_context
      end
      expect(result).to eq({})
    end
  end

  describe ".additional_context" do
    it "returns empty hash when dup raises an error" do
      # Create a context that will raise on dup
      context_hash = {}
      def context_hash.dup
        raise StandardError.new("dup error")
      end

      # Set context manually using the same key the implementation uses
      key = :__json_logging_context
      Thread.current[key] = context_hash

      # Should rescue and return empty hash
      expect(JsonLogging.additional_context).to eq({})

      # Clean up
      Thread.current[key] = nil
    end

    it "handles context with compact correctly" do
      JsonLogging.with_context(a: 1, b: nil, c: "", d: false) do
        context = JsonLogging.additional_context.compact
        # compact removes nil, but keeps false and empty string
        expect(context).to include(a: 1, c: "", d: false)
        expect(context).not_to have_key(:b)
      end
    end
  end

  describe ".safe_hash" do
    it "returns hash as-is when given a hash" do
      hash = {a: 1, b: 2}
      result = JsonLogging.safe_hash(hash)
      expect(result).to eq({a: 1, b: 2})
    end

    it "returns empty hash for non-hash objects" do
      expect(JsonLogging.safe_hash(nil)).to eq({})
      expect(JsonLogging.safe_hash("string")).to eq({})
      expect(JsonLogging.safe_hash([])).to eq({})
      expect(JsonLogging.safe_hash(123)).to eq({})
    end

    it "handles objects that raise on is_a? check" do
      obj = Object.new
      def obj.is_a?(*)
        raise "error"
      end

      result = JsonLogging.safe_hash(obj)
      expect(result).to eq({})
    end

    it "handles hash-like objects that respond to is_a?" do
      # Even if it responds to is_a?, if it's not actually a Hash, return {}
      obj = double(is_a?: false)
      result = JsonLogging.safe_hash(obj)
      expect(result).to eq({})
    end
  end
end
