#!/usr/bin/env ruby
# frozen_string_literal: true

# Pressure / load bench for JsonLogging hot paths (CPU, memory, bytes written).
#
# Usage:
#   make bench-load
#   env -u BUNDLE_PATH bundle exec ruby benchmarks/load.rb
#   SCENARIO=matrix BENCH_SIMPLE_N=500 env -u BUNDLE_PATH bundle exec ruby benchmarks/load.rb
#
# In some Cursor/sandbox environments BUNDLE_PATH points at a stale bundle; unset it first.
#
# Env:
#   SCENARIO=matrix|simple|hash|tagged|fiber|smoke (default matrix)
#   BENCH_SIMPLE_N, BENCH_HASH_N, BENCH_TAGGED_N, BENCH_FIBER_N — baseline iteration counts
#   BENCH_FIBER_COUNT — concurrent Fibers per wave (default 8)
#   PRESSURE_MULT — pressure round ops multiplier vs baseline (default 1.75, range ~1.5–2)
#   TARGET_FACTOR — next-round resource ceiling vs baseline metrics (default 0.85)
#   PRESSURE_POLYRUN_LIB — optional override path to polyrun lib/ (default ../../polyrun.rb/lib)

gem_lib = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(gem_lib) unless $LOAD_PATH.include?(gem_lib)

polyrun_lib = ENV["PRESSURE_POLYRUN_LIB"] || File.expand_path("../../polyrun.rb/lib", __dir__)
$LOAD_PATH.unshift(polyrun_lib) unless $LOAD_PATH.include?(polyrun_lib)

require "json"
require "stringio"
require "active_support/logger"
require "json_logging"
require "polyrun/benchmark/pressure"

