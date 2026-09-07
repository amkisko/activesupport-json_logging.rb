---
name: dependency-audit
description: >-
  Select, alter, and audit third-party dependencies with advisory scans,
  target-scoped vulnerability assessments, and deep recon/OSINT. Use when
  adding, replacing, or removing packages; when asked to audit, review, or
  harden dependency graphs, lockfiles, or manifests; or when ordinary work
  surfaces suspicious package behavior, an advisory, a scanner match, or a
  plausible vulnerability or exploitation signal involving a package.
  Includes freshness lag (libyears or equivalent).
---

# Dependency audit

Use when adding, changing, or removing a direct dependency; when asked for a supply-chain review, lockfile health check, or whether dependencies are safe and current; or when ordinary work exposes a plausible vulnerability or exploitation signal involving a package.

Choose the smallest matching path:

- for suspicious package behavior, an advisory, scanner match, code finding, or reproducible exploit, read `references/vulnerability-assessment.md` first; stop after that assessment unless the user requested a full audit or the disposition requires graph work;
- for adding, changing, replacing, or removing a dependency, read `references/selection-and-alteration.md`;
- for a requested graph, lockfile, or supply-chain audit, read `references/dependency-audit.md`; read `references/libyears.md` when reporting maintenance lag.

## Quick reference

```text
observed security signal → target-scoped assessment → durable record
dependency change → selection and alteration checks
requested full audit → recon (OSINT) → security → freshness → ecosystem synthesis
```

Tool-only output (advisory scanner alone, outdated list alone) is a partial audit. State that explicitly when depth was limited.

Classify each package: hot path, transitive on hot path, dev or test only.

For security findings, decide target applicability before priority. Separate observed facts from inference.
