# Observability mode

Run this mode when the audited system runs as a service, job worker, or long-lived process. Skip for a library with no runtime of its own, and state that reason. Keep the same finding fields.

Ask whether a person can know what broke without reading source.

## Checks

- structured logs with request or job correlation that does not leak private data;
- every failed job findable;
- every unhandled failure traced to request, user or actor, and action;
- noisy errors filtered;
- slow endpoints or jobs visible;
- outbound mail, webhook, and third-party failures visible and separated from application faults;
- health and readiness distinct when the platform has both;
- pool, queue, and retry or dead-letter behaviour visible;
- alert thresholds that fire on user impact, not on every retry.

Industry frame: latency, traffic, errors, and saturation (SRE four signals) as related reading, not house MUST.

## Indicators

Prefer new-issue counts, unresolved-failure rates, queue lag, and time-to-find a known fault over adjectives.

## Skip

No running service or worker: skip and say so.
