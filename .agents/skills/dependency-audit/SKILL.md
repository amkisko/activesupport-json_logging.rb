---
name: dependency-audit
description: >-
  Select, alter, and audit third-party dependencies with advisory scans plus
  deep recon/OSINT. Use when adding, replacing, or removing packages, or when
  asked to audit, review, or harden the dependency graph, lockfiles, or
  package manifests. Includes freshness lag (libyears or equivalent) alongside
  locked-versus-registry comparison.
---

# Dependency audit

Use when adding, changing, or removing a direct dependency, or when asked for a supply-chain review, lockfile health check, or whether dependencies are safe and current.

Read `references/selection-and-alteration.md` for prefer/reject rules, alteration checks, and automation. Read `references/dependency-audit.md` for recon workflow, analytic passes, tier rules, and output format. Read `references/libyears.md` when reporting maintenance lag (libyears or equivalent).

## Quick reference

```text
stop-before-add → selection rules → recon (OSINT) → security → freshness (including lag metrics) → ecosystem synthesis
```

Tool-only output (advisory scanner alone, outdated list alone) is a partial audit. State that explicitly when depth was limited.

Classify each package: hot path, transitive on hot path, dev or test only.

Order findings by hot-path exposure, then severity, then fix cost. Separate observed facts from inference.
