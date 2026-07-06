---
name: engineering-audit
description: Audit code with an evidence-first, pipeline-aware review format.
---

# Engineering audit

Use when asked for an engineering audit, systems review, hot-path analysis, Big-O review, or pipeline-style inspection.

Read `engineering-audit.md` in this skill directory for dimensions, stage checks, finding format, and ranking.

## Quick reference

Pipeline:

```text
ingress → app logic → cache → database → queue → worker → external API → egress
```

Order findings by danger, then certainty, then impact, then fix cost. Present the smallest credible fix before structural rewrite. Separate missing coverage from futile coverage.
