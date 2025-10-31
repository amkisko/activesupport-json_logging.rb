require "spec_helper"
require "benchmark"
require "stringio"
require "active_support/logger"

# Performance benchmarks comparing JsonLogging with standard Rails logger
RSpec.describe "Performance benchmarks", :benchmark do
  let(:iterations) { 10_000 }
  let(:io) { StringIO.new }

  describe "logging performance" do
    it "compares JsonLogger with ActiveSupport::Logger for simple messages" do
      json_logger = JsonLogging::JsonLogger.new(io.dup)
      std_logger = ActiveSupport::Logger.new(io.dup)

      json_time = Benchmark.realtime do
        iterations.times do |i|
          json_logger.info("Test message #{i}")
        end
      end

      std_time = Benchmark.realtime do
        iterations.times do |i|
          std_logger.info("Test message #{i}")
        end
      end

      overhead = ((json_time / std_time - 1) * 100).round(2)
      puts "\n  Simple messages (#{iterations} iterations):"
      puts "    JsonLogger:  #{json_time.round(4)}s"
      puts "    Std Logger:  #{std_time.round(4)}s"
      puts "    Overhead:    #{overhead}%"

      # JSON logging overhead is acceptable (JSON serialization adds overhead)
      # Typical overhead: 300-400% for structured logging is reasonable
      # Absolute time per log: ~0.005-0.008ms (negligible compared to I/O)
      # In real apps, I/O dominates (1-10ms disk, 5-50ms network), making this < 1% of total time
      expect(overhead).to be < 500
    end

    it "compares JsonLogger with ActiveSupport::Logger for hash messages" do
      json_logger = JsonLogging::JsonLogger.new(io.dup)
      std_logger = ActiveSupport::Logger.new(io.dup)

      json_time = Benchmark.realtime do
        iterations.times do |i|
          json_logger.info({event: "test", value: i, timestamp: Time.now.iso8601})
        end
      end

      std_time = Benchmark.realtime do
        iterations.times do |i|
          std_logger.info("event=test value=#{i} timestamp=#{Time.now.iso8601}")
        end
      end

      overhead = ((json_time / std_time - 1) * 100).round(2)
      puts "\n  Hash messages (#{iterations} iterations):"
      puts "    JsonLogger:  #{json_time.round(4)}s"
      puts "    Std Logger:  #{std_time.round(4)}s"
      puts "    Overhead:    #{overhead}%"

      # JSON formatting of hashes should be reasonable
      # Typical overhead: 250-300% is normal for structured JSON logging
      # This includes hash serialization, timestamp formatting, and payload building
      expect(overhead).to be < 300
    end

    it "measures tagged logging performance" do
      json_logger = JsonLogging::JsonLogger.new(io.dup)

      tagged_time = Benchmark.realtime do
        iterations.times do |i|
          json_logger.tagged("TAG_#{i}") do
            json_logger.info("Tagged message")
          end
        end
      end

      untagged_time = Benchmark.realtime do
        iterations.times do |i|
          json_logger.info("Untagged message")
        end
      end

      overhead = ((tagged_time / untagged_time - 1) * 100).round(2)
      puts "\n  Tagged logging (#{iterations} iterations):"
      puts "    Tagged:    #{tagged_time.round(4)}s"
      puts "    Untagged:  #{untagged_time.round(4)}s"
      puts "    Overhead:  #{overhead}%"

      # Tagging adds some overhead (thread-local storage, context merging)
      # Typical overhead: 60-70% is reasonable
      expect(overhead).to be < 100
    end

    it "measures context performance" do
      json_logger = JsonLogging::JsonLogger.new(io.dup)

      with_context_time = Benchmark.realtime do
        iterations.times do |i|
          JsonLogging.with_context(user_id: i, request_id: "req-#{i}") do
            json_logger.info("Message with context")
          end
        end
      end

      without_context_time = Benchmark.realtime do
        iterations.times do |i|
          json_logger.info("Message without context")
        end
      end

      overhead = ((with_context_time / without_context_time - 1) * 100).round(2)
      puts "\n  Context (#{iterations} iterations):"
      puts "    With context:    #{with_context_time.round(4)}s"
      puts "    Without context: #{without_context_time.round(4)}s"
      puts "    Overhead:        #{overhead}%"

      # Context should add minimal overhead (< 100%)
      expect(overhead).to be < 100
    end

    it "measures sanitization overhead" do
      json_logger = JsonLogging::JsonLogger.new(io.dup)

      # Large hash with nested structures
      large_hash = {
        user: {
          id: 123,
          email: "test@example.com",
          profile: {
            name: "Test User",
            bio: "A" * 1000,  # Long string
            preferences: (1..50).map { |i| ["pref_#{i}", "value_#{i}"] }.to_h
          }
        },
        request: {
          path: "/api/users",
          params: (1..20).map { |i| ["param_#{i}", "value_#{i}"] }.to_h
        }
      }

      sanitized_time = Benchmark.realtime do
        (iterations / 10).times do
          json_logger.info(large_hash)
        end
      end

      # Simple message for comparison
      simple_time = Benchmark.realtime do
        (iterations / 10).times do
          json_logger.info("Simple message")
        end
      end

      overhead = ((sanitized_time / simple_time - 1) * 100).round(2)
      # Calculate message size in KB
      large_hash_size_kb = (large_hash.to_json.bytesize / 1024.0).round(2)
      simple_msg_size_kb = ("Simple message".bytesize / 1024.0).round(2)

      puts "\n  Sanitization (#{iterations / 10} iterations):"
      puts "    Large hash (#{large_hash_size_kb}KB): #{sanitized_time.round(4)}s"
      puts "    Simple (#{simple_msg_size_kb}KB):     #{simple_time.round(4)}s"
      puts "    Overhead:   #{overhead}%"

      # Sanitization of large nested structures has overhead (deep_dup, filtering, etc.)
      # For large structures, 1000-1500% overhead is expected and acceptable
      expect(overhead).to be < 2000
    end

    it "measures memory allocations" do
      require "memory_profiler"

      json_logger = JsonLogging::JsonLogger.new(io.dup)

      report = MemoryProfiler.report do
        iterations.times do |i|
          json_logger.info({event: "test", value: i})
        end
      end

      total_allocated = report.total_allocated_memsize
      total_retained = report.total_retained_memsize
      objects_allocated = report.total_allocated

      puts "\n  Memory allocations (#{iterations} iterations):"
      puts "    Total allocated: #{total_allocated / 1024}KB (#{objects_allocated} objects)"
      puts "    Total retained:  #{total_retained / 1024}KB"
      puts "    Avg per log:     #{(total_allocated / iterations / 1024.0).round(2)}KB"
      puts "    Objects per log: #{(objects_allocated / iterations.to_f).round(2)}"

      # JSON serialization, string operations, hash operations, and sanitization allocate memory
      # Typical allocation: ~3KB per log entry is reasonable for structured JSON logging
      # This includes: JSON string building, hash merging, string sanitization, timestamp formatting
      expect(total_allocated / iterations).to be < 4096 # 4KB per entry threshold

      # Should not retain excessive memory (most allocations should be garbage collected)
      # Retained memory is minimal since we write to StringIO and don't keep references
      expect(total_retained / iterations).to be < 1024 # 1KB per entry threshold
    end
  end
end
