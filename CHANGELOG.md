# CHANGELOG

## 1.1.0 (2025-11-04)

- Move tags to root level of JSON payload instead of nested in context (breaking change: tags now at `payload["tags"]` instead of `payload["context"]["tags"]`)
- Filter system-controlled keys (severity, timestamp, message, tags, context) from user context to prevent conflicts
- Prevent nested context objects when user context includes a `context` key
- Fix pending spec for TimeWithZone objects by requiring ActiveSupport time extensions

## 1.0.0 (2025-10-31)

- Initial stable release
