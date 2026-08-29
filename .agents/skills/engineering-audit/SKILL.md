---
name: engineering-audit
description: >-
  Audit code with an evidence-first, pipeline-aware review format. Use for
  engineering audits, systems reviews, hot-path and Big-O analysis, pipeline
  inspection, resource and budget review, and trace and identification review.
  When the system has external services, devices, operators, or physical
  actuators, also run boundary and control mode. For every executable tree,
  also run resource and budget mode and trace and identification mode.
  Skip those two when the tree never becomes executed bytes.
---

# Engineering audit

Use when asked for an engineering audit, systems review, hot-path analysis, Big-O review, pipeline-style inspection, resource and budget review, or trace and identification review.

Read `engineering-audit.md` in this skill directory for dimensions, stage checks, boundary and control mode, finding format, and ranking. Read `resource-and-budget.md` and `trace-and-identification.md` for every tree that can execute. Skip those two files only when the tree never becomes executed bytes, and state that reason.

## Quick reference

Pipeline:

```text
ingress → app logic → cache → database → queue → worker → external API → egress
```

Order findings by danger, then certainty, then impact, then fix cost. Present the smallest credible fix before structural rewrite. Separate missing coverage from futile coverage.

When the system has external services, devices, operators, or physical actuators, also run boundary and control mode: who commands whom, interface deviations, and whether intended, commanded, reported, inferred, and physical state can diverge without an alarm.

When the product has a place the person can return to, also ask whether unknown identifiers, auth returns, forbidden, error-body status, timeouts, rate limits, 5xx survival of answers, write conflicts, system-initiated recreation, file controls, and deep links that replace in-progress work stay honest for the person and for status-based counters.

For every tree that can execute, also run resource and budget mode: measure memory, CPU, storage, network, and energy against a named ceiling; label cheaper, smaller, or greener as inference until benched. Also run trace and identification mode: which emissions identify a person or device, which observers see them, and whether they appear in what this product showed the person for this run. Skip those two modes only when the tree never becomes executed bytes.
