# JSON Logging Hot Path Overhead

## Participants

Agent-assisted performance work on activesupport-json_logging.rb.

## Decisions

Treat common log shapes as first-class fast paths instead of always building a full payload and running generic sanitization. Keep JSON field names and filtering semantics unchanged.

## Effects

Before optimization, benchmark runs on this repository showed high overhead versus ActiveSupport::Logger for everyday logging:

Simple string messages (10000 iterations) paid roughly 300 to 400 percent overhead because every line went through payload assembly, key stringification, and JSON encoding even when the message was a plain string with no tags and no thread context.

Hash messages paid a similar penalty plus sanitization cost. Primitive and shallow nested hashes still used deep_dup when Rails ParameterFilter was present, then walked values through the generic sanitize_value path.

Tagged and context-scoped lines repeated merge_context and tag preparation even when the message shape was simple enough to emit directly.

Timestamp handling reformatted values on every add call even when the caller already supplied an ISO8601 microsecond UTC string.

Large nested structured hashes in the sanitization benchmark remained expensive because the generic path deep-copied the source hash before filtering.

RuboCop CI failed on the new optimization spec and benchmark spec (describe layout, spy usage, Rails/Output).

After optimization (unreleased, commit 09081c4 plus working tree), focused benchmarks on the same machine recorded roughly 340 percent overhead for simple strings, 313 percent for hash messages, 97 percent for tagged logging, 172 percent for context scope, and about 11 objects per hash log line. Tagged logging improved versus earlier rounds.

Single-pass encoding for large structured hashes (StructuredHashJsonEncoder) walks the source once with copy-on-write jsonable_tree. When no values need mutation, the encoder calls JSON.generate on the original tree instead of allocating a sanitized copy. A pure Ruby character streaming prototype was about three times slower than copy plus JSON.generate and was replaced by this hybrid approach. Large nested hash sanitization overhead in the full logger benchmark remains high relative to simple strings because the ratio includes logger stack work beyond encoding alone; direct encode_line calls on the benchmark-shaped hash are faster than sanitize_hash plus JSON.generate in isolation.

## Next

Bump lib/json_logging/version.rb when cutting release 1.2.3. Open pull request with changelog and trace files.

## Source

spec/performance/benchmark_spec.rb, tmp/benchmarks/profile_09081c4b3968517fa4a4ed7664dea049de3473f6_20260713084208.log, agent session on json logging optimizations.
