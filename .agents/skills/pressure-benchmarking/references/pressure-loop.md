# Pressure loop

## Goal

Keep the product correct under higher load while using less CPU, resident
memory, storage growth, and network bytes than the previous accepted ceiling.
Time behaviour (latency, near-linear scaling) stays a sibling series; do not
trade correctness for a lower number.

## States

```text
calibrate meter -> baseline -> stress -> tighten -> (optimize -> prove) x N -> accept|rollback
```

1. calibrate meter - prove the parser and harness separate every named stage
2. baseline - named probe, fixture, machine class, load L0
3. stress - same probe at load L1 greater than L0
4. tighten - new ceilings set below previous headroom at L1
5. optimize - one hypothesis, one change aimed at the named primary series only
6. prove - remeasure at L1 against the new ceilings
7. accept or roll back - write ceilings only when prove passes and cooker rules hold

Do not skip from calibrate to baseline. A missing meter is not a pass. An
uncalibrated meter is not a baseline. Do not skip from baseline to accept.

## Calibrate meter

Before baseline:

1. Run the consumer self-test where every named stage has a distinct known p95
   (for a multi-stage probe: for example parse, resolve, render, lock).
2. Fail if the parser mixes stages (resolve field must equal the resolve line
   value, and likewise for every other stage). Do not trust multiline patterns
   that swallow lines (for example `/m` with `.` across newlines).
3. Run one direct harness comparison (stage p95 versus wall/cpu aggregate) and
   record that the meter separates stages from the aggregate.
4. Calibrate fail ends the episode as incomplete. No optimize, no propose, no
   write of ceilings.

## Pressure cooker

Pressure is not a one-cycle gate. Analogy: bring the pot to temperature, then
hold until it boils.

1. Bring to temperature - raise load to L1 and set new ceilings from the
   per-series propose-basis.
2. Hold until it boils - run at least 10 optimize/prove cycles at L1 against
   those ceilings (or deliberately tighter ceilings). One green prove is not
   an accepted episode.
3. Each boil cycle - name the primary series; one hypothesis; one change;
   remeasure; append the iteration log (measurement, change, prove pass/fail).
4. Samples versus iterations - samples-per-load (noise and median/max; n >= 3
   for gate, propose, and write) is not the same as episode iterations
   (cooker; N >= 10). Neither replaces the other.
5. House default N >= 10. Binding may raise N when the hot path warrants it.

## Primary series

Before each optimize cycle, name exactly one primary series (for example
`resolve_p95_us` or `wall_ms`). Optimize only that series until prove. Other
series are side effects. A broad hot-path cleanup without a named primary is
a procedure failure. When prove passes for the primary, pick the next primary
explicitly or stop under the stop criteria below.

## Propose basis

Name the propose basis for every series in one place in the consumer binding:
`median` or `max`, times headroom (default headroom 1.15). Timing series may
use `max` times headroom when host noise requires it. Do not leave the loop
text saying median while the script uses max. Never raise a ceiling in the
same episode without an explicit allow-raise decision in the live-work note.

## Series (minimum)

Measure the same series at each load step:

1. CPU - process CPU milliseconds for the named probe, or a stated proxy
2. Memory - peak RSS bytes for that probe; see Memory rule below
3. Storage - fixture or cache growth for the probe, plus shipped artifact size
   when the change can grow publish bytes (cite `delivery-budgets` for the
   continuous ship-path gate)
4. Network - transferred bytes for probes that touch a registry or remote
   source; mark `not_in_scope` when the probe is local-only and say so
5. Time sibling - wall milliseconds and, for multi-stage probes, each stage
   p95 separately from the aggregate

### Aggregates versus stages

When the probe is multi-stage, the report must carry named stage p95 fields
separately (for example `parse_p95`, `resolve_p95`, `render_p95`, `lock_p95`)
plus `wall_ms` and `cpu_ms`. Do not treat a stage p95 as the wall aggregate,
and do not treat wall as a substitute for a stage that failed the gate.

### Memory rule

Peak RSS is process lifetime plus fixtures held in memory unless the probe is
isolated per stage. Do not claim stage RSS without an isolated probe. Mark the
Memory series in the binding as `process_lifetime` or `isolated_stage`.

## Probe rules

- same machine class and comparable host load for every step in one episode
- name probe, fixture, warmup, iterations, and exact command
- alternate order when repeating samples that can drift with host load
- CPU and RSS directional claims need at least three samples and a median or
  max per the series basis; with n = 1 report observed values only and do not
  gate, propose, or write
- gate, propose, and write require samples-per-load >= 3; n = 1 ladders are
  observe-only
- raise one load axis at a time (package count, export size, concurrency)
- stop uncontrolled load against live shared services; use local fixtures or a
  dedicated ceiling

## Load pattern siblings

The pressure loop is primarily a step/capacity ladder (raise load, hold, measure).
Name soak (time axis, leaks), spike, and stress as siblings. Do not mix them
into the same episode without an explicit live-work decision.

## Stop criteria

Record stop in the live-work note. Stop when all of the following hold, or when
an explicit stop decision is recorded:

- N >= 10 optimize/prove cycles completed
- gate green for the primary series and the recorded ceilings
- engineering-audit list has no remaining high-confidence candidates for the
  primary series
- primary series no longer moves above the measured noise floor

Filling N with low-ROI clone cleanups after those conditions hold is forbidden.
An episode with N < 10 is incomplete, not an accepted pressure run. Continuous
CI `--gate` does not replace a pressure-cooker episode.

## Dependency fitness escalate

When N >= 10, the gate still fails or the primary series is stuck, profiler or
stage evidence places the cost inside a third-party package, and the
engineering-audit list has no remaining high-confidence first-party
candidates for that series, stop the cooker as incomplete for ceiling write
and record `dependency fitness: fail` with the package name, series, and
evidence. Route to dependency-audit upgrade impact fitness reassessment
(replace, remove, vendor or thin fork, or narrow first-party). Do not open a
custom rewrite as an optimize cycle inside this episode.

## Report contract

Each episode records:

- started_at, finished_at, repository revision, machine class
- calibrate result (self-test command, stage values, pass/fail)
- load steps and raw samples per series
- primary series per optimize cycle
- ceilings before and after (or proposed), with propose-basis per series
- which series failed the gate
- iteration log 1..N (change, measurement, prove)
- optimizations tried and whether prove passed
- network marked `not_in_scope` when the probe never left the machine
- Memory probe class (`process_lifetime` or `isolated_stage`)

Store durable outcomes under `docs/issues/` while the work is open, then fold
accepted ceiling changes into `docs/changelogs/` when they ship.

Do not claim cheaper, smaller, faster, or greener without the samples above.
Until measured, label those claims as inference.

## Optimization discipline

- change only the named primary series; avoid broad rewrites
- re-run the failed load before declaring success
- if prove fails after tighten, either restore the previous ceiling or keep
  optimizing; do not silently widen the budget
- keep asymptotic or near-linear scaling checks green when that claim is in scope

## Binding checklist

- measure command
- self-test command (distinct known p95 per named stage)
- ceilings file path
- load axis
- samples-per-load default (>= 3)
- min episode iterations (>= 10)
- propose-basis per series and headroom
- Memory probe class
- gate / propose / write invocation
