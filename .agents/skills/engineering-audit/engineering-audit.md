# Engineering audit (pipeline + evidence)

Use when asked for an engineering audit, systems review, hot-path analysis, Big-O review, pipeline-style inspection, resource and budget review, or trace and identification review. When the system talks to external services, devices, operators, or physical actuators, also run boundary and control mode below. For every tree that can execute, also run resource and budget mode and trace and identification mode. Skip those two only when the tree never becomes executed bytes, and state that reason.

## Voice and prose

Structured finding fields stay as specified below. Free-form audit text stays blunt, compressed, and evidence-first. No engagement filler.

- no sales language, trend packaging, or methodology pitches;
- no negation-first hooks; state the fact and move on;
- do not repeat the same claim in positive and negative form in adjacent lines;
- prefer commas, colons, semicolons, and full stops over em dashes;
- findings destined for `usr/docs/issues/`: plain prose, no markdown tables, bold, italic, or other styling unless the repository explicitly allows it.

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

## Systems lens

Ask where work waits, repeats, bottlenecks, or amplifies; where load skews; where latency spikes or throughput caps; where idempotency or bounds are missing.

## Boundary and control mode

Run this mode when the audited system has external services, devices, operators, or physical actuators. Skip it for a library with no IO. Keep the same finding fields. Optional extra fields when they help: who commanded what; how the command went wrong (missing, harmful, mistimed, held too long); which state (intended, commanded, reported, inferred, physical).

Shared trust matters more than how many integrations you count. One identity or unlock service that every actuator trusts fails everyone together; many independent read-only feeds usually do not.

Sketch who commands whom, what feedback returns, and who is allowed to command a physical or identity-changing action. Then for each command (send, unlock, bind identity, show results, type a device message):

- required command not sent;
- harmful command sent;
- sent too early, too late, duplicated, or out of sequence;
- applied too long or stopped too soon.

At each interface, try: no message, duplicate, stale, late, wrong identity, wrong unit or encoding, wrong destination, other than the intended device or person.

Name five states when they can diverge without an alarm: intended, commanded, reported, inferred, observed physical. Software consensus against a disagreeing physical process is higher danger than a clean crash.

Ask whether any safety check is independent of the integration it polices. A freeze, match, or occupancy bit that lives inside the same shop or device path only checks that path.

Ask about hazards from a correctly functioning dependency whose assumptions are false: label uniqueness, occupancy listing freshness, a sensor or classifier outside its training conditions.

Ask who remains operational after partial failure, and whether two commanders can both believe they own the same lock, order, or identity.

A logically valid command that moves a lock, types a scale, or labels a sample is a safety and privacy event. Hand spoofable identity keys and missing TLS verify to security review.

Human: can an operator or customer act on a stale or colliding label, tell empty, occupied, refused, or never-synced apart, and still operate on the place they used (URL, document, screen, command, query) after a refusal.

When the product has a place the person can return to, also ask:

- unknown identifier served as a successful document;
- auth return URL that can open-redirect;
- signed-in 403 bounced to login;
- a recovery action that confirms a resource a 404 was meant to hide;
- error-body status that disagrees with the HTTP line;
- delayed redirect with no chance to stay;
- deep link or navigation that replaces in-progress work without a chance to stay;
- ephemeral notice or a replacement home as the only blocking-error surface;
- error replaces the document or screen and drops the place and answers;
- timeout that deletes answers without saying so;
- edge or log pipeline that counts 403/404 by an error-document path instead of by the client request;
- rate limit returned as 503 instead of 429;
- 5xx or shutter page that does not say whether in-progress answers survived;
- write conflict that wipes the draft;
- system-initiated recreation that drops the screen and in-progress answers;
- file control empty after other fields fail.

Related: `io-simulation` injects those interface faults in a plant; `finite-state-machines` names digital and physical lifecycles; `keep-the-work` keeps that place and in-progress work usable after a refusal.

## Resource and budget mode

Run this mode for every audited tree that can execute. Skip only when the tree never becomes executed bytes, and state that reason. Keep the same finding fields. Procedure in `resource-and-budget.md` in this skill directory.

## Trace and identification mode

Run this mode for every audited tree that can execute. Skip only when the tree never becomes executed bytes, and state that reason. Keep the same finding fields. Procedure in `trace-and-identification.md` in this skill directory. Quantity of traces stays in resource and budget; this mode asks who those emissions identify.

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
4. no micro-optimizations without bottleneck evidence; time, memory, CPU, storage, network, and energy claims need a bench or stay inference.

## Ignore

Stylistic trivia unless it harms correctness, operability, maintainability, or auditability under realistic load. Theatrical severity without evidence.

## Checklist before finishing

- findings mapped to pipeline stages where relevant;
- boundary mode run when external services, devices, operators, or actuators exist, or explicitly skipped with reason;
- resource mode run for an executable tree, or skipped with reason when the tree never executes;
- trace and identification mode run for an executable tree, or skipped with reason when the tree never executes;
- cheaper, smaller, or greener claims labeled with the bench or marked inference; mixed compressed versus uncompressed numbers called out; energy or a stated proxy named;
- identity claims labeled with the bench (HAR, disk, logs, SDK init) or marked inference;
- missing versus futile coverage separated;
- each finding has severity, confidence, location, kind, smallest fix;
- inferences label the confirming check;
- ranked by danger, certainty, impact, fix cost;
- purpose and ownership claims grounded in tree plus search evidence.
