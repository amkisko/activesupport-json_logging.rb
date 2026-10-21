# Protocols and messaging

Run this companion when the tree consumes or emits webhooks, queue messages, events, sockets, custom protocols, or serialized commands. Skip when it has no such boundary, and state that reason. Keep the finding contract in `security.md`.

Trace sender identity, framing, canonical bytes, authenticity, freshness, ordering, replay handling, schema selection, acknowledgement, retry, and side effect. A transport credential authenticates a hop, not necessarily the original sender or object authority.

Scan for: ambiguous framing; verify-after-parse; signature over different bytes than the consumer uses; missing destination or tenant binding; replayable sensitive commands; stale events that overwrite newer state; unsafe type selection; unbounded decompression or nesting; poison messages; acknowledgement before durable commit; retry that duplicates a non-idempotent effect.

Validate with duplicate, delayed, reordered, truncated, oversized, wrongly encoded, wrong-destination, wrong-tenant, and invalid-signature messages. Confirm the consumer fails closed before the sensitive side effect.

## Skip

No message, event, webhook, socket, or custom serialization boundary: skip and say so.
