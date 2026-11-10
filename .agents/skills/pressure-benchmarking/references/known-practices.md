# Known practices

Principles that back the pressure loop. House MUST rules live in
`pressure-loop.md`. This file is rationale only; do not name vendor products,
tool brands, or persons as authorities.

## Meter truth before optimize

A wrong parser turns twenty optimize cycles into fiction. Calibrate with
stage-distinct fixtures before baseline. Missing meters and uncalibrated
meters are incomplete, not green.

## Observe, set headroom, validate, write

Establish a baseline from measured values, add named headroom, re-run until
stable, then promote deliberately. Do not auto-promote the last green run as
the fixed baseline. Absolute ceilings, comparison to a promoted baseline, and
optional trend or change-point detection are three layers; continuous absolute
gates alone miss slow drift under the limit.

## Noise floor

Run the same build against itself enough times to see ordinary spread before
tight claims. Directional claims need at least three samples. Prefer five to
ten when characterizing noise for tolerance. Percentage cushions that hide
real change waste the gate; cushions tighter than measured noise create
flakes. Statistical or change-point detectors can separate persistent shifts
from transient spikes; they remain optional related practice, not a house
dependency.

## One change, remeasure

Profile or measure, form one hypothesis, change one thing, remeasure under the
same load. End-to-end gain is capped by the fraction of time the change
touches. Stop when expected gain sits under the noise floor and the audit list
has no high-confidence primary candidates. Pressure cooker means many of these
loops (N >= 10), not one.

## Load patterns

Step or capacity tests raise load in plateaus and find inflection points.
Soak holds steady load over time for leaks and drift. Spike and stress probe
failure modes and recovery. The pressure loop owns step/capacity plus ceiling
ratchet. Do not treat soak duration as a substitute for optimize/prove
iterations, or spike as a substitute for a calibrated meter.

## Ownership siblings in this house

- `delivery-budgets` - continuous absolute ship-path size and build-timing CI gates
- dependency-audit upgrade resource compare - one-change base/head deltas
- dependency-audit upgrade impact - changelog usage map and fitness reassessment after a measured dependency miss
- engineering-audit resource and budget - utilization audit claims and candidate lists
- this skill - calibrate, load ladder, ceiling ratchet, pressure cooker; escalate dependency fitness failures, do not decide custom replacements here

## Session failure mode to avoid

Trusting a harness output without a stage-distinct self-test produced false
stage p95 history and misleading ceiling proposals until the parser was
fixed. Calibrate first. Name propose-basis per series in one place. Gate and
write only with n >= 3. Name a primary series before each optimize cycle.
