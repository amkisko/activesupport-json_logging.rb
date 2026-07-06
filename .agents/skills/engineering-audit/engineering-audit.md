# Engineering audit (pipeline + evidence)

Use when asked for an engineering audit, systems review, hot-path analysis, Big-O review, or pipeline-style inspection.

## Voice and prose

Structured finding fields stay as specified below. Free-form audit text stays blunt, compressed, and evidence-first. No engagement filler.

- no sales language, trend packaging, or methodology pitches;
- no negation-first hooks; state the fact and move on;
- do not repeat the same claim in positive and negative form in adjacent lines;
- prefer commas, colons, semicolons, and full stops over em dashes;
- findings destined for `docs/issues/`: plain prose, no markdown tables, bold, italic, or other styling unless the repository explicitly allows it.

## Role

Operate as a senior engineer. Treat the system as a pipeline:

```text
ingress → app logic → cache → database → queue → worker → external API → egress
```

Map each finding to a stage when relevant.

## Eight core dimensions

Scan for:

1. broken or incomplete behavior;
2. inadequate test coverage;
3. futile test coverage (distinguish explicitly from missing coverage);
4. redundancy and tangled ownership;
5. code quality and organization that hurts maintenance;
6. asymptotic and hot-path shape (N+1 queries, repeated scans, probable O(n²) regions);
7. purpose and ownership (ground dead-code claims with tree and search evidence);
8. language-native features the code fights instead of using.

## Pipeline stage checks

When the audit scope includes these layers, inspect explicitly.

Cache: key design, TTL correctness, stampede protection, invalidation ownership, whether misses amplify upstream load.

Database: N+1 queries, unbounded result sets, missing indexes, lock contention, tenant or shard skew hotspots.

Queue and worker: retry storms, poison jobs, duplicate work, drain rate versus enqueue rate, starvation, head-of-line blocking, missing backpressure, idempotency gaps.

External API: jobs orchestrate; client adapters own protocol details; retries, backoff, and idempotency tested at the correct boundary.

## Required output per finding

| Field | Content |
|-------|---------|
| Severity | critical, high, medium, low |
| Confidence | high, medium, low |
| Location | file, symbol, endpoint, queue, job, query, worker, or subsystem |
| Why it matters | short, concrete |
| Kind | observed fact vs inference |
| Smallest credible fix | minimal change that addresses the issue |
| Deeper fix | optional structural change when the small fix is insufficient |

Label every claim not proven by code, tests, logs, traces, or query plans as inference and include the exact check needed to confirm or reject it.

## Ranking

Order work by danger, certainty, impact, and fix cost. Present the smallest real fix first.

## Subsystem and hot-path mode

When inspecting a subsystem for hot paths:

1. identify likely hot paths (handlers, serializers, loops over large collections, ORM-heavy paths, workers);
2. estimate rough complexity of main loops;
3. rank fixes by likely payoff versus implementation risk;
4. no micro-optimizations without bottleneck evidence.

## Ignore

Stylistic trivia unless it harms correctness, operability, maintainability, or auditability under realistic load. Theatrical severity without evidence.

## Checklist before finishing

- findings mapped to pipeline stages where relevant;
- missing versus futile coverage separated;
- each finding has severity, confidence, location, kind, smallest fix;
- inferences label the confirming check;
- ranked by danger, certainty, impact, fix cost;
- purpose and ownership claims grounded in tree plus search evidence.
