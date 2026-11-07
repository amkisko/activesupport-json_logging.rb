# Experimental Fiber isolation review

## Participants

Andrei Makarov (@amkisko)

## Decisions

Ship experimental `JsonLogging.isolation_level = :fiber` in 1.3.2. Default stays `:thread`. Fiber mode stores context, tags, timestamp cache, and prepared-tag cache on the current Fiber. Do not flip Rails `ActiveSupport::IsolatedExecutionState.isolation_level` from this API; Falcon-style apps set Rails isolation separately.

Accept the feature on measured baselines (n = 3 samples, `SCENARIO=fiber`, `BENCH_FIBER_N=3000`, `BENCH_FIBER_COUNT=8`, Ruby 4.0.2 arm64-darwin). Pressure-round `TARGET_FACTOR=0.85` fails on linear storage/alloc scale; that ratchet stays for later cooker episodes, not a block on shipping the experimental switch.

## Effects

Implementation: `lib/json_logging/execution_state.rb`, wired from context, tags, helpers timestamp cache, and sanitizer tag cache. Specs cover concurrent Fiber isolation, sibling non-leak, and shared-stack behavior under `:thread`. `make bench-fiber` / `SCENARIO=fiber` and matrix smoke include fiber series.

Median of three host samples (`benchmarks/output/fiber_sample_{1,2,3}.log`):

| Series | median ops/s | median wall (s) | alloc |
| --- | ---: | ---: | ---: |
| `baseline_fiber_sequential` | 58149.7 | 0.0516 | 201080 |
| `baseline_fiber_concurrent` | 46594.0 | 0.0644 | 274166 |
| `baseline_thread_concurrent_fibers` | 16398.4 | 0.1829 | 219824 |

Fiber concurrent isolation is about **2.84×** the ops/s of the same interleaved Fiber workload under default `:thread` (shared tag stack). Sequential fiber path stays in the same band as thread tagged+context logging.

## Next

- Optional later cooker: calibrate storage ceilings for fiber series, then N ≥ 10 optimize/prove cycles if a hot path regresses.
- Keep experimental label until a production Fiber server validates the API.

## Source

- `lib/json_logging/execution_state.rb`
- `benchmarks/load.rb` (`SCENARIO=fiber`)
- `spec/json_logging_fiber_isolation_spec.rb`
- `benchmarks/output/fiber_sample_1.log`
- `benchmarks/output/fiber_sample_2.log`
- `benchmarks/output/fiber_sample_3.log`
