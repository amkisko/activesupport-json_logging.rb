# Upgrade resource compare

Use with the dependency-audit skill whenever a change alters the resolved package graph in a lockfile or changes a runtime pin. Automated and human upgrades use the same procedure.

This is delta evidence for one change request. Continuous absolute ceilings stay in `delivery-budgets`. Audit claims about utilization stay in engineering-audit resource and budget mode.

## When required

- any pull request or commit that changes a resolved lockfile graph or a runtime pin (language, framework, or hot-path library);
- grouped automated update pull requests: one comparison for the group, not one per package, unless packages land on separate ship paths;
- major runtime or framework hops: always; do not defer to a later soak.

Skip when a manifest edit leaves the resolved graph and shipped bytes unchanged, or when the change is a documentation-only dependency note. State the skip and the evidence used to establish it.

## Who runs what

The reviewing agent selects base and head revisions, runs the same probes on both, and returns the comparison for review. It writes to a change request or repository note only when the current request authorizes that write.

Do not switch, reset, or clean the person's active working tree. Use isolated worktrees or equivalent temporary checkouts for base and head. Record the exact revisions before running probes. Remove temporary checkouts only after confirming their paths; leave the active tree and its uncommitted changes untouched.

Measurement commands stay thin and consumer-local. The shared prayer names the series and the report contract. It does not ship a multi-ecosystem bench harness. Prefer one small command or script per consumer that prints stable machine-readable samples; the agent chooses revisions and records context.

CI may sample install size or ship-artifact size when that is cheap. Boot CPU and resident memory often need a local probe or a dedicated dual-revision job. Missing automation is not a skip of the series; gather the samples or report which series remain open.

## Series (minimum)

Measure the same series on base and head:

1. Install or graph storage - on-disk bytes of the installed package tree the product or CI actually uses (gems path, `node_modules`, language-equivalent). Record tool and path.
2. Resident memory - RSS (or documented equivalent) after a named boot or thin request path.
3. CPU time - process CPU seconds for that same path, or a stated proxy (CPU-seconds from the runner). Wall clock is allowed as a sibling signal; do not mix wall and CPU in one series.
4. Shipped bundle or image size - when the product ships bytes: the same artifact series `delivery-budgets` would gate (static bundle, container image, native binary, gem). Record compressed versus uncompressed distinctly.

Optional when the upgrade can grow caches or databases: named cache or storage growth for the same boot path. Energy or a joule meter when one exists; otherwise keep CPU-seconds as the proxy and say so.

## Probe rules

- same machine class and comparable load for base and head; alternate measurement order when repeated samples could drift with host load;
- name the probe, fixture, warmup policy, and command exactly;
- record when and where: started_at, finished_at, repository, revision (base and head), run identity or URL, host or runner class;
- prefer positive named paths (boot, login, one API resource) over whole-suite wall time as the primary CPU or memory series;
- whole-suite duration may appear as secondary context; it is not a substitute for boot or thin-path CPU and RSS;
- one deterministic byte count may be enough for a first report; say when n is 1;
- CPU, RSS, and wall-time directional claims need at least three comparable samples per revision with the raw values and a median. With n=1, report only the observed values and delta, not a cheaper, smaller, or faster conclusion.

## Report contract

Return the comparison in the requested channel. When the current request authorizes repository or forge writes, put it in the change request body and the durable upgrade note (`docs/changelogs/` or `docs/dependencies/` per docs conventions). Each series lists base value, head value, delta, unit, probe name, and machine class.

Do not claim cheaper, smaller, faster, or greener without those samples. Until measured, label such claims as inference.

If a series cannot run (missing runtime on the agent host, image build blocked), mark the comparison incomplete: state which series failed, the exact command, and the next human step. Do not drop the series silently or mark the comparison complete.

## Binding (consumer)

Record next to development process docs when the tree has local measure commands:

- command that emits install or graph storage;
- command that emits boot or thin-path CPU and RSS;
- command or CI job that emits shipped artifact size;
- where samples are stored (change request, docs path, or artifact name).

Absent a binding, the agent still runs the minimum series with explicit one-off commands and records them in the report.

## Related

- `selection-and-alteration.md` - when altering dependencies, run this compare before calling the upgrade done;
- `upgrade-impact.md` - changelog and usage map before or beside this compare; fitness reassessment when load shows a miss;
- `delivery-budgets` - absolute ship-path size and build-timing gates;
- engineering-audit resource and budget mode - utilization audit; cites these samples when present;
- `pressure-benchmarking` - load ladder, ceiling ratchet, and pressure-cooker episodes (not a one-change delta);
- `libyears.md` - freshness lag is not resource cost.
