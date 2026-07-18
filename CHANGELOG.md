# CHANGELOG

## Unreleased

- Add opt-in `JsonLogging::EventSubscriber` for Rails 8.1 `ActiveSupport::EventReporter` / `Rails.event` structured events

## 1.2.3 (2026-07-13)

- Reduce per-line work for plain string, hash, tagged, and context-scoped log messages on common shapes
- Sanitize flat and nested structured hash payloads without deep-copying the source when values are logging-safe primitives
- Reuse ISO8601 microsecond UTC timestamps when callers already supply them
- Skip context merging when tags and additional context are both empty
- Cache empty thread context as a frozen hash on the hot path
- Expand hot-path contract specs for fast-path logging and sanitization
- Encode large nested structured hash log lines in one pass with copy-on-write sanitization and JSON.generate instead of building a full sanitized tree first

## 1.2.2 (2026-07-08)

- Isolate log context per execution via `ActiveSupport::IsolatedExecutionState` when available
- Sanitize fallback formatter output when JSON encoding fails
- Refactor emit path into `LineEncoder`, `PayloadBuilder`, and `Severity` modules
- Cache sanitized `additional_context` per `with_context` scope on the hot path
- Memoize `ActiveSupport::ParameterFilter` when `filter_parameters` is unchanged
- Fast-path `sanitize_string` for clean ASCII text within length limits
- Sanitize tags at push time instead of on every log line
- Skip `deep_stringify_keys` when payload structure already uses string keys
- Add hot-path optimization specs

## 1.2.1 (2026-01-18)

- Refactor tag stack handling in JsonLogging formatter for improved maintainability
- Refactor timestamp handling in JsonLogging helpers to support Time.zone
- Add Ruby 4.0 support in gemspec and Appraisal configurations

## 1.2.0 (2025-11-07)

- Add support for service-specific tagged loggers: create loggers with permanent tags using `logger.tagged("service")` without a block
- Improve BroadcastLogger compatibility: service-specific loggers work seamlessly with `ActiveSupport::BroadcastLogger`
- Fix LocalTagStorage implementation to match Rails' TaggedLogging behavior: use `tag_stack` attribute accessor pattern for proper tag isolation
- Add comprehensive examples in README for service-specific loggers and BroadcastLogger integration

## 1.1.0 (2025-11-04)

- Move tags to root level of JSON payload instead of nested in context (breaking change: tags now at `payload["tags"]` instead of `payload["context"]["tags"]`)
- Filter system-controlled keys (severity, timestamp, message, tags, context) from user context to prevent conflicts
- Prevent nested context objects when user context includes a `context` key
- Fix pending spec for TimeWithZone objects by requiring ActiveSupport time extensions

## 1.0.0 (2025-10-31)

- Initial stable release
