# Changelog

## 1.0.0 (2024-10-31)

First stable release.

- feat: single-line JSON format compatible with cloud logging services (GCP, AWS, Azure)
- feat: native tagged logging with `logger.tagged("TAG")` API compatible with Rails
- feat: thread-safe context via `JsonLogging.with_context` for per-thread fields
- feat: smart message parsing for hashes, JSON strings, and plain strings
- feat: inherit all ActiveSupport::Logger features (silence, local_level, etc.)
- feat: BroadcastLogger compatibility for Rails 7.1+ automatic wrapping
- feat: timestamp precision in microseconds (iso8601 with 6 decimals)
- feat: Rails ParameterFilter integration for automatic sensitive data filtering
- feat: input sanitization removing control characters and truncating long strings
- feat: sensitive key pattern matching fallback when ParameterFilter unavailable
- feat: depth and size limits for nested structures to prevent log bloat
- feat: single-line JSON output to prevent log injection via newlines
- feat: graceful error handling with fallback entries on serialization errors
- feat: Rails 6.0, 6.1, 7.0, 7.1, 7.2, 8.0 support
- feat: IsolatedExecutionState for thread/Fiber isolation (Rails 7.1+)
- feat: backward compatible fallback to Thread.current for Rails 6-7.0
- feat: kwargs support in logger initialization for Rails 7+
- perf: ~0.006ms per log entry overhead (250-400% vs plain text, typical for JSON)
- perf: memory efficient with ~3KB per entry and zero retained memory
- feat: performance benchmarks with memory profiling included
- test: 93.78% code coverage with comprehensive RSpec suite
- test: BroadcastLogger integration tests
- test: IsolatedExecutionState thread safety tests
- test: Appraisals configured for multi-version testing (Rails 6-8)
- test: GitHub Actions CI workflow
- docs: complete README with installation, usage, and API docs
- docs: Rails environment configuration examples (development, production, test)
- docs: Lograge integration with third-party logger configurations
- docs: Puma integration example
- docs: security best practices and ParameterFilter guide
- docs: inherited Rails logger features documentation

---

## 0.1.0

- feat: initial JSON formatter and logger implementation
- test: basic RSpec test coverage
