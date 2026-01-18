# CHANGELOG

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
