# Performance mode

Run this mode when serving latency, payload size, or person-perceived delay is in scope. Skip for a pure specification or data file, and state that reason. Keep the same finding fields.

Hot-path shape (Big-O, N+1, repeated scans) stays in the core dimensions. This mode records named measurements against a named budget.

## Two tracks

Person-perceived: first paint or equivalent, layout stability, input delay, cold versus warm load, narrow surface, slow network, large lists, error and modal-heavy states.

Serving: request or job latency percentiles, query count, allocation, serialization cost. Use a profiler or query plan when the hot path is unclear.

## What to name

Each performance claim names the surface or endpoint, the metric, the fixture, and the measured value. Budget without a measurement is inference. Name a round-trip or byte budget, not only latency percentiles.

## Shapes

Look for these shapes without vendor tokens. A match is only a candidate until the loop body is shown to perform storage or network IO, or a benchmark demonstrates the cost.

- query per element in a loop, only when the body does store or network IO;
- unbounded list read and unpaginated egress;
- fetch-all then filter or slice in process;
- wide fetch of unused columns or nested relations;
- independent sequential IO versus data-dependent sequential; unbounded fan-out versus pool or worker budget;
- non-store work inside a transaction while a connection or lock is held;
- blocking the serving thread or event loop with sync IO or CPU on the request path;
- whole-body buffering of large uploads;
- process-lifetime cache or map with no eviction, TTL, or size cap;
- unanchored pattern search on a growing table;
- missing index on referencing foreign keys and on hot filter or order fields;
- vector search without a row limit, or stored in a type the available index cannot cover;
- repeated linear lookup in a loop, pairwise nested scans, sort inside a loop, front-insert on a growing array, copy-accumulator rebuild, full-tree clone of a large value on a hot path;
- heavy first-paint script, initial document data fetched on the client, search IO per keystroke with no debounce.

If the person asks for a quick pass, run only the high-shape checks and still label unverified hits as inference.

Related: resource and budget mode owns memory, CPU, storage, network bytes, energy, tool calls, and tokens. This mode owns time the person or caller waits.

## Indicators

Prefer milliseconds, scores the tree already collects, query counts, and payload bytes over "slow" or "fast".

## Skip

No runtime serving or person-perceived delay in scope: skip and say so.
