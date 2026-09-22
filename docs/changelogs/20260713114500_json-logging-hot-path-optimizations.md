# JSON Logging Hot Path Optimizations

## Participants

Agent-assisted performance work on activesupport-json_logging.rb.

## Decisions

Add LineEncoder fast paths for plain strings, tagged strings, contextual strings, standalone hashes, tagged hashes, and contextual hashes when additional context is already sanitized. Skip PayloadBuilder.merge_context when tags and additional context are both empty.

Extend Sanitizer with primitive hash and structured hash fast paths. Move structured hash logic into lib/json_logging/structured_hash_sanitizer.rb as Sanitizer::StructuredHash. Detect circular references during structured_log_hash? so logging falls back to the generic sanitizer instead of overflowing the stack.

Reuse ISO8601 microsecond UTC timestamps via Helpers.current_timestamp and Helpers.normalize_timestamp. Freeze and cache an empty hash for thread context when no additional context is present.

Record benchmark output to tmp/benchmarks/profile_<commit>.log (or timestamp suffix when the working tree is dirty). Add optional StackProf and benchmark-ips harness under spec/performance/profiling_spec.rb (development dependencies only).

## Effects

Files changed or added: lib/json_logging/line_encoder.rb, lib/json_logging/sanitizer.rb, lib/json_logging/structured_hash_sanitizer.rb, lib/json_logging/structured_hash_json_encoder.rb, lib/json_logging/payload_builder.rb, lib/json_logging/helpers.rb, lib/json_logging/json_logger_extension.rb, lib/json_logging.rb, spec/json_logging_optimizations_spec.rb, spec/support/benchmark_profile.rb, spec/support/benchmark_profiler.rb, spec/performance/profiling_spec.rb, spec/performance/benchmark_spec.rb, activesupport-json_logging.gemspec.

Add StructuredHashJsonEncoder for large structured hash messages when Rails parameter filters do not require a full-tree walk. The encoder walks the source hash once with copy-on-write jsonable_tree, keeps the source tree when all values are already logging-safe, and emits JSON with JSON.generate plus severity and timestamp fields. Falls back to sanitize_hash plus JSON.generate for smaller shapes, deep parameter filters, and non-structured hashes.

Validation commands run:

bundle exec rubocop lib/json_logging/structured_hash_json_encoder.rb lib/json_logging/structured_hash_sanitizer.rb

bundle exec rspec spec/json_logging_optimizations_spec.rb spec/json_logging_sanitizer_spec.rb spec/json_logger_spec.rb spec/json_logging_context_spec.rb

bundle exec rspec spec/performance/benchmark_spec.rb --tag benchmark

All passed: 90 examples in focused suite, 6 benchmark examples, RuboCop clean on encoder and structured sanitizer files.

Benchmark profile after single-pass encoder work (10000 iterations unless noted): simple messages 153.36 percent overhead, hash messages 361.64 percent, tagged logging 103.09 percent, context scope 180.28 percent, large hash sanitization 3801.62 percent versus simple string (1000 iterations), 11.0 objects per hash log line. Micro-benchmark on the benchmark-shaped large hash: encode_line about 18 percent faster than sanitize_hash plus JSON.generate for 2000 iterations when the source tree needs no copy.

## Next

Release 1.2.3 with version.rb bump. Pull request linking this trace file and usr/docs/issues/20260713114500_json-logging-hot-path-overhead.md. Explore copy-free encoding for large structured hashes if further sanitization gains are needed.

## Source

usr/docs/issues/20260713114500_json-logging-hot-path-overhead.md, tmp/benchmarks/profile_09081c4b3968517fa4a4ed7664dea049de3473f6_20260713084208.log, commits 581d728 through 09081c4 plus uncommitted optimization work.
