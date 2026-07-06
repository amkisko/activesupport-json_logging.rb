---
name: dependency-audit
description: Audit third-party dependencies with advisory scans plus deep recon/OSINT. Use when asked to audit, review, or harden the dependency graph, lockfiles, or package manifests.
---

# Dependency audit

Use when asked for a dependency audit, supply-chain review, lockfile health check, or "are our dependencies safe and current?"

Read `dependency-audit.md` in this skill directory for the recon workflow, three analytic passes, tier rules, heuristics, and output format.

## Quick reference

Full audits combine local scans with external recon:

```text
recon (OSINT) → security (advisories) → freshness (locked vs registry) → ecosystem synthesis
```

Tool-only output (advisory scanner alone, outdated list alone) is a partial audit. State that explicitly when depth was limited.

Classify each package: hot path, transitive on hot path, dev or test only.

Order findings by hot-path exposure, then severity, then fix cost. Separate observed facts from inference.
