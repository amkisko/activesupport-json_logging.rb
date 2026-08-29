# Performance mode

Run this mode when serving latency, payload size, or person-perceived delay is in scope. Skip for a pure specification or data file, and state that reason. Keep the same finding fields.

Hot-path shape (Big-O, N+1, repeated scans) stays in the core dimensions. This mode records named measurements against a named budget.

## Two tracks

Person-perceived: first paint or equivalent, layout stability, input delay, cold versus warm load, narrow surface, slow network, large lists, error and modal-heavy states.

Serving: request or job latency percentiles, query count, allocation, serialization cost. Use a profiler or query plan when the hot path is unclear.

## What to name

Each performance claim names the surface or endpoint, the metric, the fixture, and the measured value. Budget without a measurement is inference.

Related: resource and budget mode owns memory, CPU, storage, network bytes, and energy. This mode owns time the person or caller waits.

## Indicators

Prefer milliseconds, scores the tree already collects, query counts, and payload bytes over "slow" or "fast".

## Skip

No runtime serving or person-perceived delay in scope: skip and say so.
