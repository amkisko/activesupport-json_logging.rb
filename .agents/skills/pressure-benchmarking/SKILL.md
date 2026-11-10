---
name: pressure-benchmarking
description: >-
  Calibrate meters, raise load, ratchet resource ceilings, and run at least
  ten optimize/prove pressure-cooker cycles against named series. Use when
  asked for pressure benchmarking, load stepping, resource ratchet,
  performance pressure testing, delivery budget tighten, or a pressure cooker
  optimize loop. Do not use for one-shot upgrade deltas, continuous ship-path
  CI budgets alone, or pure documentation edits with no executable path.
---

# Pressure benchmarking

## When to use

Use when the person asks to raise load, tighten resource budgets, prove a hot
path stays near-linear, or drive optimizations against measured ceilings
rather than intuition.

Skip for pure documentation or contract edits with no executable path, and say
so. Route one-change dependency base/head deltas to dependency-audit upgrade
resource compare. Route continuous ship-path absolute size and build-timing
gates to `delivery-budgets`. Route utilization review claims to engineering-audit
resource and budget mode. When the primary series remains inside a dependency
after cooker rules and no high-confidence first-party candidate remains, record
dependency fitness failure and route to dependency-audit upgrade impact
(fitness reassessment); do not invent a custom replacement inside this skill.

## Quick reference

```text
calibrate meter -> baseline -> stress -> tighten -> (optimize -> prove) x N -> accept|rollback
```

Rules that fail the episode if skipped:

- calibrate before baseline (stage-distinct self-test; uncalibrated is not a baseline)
- name one primary series before each optimize cycle; change only that series until prove
- samples-per-load >= 3 for gate, propose, and write; n=1 is observe only
- episode iterations N >= 10 before accept (pressure cooker); one green prove is not enough
- do not claim stage RSS without an isolated probe

Read `references/pressure-loop.md` before changing ceilings or claiming cheaper.
Read `references/known-practices.md` for layered gates, noise floor, and stop criteria.

## Binding (consumer)

Record next to development process docs when the tree has local measure commands:

- measure command that prints stable samples
- self-test command with distinct known p95 per named stage
- ceilings file path
- load axis definition
- samples-per-load default (>= 3)
- min episode iterations (>= 10)
- propose-basis per series (`median` or `max`, times headroom; default headroom 1.15)
- Memory probe class (`process_lifetime` or `isolated_stage`)
- gate / propose / write command flags

Absent a binding, the agent still runs calibrate and the minimum series with
explicit one-off commands and records them in the live-work note.

## Related

- engineering-audit resource and budget mode - utilization claims; prioritized candidates for the loop
- engineering-audit performance mode - wait-time claims
- dependency-audit upgrade resource compare - base/head deltas for lockfile or runtime-pin changes
- dependency-audit upgrade impact - fitness reassessment when load shows a dependency miss
- delivery-budgets - continuous ship-path absolute size and build-timing gates