module JsonLogging
  module Bench
    module Load
      module_function

      def run!
        scenario = ENV.fetch("SCENARIO", "matrix")
        factor = env_float("TARGET_FACTOR", Polyrun::Benchmark::Pressure::DEFAULT_TARGET_FACTOR)
        pressure_mult = env_float("PRESSURE_MULT", 1.75)

        simple_n, hash_n, tagged_n, fiber_n = iteration_plan(scenario)
        fiber_count = env_int("BENCH_FIBER_COUNT", 8)

        puts "JsonLogging pressure scenario=#{scenario} simple_n=#{simple_n} hash_n=#{hash_n} tagged_n=#{tagged_n} fiber_n=#{fiber_n} fiber_count=#{fiber_count} pressure_mult=#{pressure_mult} target_factor=#{factor}"

        results =
          case scenario
          when "matrix"
            run_matrix!(simple_n, hash_n, tagged_n, fiber_n, fiber_count, pressure_mult, factor)
          when "simple"
            [measure_simple!("baseline_simple_string", simple_n)]
          when "hash"
            [measure_hash!("baseline_nested_hash", hash_n)]
          when "tagged"
            [measure_tagged_context!("baseline_tagged_context", tagged_n)]
          when "fiber"
            run_fiber_matrix!(fiber_n, fiber_count, pressure_mult, factor)
          when "smoke"
            run_matrix!(50, 20, 30, 40, 4, 1.5, factor)
          else
            raise ArgumentError, "Unknown SCENARIO=#{scenario.inspect}"
          end

        repo_root = File.expand_path("..", __dir__)
        path = Polyrun::Benchmark::Pressure.write_results!(results, repository_root: repo_root, name: "load")
        results.each { |row| puts row["report"] }
        puts "wrote #{path}"
        exit_code = (results.any? { |row| row["pass"] == false }) ? 1 : 0
        exit exit_code
      end

      def run_matrix!(simple_n, hash_n, tagged_n, fiber_n, fiber_count, pressure_mult, factor)
        results = []

        # Simple string logs
        simple_b = measure_simple!("baseline_simple_string", simple_n)
        results << simple_b
        simple_hot = [(simple_n * pressure_mult).round, 1].max
        simple_targets = scaled_targets(simple_b, simple_hot, factor)
        results << measure_simple!("pressure_simple_string_#{simple_hot}", simple_hot, targets: simple_targets)

        # Nested hash + sanitization
        hash_b = measure_hash!("baseline_nested_hash", hash_n)
        results << hash_b
        hash_hot = [(hash_n * pressure_mult).round, 1].max
        hash_targets = scaled_targets(hash_b, hash_hot, factor)
        results << measure_hash!("pressure_nested_hash_#{hash_hot}", hash_hot, targets: hash_targets)

        # Tagged + thread context
        tag_b = measure_tagged_context!("baseline_tagged_context", tagged_n)
        results << tag_b
        tag_hot = [(tagged_n * pressure_mult).round, 1].max
        tag_targets = scaled_targets(tag_b, tag_hot, factor)
        results << measure_tagged_context!("pressure_tagged_context_#{tag_hot}", tag_hot, targets: tag_targets)

        results.concat(run_fiber_matrix!(fiber_n, fiber_count, pressure_mult, factor))
        results
      end

      def run_fiber_matrix!(fiber_n, fiber_count, pressure_mult, factor)
        results = []

        # Sequential tagged+context under experimental :fiber (same shape as thread path)
        seq_b = measure_tagged_context_fiber!("baseline_fiber_sequential", fiber_n)
        results << seq_b
        seq_hot = [(fiber_n * pressure_mult).round, 1].max
        results << measure_tagged_context_fiber!(
          "pressure_fiber_sequential_#{seq_hot}",
          seq_hot,
          targets: scaled_targets(seq_b, seq_hot, factor)
        )

        # Concurrent Fibers under :fiber (isolated)
        conc_b = measure_concurrent_fibers!("baseline_fiber_concurrent", fiber_n, fiber_count: fiber_count)
        results << conc_b
        conc_hot = [(fiber_n * pressure_mult).round, 1].max
        results << measure_concurrent_fibers!(
          "pressure_fiber_concurrent_#{conc_hot}",
          conc_hot,
          fiber_count: fiber_count,
          targets: scaled_targets(conc_b, conc_hot, factor)
        )

        # Concurrent Fibers under default :thread (shared storage; throughput comparison only)
        thread_conc_b = measure_concurrent_fibers!(
          "baseline_thread_concurrent_fibers",
          fiber_n,
          fiber_count: fiber_count,
          isolation: :thread
        )
        results << thread_conc_b
        thread_conc_hot = [(fiber_n * pressure_mult).round, 1].max
        results << measure_concurrent_fibers!(
          "pressure_thread_concurrent_fibers_#{thread_conc_hot}",
          thread_conc_hot,
          fiber_count: fiber_count,
          isolation: :thread,
          targets: scaled_targets(thread_conc_b, thread_conc_hot, factor)
        )

        results
      end

      def measure_simple!(label, ops, targets: nil)
        io = StringIO.new
        logger = JsonLogging::JsonLogger.new(io)
        start_size = io.size
        result = Polyrun::Benchmark::Pressure.measure(
          label: label,
          ops: ops,
          extras: {"targets" => targets}
        ) do
          ops.times { |i| logger.info("simple hot-path message #{i}") }
        end
        add_storage!(result, io, start_size)
        result
      end

      def measure_hash!(label, ops, targets: nil)
        io = StringIO.new
        logger = JsonLogging::JsonLogger.new(io)
        payload = nested_hash_payload
        start_size = io.size
        result = Polyrun::Benchmark::Pressure.measure(
          label: label,
          ops: ops,
          extras: {"targets" => targets}
        ) do
          ops.times { |i| logger.info(payload.merge(iteration: i)) }
        end
        add_storage!(result, io, start_size)
        result
      end

      def measure_tagged_context!(label, ops, targets: nil)
        with_isolation(:thread) do
          io = StringIO.new
          logger = JsonLogging::JsonLogger.new(io)
          start_size = io.size
          result = Polyrun::Benchmark::Pressure.measure(
            label: label,
            ops: ops,
            extras: {"targets" => targets, "isolation_level" => "thread"}
          ) do
            ops.times do |i|
              JsonLogging.with_context(user_id: i, request_id: "req-#{i}", trace: "t#{i % 100}") do
                logger.tagged("HTTP", "json_logging") do
                  logger.info("tagged message with context")
                end
              end
            end
          end
          add_storage!(result, io, start_size)
          result
        end
      end

      def measure_tagged_context_fiber!(label, ops, targets: nil)
        with_isolation(:fiber) do
          io = StringIO.new
          logger = JsonLogging::JsonLogger.new(io)
          start_size = io.size
          result = Polyrun::Benchmark::Pressure.measure(
            label: label,
            ops: ops,
            extras: {"targets" => targets, "isolation_level" => "fiber"}
          ) do
            ops.times do |i|
              JsonLogging.with_context(user_id: i, request_id: "req-#{i}", trace: "t#{i % 100}") do
                logger.tagged("HTTP", "json_logging") do
                  logger.info("tagged message with context")
                end
              end
            end
          end
          add_storage!(result, io, start_size)
          result
        end
      end

      def measure_concurrent_fibers!(label, ops, fiber_count:, targets: nil, isolation: :fiber)
        with_isolation(isolation) do
          io = StringIO.new
          logger = JsonLogging::JsonLogger.new(io)
          start_size = io.size
          result = Polyrun::Benchmark::Pressure.measure(
            label: label,
            ops: ops,
            extras: {
              "targets" => targets,
              "isolation_level" => isolation.to_s,
              "fiber_count" => fiber_count
            }
          ) do
            i = 0
            while i < ops
              batch = [fiber_count, ops - i].min
              fibers = batch.times.map do |f|
                idx = i + f
                Fiber.new do
                  JsonLogging.with_context(user_id: idx, fiber_id: f, request_id: "req-#{idx}") do
                    logger.tagged("HTTP", "fiber-#{f}") do
                      Fiber.yield
                      logger.info("fiber concurrent message")
                    end
                  end
                end
              end
              fibers.each(&:resume)
              fibers.each(&:resume)
              i += batch
            end
          end
          add_storage!(result, io, start_size)
          result
        end
      end

      def with_isolation(level)
        previous = JsonLogging.isolation_level
        JsonLogging.isolation_level = level
        yield
      ensure
        JsonLogging.isolation_level = previous
      end

      def nested_hash_payload
        @nested_hash_payload ||= {
          user: {
            id: 123,
            email: "user@example.com",
            profile: {
              name: "Bench User",
              bio: "A" * 800,
              preferences: (1..30).map { |j| ["pref_#{j}", "value_#{j}"] }.to_h
            }
          },
          request: {
            path: "/api/bench",
            params: (1..12).map { |j| ["param_#{j}", "value_#{j}"] }.to_h
          }
        }
      end

      def add_storage!(result, io, start_size)
        result["metrics"]["storage_delta_bytes"] += (io.size - start_size)
        result["report"] = Polyrun::Benchmark::Pressure.format_report(result)
      end

      def scaled_targets(baseline_row, new_ops, factor)
        base_targets = Polyrun::Benchmark::Pressure.targets_from(baseline_row["metrics"], factor: factor)
        scale_targets_for_ops(base_targets, baseline_row["ops"], new_ops)
      end

      def scale_targets_for_ops(targets, baseline_ops, new_ops)
        return targets if baseline_ops.nil? || baseline_ops <= 0 || new_ops.nil?

        ratio = new_ops.to_f / baseline_ops
        targets.transform_values { |v| v.nil? ? nil : v * ratio }
      end

      def iteration_plan(scenario)
        case scenario
        when "smoke"
          [50, 20, 30, 40]
        when "fiber"
          [
            env_int("BENCH_SIMPLE_N", 10_000),
            env_int("BENCH_HASH_N", 1_500),
            env_int("BENCH_TAGGED_N", 5_000),
            env_int("BENCH_FIBER_N", 5_000)
          ]
        else
          [
            env_int("BENCH_SIMPLE_N", 10_000),
            env_int("BENCH_HASH_N", 1_500),
            env_int("BENCH_TAGGED_N", 5_000),
            env_int("BENCH_FIBER_N", 5_000)
          ]
        end
      end

      def env_int(name, default)
        Integer(ENV.fetch(name, default.to_s))
      end

      def env_float(name, default)
        Float(ENV.fetch(name, default.to_s))
      end
    end
  end
end

JsonLogging::Bench::Load.run! if $PROGRAM_NAME == __FILE__
