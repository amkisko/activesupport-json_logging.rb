# Learned-systems mode

Run this mode when the audited system uses a generative model, retrieval over a corpus, or a tool-calling agent. Skip when none of those exist, and state that reason. Keep the same finding fields.

Treat the system as data, search, prompt, model, tool, and monitoring.

## Three maps

1. User request: input → intent → guardrails → retrieve or not → rewrite → search → rerank → context → prompt → model → tool → answer → citation → log → feedback.
2. Data: source → ingest → parse → clean → chunk → metadata → embed → index → refresh → delete or version → evaluation set.
3. Failure and attacker: injection → retrieval poisoning → context override → tool abuse → exfiltration → unauthorized action → invented answer → silent degradation → missing audit.

## Architecture

Classify before judging: naive retrieval, retrieval with hybrid search and rerank, graph-augmented retrieval, agent with tools. Start simple. Add complexity when a measured failure proves the need.

## Agent artifacts

When the tree publishes skill files, prompt templates, MCP configs, or tool schemas, inventory those files. Ask whether tool descriptions are treated as untrusted; whether grants are least privilege; whether command-string parameters are unbounded; whether MCP environment settings hold live secrets; whether the server binds a public interface without authentication; whether retry or subagent depth has a named cap.

A guardrail prompt is not a security boundary. Prompt injection alone is not a finding; require a code-level boundary failure. Authorization and action binding are different controls. Model output, memory, tool descriptions, and MCP responses are untrusted input. MCP identity confusion and metadata-as-policy are findings when the tree treats a description as a grant.

Isolation claim versus blast radius: name what the agent process can actually command. A container is not isolation if it holds the runtime socket. A supervisor disabled by default does not protect ordinary runs. Ask for identical-call and no-progress ceilings, and whether compacted history still holds constraints and authorization.

Falsify a finding against the diff or source files alone, not against the same tool-augmented context that produced it.

Cite OWASP LLM01, LLM06, and the OWASP MCP Top 10 when those frames apply. Keep vendor names out of findings.

When the person asks for skill or MCP review on its own, use `agent-artifact`. When they ask to supervise a live tool-calling run, use `agent-run-supervision`.

## What to measure

Retrieval quality at k, faithfulness or groundedness, citation pass rate, tool-permission misses, evaluation-set coverage, cost per successful task, tool-call count, token count. Stakeholder copy stays free of model-vendor names unless the audience is engineering. Claims that extra supervisors improve quality by a multiplier stay inference until a benchmark demonstrates the effect.

## Skip

No generative model, retrieval corpus, or tool-calling agent: skip and say so.
