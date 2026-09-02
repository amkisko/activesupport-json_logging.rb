# Contract mode

Run this mode when the audited system publishes or consumes a protocol, API, or event contract. Skip when it has none, and state that reason. Keep the same finding fields.

## Checks

- request and response (or message) shape;
- authorization per operation;
- rate and pagination limits;
- idempotency for writes;
- error shape that matches the transport status;
- webhook or callback verification and replay protection;
- destination failure recorded as completed versus retried as if our code failed;
- backward compatibility for callers you still support.

Auth detail for each operation stays in security review mode.

## Indicators

Prefer schema-validation pass/fail, operations without a negative auth test, and compatibility breaks since the last released contract.

## Skip

No published or consumed contract: skip and say so.
