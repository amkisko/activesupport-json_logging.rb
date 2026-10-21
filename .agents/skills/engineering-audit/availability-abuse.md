# Security availability and abuse

Run this companion when a lower-trust principal can trigger work, allocate a resource, or automate a valuable business action. Skip when no such path exists, and state that reason. Keep the finding contract in `security.md`.

Name the expensive unit: bytes parsed, decompressed size, rows scanned, fan-out, queue work, external calls, memory retained, locks held, or valuable action consumed. Bound cost per request, per principal, per tenant, and globally.

Scan for: asymmetric work; unbounded collection, recursion, nesting, decompression, regex, or upload; cache-key explosion; retry amplification; slow consumer; lock or connection starvation; tenant starvation; enumeration; credential or recovery flooding; unrestricted automation of purchases, invitations, exports, or scarce allocations; rate limits that fail open or merge unrelated principals.

Validate with a safe local ceiling or production-shaped benchmark, not uncontrolled load against a live service. Record the smallest input, concurrency, and duration that cross the named budget. Resource-and-budget mode owns normal efficiency; this companion owns lower-trust amplification and abuse.

## Skip

No lower-trust trigger for meaningful work or business action: skip and say so.
