# Learned-systems mode

Run this mode when the audited system uses a generative model, retrieval over a corpus, or a tool-calling agent. Skip when none of those exist, and state that reason. Keep the same finding fields.

Treat the system as data, search, prompt, model, tool, and monitoring.

## Three maps

1. User request: input → intent → guardrails → retrieve or not → rewrite → search → rerank → context → prompt → model → tool → answer → citation → log → feedback.
2. Data: source → ingest → parse → clean → chunk → metadata → embed → index → refresh → delete or version → evaluation set.
3. Failure and attacker: injection → retrieval poisoning → context override → tool abuse → exfiltration → unauthorized action → invented answer → silent degradation → missing audit.

## Architecture

Classify before judging: naive retrieval, retrieval with hybrid search and rerank, graph-augmented retrieval, agent with tools. Start simple. Add complexity when a measured failure proves the need.

## What to measure

Retrieval quality at k, faithfulness or groundedness, citation pass rate, tool-permission misses, eval-set coverage, cost per successful task. Stakeholder copy stays free of model-vendor names unless the audience is engineering.

## Skip

No generative model, retrieval corpus, or tool-calling agent: skip and say so.
