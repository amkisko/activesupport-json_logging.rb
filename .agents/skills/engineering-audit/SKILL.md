---
name: engineering-audit
description: >-
  Audit code with an evidence-first, pipeline-aware review format. Use for
  engineering audits, systems reviews, hot-path and Big-O analysis, pipeline
  inspection, resource and budget, trace and identification, product-surface,
  privacy, performance, observability, security, contract, and learned-systems
  reviews. Modes skip when they do not apply. Language- and framework-agnostic.
  When the system has external services, devices, operators, or physical
  actuators, also run boundary and control mode. For every executable tree,
  also run resource and budget mode and trace and identification mode.
  Skip those two when the tree never becomes executed bytes.
---

# Engineering audit

Use when asked for an engineering audit, systems review, hot-path analysis, Big-O review, pipeline-style inspection, resource and budget review, trace and identification review, or a product-health pass.

Read `engineering-audit.md` in this skill directory for dimensions, indicators, stage checks, boundary and control mode, optional product modes, finding format, and ranking. Read `resource-and-budget.md` and `trace-and-identification.md` for every tree that can execute. Skip those two files only when the tree never becomes executed bytes, and state that reason.

Read the matching optional file when the product has that surface: `product-surface.md`, `privacy.md`, `performance.md`, `observability.md`, `security.md`, `contracts.md`, `learned-systems.md`. Skip and state the reason when it does not. Stay on concepts. Do not require a named framework or vendor tool.

## Quick reference

Pipeline:

```text
ingress → app logic → cache → database → queue → worker → external API → egress
```

Order findings by danger, then certainty, then impact, then fix cost. Present the smallest credible fix before structural rewrite. Separate missing coverage from futile coverage. Indicators are categorizable, measurable, and representable.

When the system has external services, devices, operators, or physical actuators, also run boundary and control mode: who commands whom, interface deviations, and whether intended, commanded, reported, inferred, and physical state can diverge without an alarm.

When the product has a place the person can return to, also ask whether unknown identifiers, auth returns, forbidden, error-body status, timeouts, rate limits, 5xx survival of answers, write conflicts, system-initiated recreation, file controls, and deep links that replace in-progress work stay honest for the person and for status-based counters.

For every tree that can execute, also run resource and budget mode: measure memory, CPU, storage, network, and energy against a named ceiling; label cheaper, smaller, or greener as inference until benched. Also run trace and identification mode: which emissions identify a person or device, which observers see them, and whether they appear in what this product showed the person for this run. Skip those two modes only when the tree never becomes executed bytes.
