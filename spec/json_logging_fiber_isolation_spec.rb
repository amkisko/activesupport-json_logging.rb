# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe JsonLogging do
  describe "fiber isolation (experimental)" do
    let(:io) { StringIO.new }
    let(:logger) { JsonLogging::JsonLogger.new(io) }

    around do |example|
      previous = described_class.isolation_level
      example.run
    ensure
      described_class.isolation_level = previous
    end

    describe ".isolation_level" do
      it "defaults to :thread" do
        described_class.isolation_level = :thread
        expect(described_class.isolation_level).to eq(:thread)
      end

      it "accepts :fiber" do
        described_class.isolation_level = :fiber
        expect(described_class.isolation_level).to eq(:fiber)
      end

      it "rejects unknown levels" do
        expect { described_class.isolation_level = :ractor }.to raise_error(ArgumentError, /:thread or :fiber/)
      end
    end

    describe "when isolation_level is :fiber" do
      before { described_class.isolation_level = :fiber }

      it "isolates tags across concurrent Fibers on one Thread", :aggregate_failures do
        seen = {}
        fibers = 8.times.map do |i|
          Fiber.new do
            logger.tagged("FIBER_#{i}") do
              Fiber.yield
              seen[i] = logger.send(:current_tags).dup
              logger.info("from fiber #{i}")
            end
          end
        end

        fibers.each(&:resume)
        fibers.each(&:resume)

        expect(seen.size).to eq(8)
        seen.each do |i, tags|
          expect(tags).to eq(["FIBER_#{i}"])
        end

        io.rewind
        lines = io.readlines
        expect(lines.size).to eq(8)
        lines.each do |line|
          payload = JSON.parse(line)
          expect(payload["tags"].size).to eq(1)
          expect(payload["tags"].first).to match(/\AFIBER_\d+\z/)
        end
      end

      it "isolates with_context across concurrent Fibers", :aggregate_failures do
        fibers = 4.times.map do |i|
          Fiber.new do
            described_class.with_context(fiber_id: i, request_id: "req-#{i}") do
              Fiber.yield
              logger.info("context fiber #{i}")
            end
          end
        end

        fibers.each(&:resume)
        fibers.each(&:resume)

        io.rewind
        payloads = io.readlines.map { |line| JSON.parse(line) }
        expect(payloads.size).to eq(4)

        fiber_ids = payloads.map { |p| p.dig("context", "fiber_id") }.sort
        expect(fiber_ids).to eq([0, 1, 2, 3])

        payloads.each do |payload|
          fid = payload.dig("context", "fiber_id")
          expect(payload.dig("context", "request_id")).to eq("req-#{fid}")
        end
      end

      it "does not leak outer Fiber context into a sibling Fiber", :aggregate_failures do
        leaked = nil
        parent = Fiber.new do
          described_class.with_context(owner: "parent") do
            child = Fiber.new do
              leaked = described_class.additional_context[:owner]
              logger.tagged("child") { logger.info("child") }
            end
            child.resume
            logger.tagged("parent") { logger.info("parent") }
          end
        end
        parent.resume

        expect(leaked).to be_nil

        io.rewind
        payloads = io.readlines.map { |line| JSON.parse(line) }
        child_line = payloads.find { |p| p["tags"] == ["child"] }
        parent_line = payloads.find { |p| p["tags"] == ["parent"] }
        expect(child_line.dig("context", "owner")).to be_nil
        expect(parent_line.dig("context", "owner")).to eq("parent")
      end

      it "keeps nested tagged blocks on the same Fiber", :aggregate_failures do
        logger.tagged("OUTER") do
          logger.tagged("INNER") do
            logger.info("nested")
          end
        end

        io.rewind
        expect(JSON.parse(io.gets)["tags"]).to eq(["OUTER", "INNER"])
      end
    end

    describe "when isolation_level stays :thread" do
      before { described_class.isolation_level = :thread }

      it "shares Thread-scoped storage across Fibers on the same Thread (Rails default)", :aggregate_failures do
        # Opt-in :fiber exists because interleaved Fibers push into one shared tag stack.
        observed = []
        fibers = 2.times.map do |i|
          Fiber.new do
            logger.tagged("T_#{i}") do
              Fiber.yield
              observed << logger.send(:current_tags).dup
              logger.info("thread-scope fiber #{i}")
            end
          end
        end

        fibers.each(&:resume)
        fibers.each(&:resume)

        expect(observed.size).to eq(2)
        # First Fiber resumes after the second Fiber pushed into the shared stack.
        expect(observed.first).to eq(["T_0", "T_1"])
      end
    end
  end
end
