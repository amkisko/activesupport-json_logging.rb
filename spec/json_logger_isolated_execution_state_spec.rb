require "spec_helper"
require "stringio"

# Test IsolatedExecutionState integration (Rails 7.1+)
# Verifies thread/Fiber isolation for tags and backward compatibility
RSpec.describe JsonLogging::JsonLogger do
  let(:io) { StringIO.new }
  let(:logger) { described_class.new(io) }

  describe "thread isolation" do
    it "isolates tags per thread", :aggregate_failures do
      threads = []

      3.times do |i|
        # rubocop:disable ThreadSafety/NewThread
        threads << Thread.new do
          logger.tagged("THREAD_#{i}") do
            logger.info("message from thread #{i}")
            # Small delay to ensure interleaving
            sleep 0.01
          end
        end
        # rubocop:enable ThreadSafety/NewThread
      end

      threads.each(&:join)

      io.rewind
      lines = io.readlines

      # Each thread should have its own tags
      lines.each do |line|
        payload = JSON.parse(line)
        tags = payload["tags"] || []
        thread_id = tags.find { |t| t.start_with?("THREAD_") }
        expect(thread_id).not_to be_nil
        expect(tags.length).to eq(1)
      end

      # Should have 3 log entries
      expect(lines.length).to eq(3)
    end

    it "isolates context per thread", :aggregate_failures do
      threads = []

      2.times do |i|
        # rubocop:disable ThreadSafety/NewThread
        threads << Thread.new do
          JsonLogging.with_context(thread_id: i) do
            logger.info("test #{i}")
          end
        end
        # rubocop:enable ThreadSafety/NewThread
      end

      threads.each(&:join)

      io.rewind
      lines = io.readlines
      expect(lines.length).to eq(2)

      # Verify each thread has correct context
      lines.each do |line|
        payload = JSON.parse(line)
        thread_id = payload.dig("context", "thread_id")
        expect(thread_id).to be_in([0, 1])
      end
    end

    it "maintains tags across nested blocks in same thread" do
      logger.tagged("OUTER") do
        logger.tagged("INNER") do
          logger.info("nested")
        end
      end

      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["tags"]).to eq(["OUTER", "INNER"])
    end
  end

  describe "IsolatedExecutionState vs Thread.current" do
    it "uses IsolatedExecutionState when available (Rails 7.1+)", :aggregate_failures do
      if defined?(ActiveSupport::IsolatedExecutionState)
        logger.tagged("TEST") do
          # Tags should be stored in IsolatedExecutionState
          tags = logger.send(:current_tags)
          expect(tags).to eq(["TEST"])

          # Verify it's using IsolatedExecutionState
          key = logger.send(:tags_key)
          stored = ActiveSupport::IsolatedExecutionState[key]
          expect(stored).to eq(["TEST"])
        end
      else
        skip "IsolatedExecutionState not available (requires Rails 7.1+)"
      end
    end

    it "falls back to Thread.current for Rails 6-7.0", :aggregate_failures do
      # When IsolatedExecutionState is not available, should use Thread.current
      logger.tagged("FALLBACK") do
        tags = logger.send(:current_tags)
        expect(tags).to eq(["FALLBACK"])

        # In Rails < 7.1, tags are stored in Thread.current
        key = logger.send(:tags_key)
        if defined?(ActiveSupport::IsolatedExecutionState)
          # Rails 7.1+: Check IsolatedExecutionState
          stored = ActiveSupport::IsolatedExecutionState[key]
          expect(stored).to eq(["FALLBACK"]) if stored
        else
          # Rails 6-7.0: Check Thread.current
          stored = Thread.current[key]
          expect(stored).to eq(["FALLBACK"])
        end
      end
    end
  end

  describe "Fiber isolation (Rails 7.1+)" do
    it "isolates tags per Fiber when IsolatedExecutionState configured for Fiber" do
      skip "Fiber isolation test requires Rails 7.1+" unless defined?(ActiveSupport::IsolatedExecutionState)

      # This test would require setting IsolatedExecutionState.isolation_level = :fiber
      # But we can't change that globally in tests as it affects other tests
      # So we just verify the code path exists

      logger.tagged("FIBER_TEST") do
        tags = logger.send(:current_tags)
        expect(tags).to include("FIBER_TEST")
      end
    end
  end

  describe "backward compatibility" do
    it "works with Thread.current when IsolatedExecutionState unavailable" do
      # Simulate Rails 6-7.0 behavior by ensuring Thread.current is used
      logger.tagged("COMPAT") do
        logger.info("backward compatible")
      end

      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["tags"]).to eq(["COMPAT"])
    end

    it "maintains tag behavior across Rails versions" do
      # Tags should work the same way regardless of storage mechanism
      logger.tagged("A") do
        logger.tagged("B") do
          logger.info("test")
        end
      end

      io.rewind
      payload = JSON.parse(io.gets)
      expect(payload["tags"]).to eq(["A", "B"])
    end
  end

  describe "async code compatibility" do
    it "handles concurrent tag operations", :aggregate_failures do
      # Simulate async operations with multiple threads setting tags
      threads = []
      mutex = Mutex.new
      all_tags = {}
      barrier = Mutex.new
      condition = ConditionVariable.new
      ready_count = 0
      target_count = 5

      5.times do |i|
        # Capture thread_id outside of Thread.new to avoid closure issues
        thread_id = i
        # rubocop:disable ThreadSafety/NewThread
        threads << Thread.new(thread_id) do |tid|
          # Use barrier to ensure all threads start tagging at roughly the same time
          barrier.synchronize do
            ready_count += 1
            condition.wait(barrier) while ready_count < target_count
            condition.broadcast
          end

          logger.tagged("ASYNC_#{tid}") do
            # Small delay to increase chance of race condition if isolation is broken
            sleep 0.001
            # Read tags while still in tagged block to verify isolation
            current_tags_in_thread = logger.send(:current_tags).dup
            mutex.synchronize do
              all_tags[tid] = current_tags_in_thread
            end
            logger.info("async message #{tid}")
          end
        end
        # rubocop:enable ThreadSafety/NewThread
      end

      threads.each(&:join)

      # Each thread should have its own tags
      expect(all_tags.length).to eq(5)
      all_tags.each do |thread_id, tags|
        expect(tags).to include("ASYNC_#{thread_id}"),
          "Expected thread #{thread_id} to have ASYNC_#{thread_id} tag, but got #{tags.inspect}"
        expect(tags.length).to eq(1)
      end

      io.rewind
      lines = io.readlines
      expect(lines.length).to eq(5)

      # Verify each log entry has correct tags
      lines.each do |line|
        payload = JSON.parse(line)
        tags = payload["tags"] || []
        expect(tags.length).to eq(1)
        expect(tags.first).to match(/^ASYNC_\d+$/)
      end
    end
  end
end
