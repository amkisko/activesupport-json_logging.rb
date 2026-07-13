# Dependency audit (recon + security + freshness + ecosystem)

Use when asked to audit dependencies, review lockfiles, assess supply-chain risk, or decide whether upgrades are safe.

Read `dependency-policy` in the shared prayers fragment for selection and alteration rules this audit enforces.

## Voice and prose

Evidence-first. List exact commands, queries, and URLs consulted. Never claim advisories are clean, versions current, or maintainers healthy without gathered evidence.

- no drive-by dependency hunts when the task is unrelated;
- separate hot-path findings from dev-only lag;
- label OSINT inference (stars, issue ratios, maintainer overlap) as heuristic with confidence;
- findings for `usr/docs/issues/` or `usr/docs/dependencies/`: plain prose per docs conventions.

## Role

Operate as a supply-chain reviewer with recon discipline. Map each finding to:

```text
recon sources → selection → manifest contract → lockfile snapshot → CI matrix → hot-path runtime → dev/test tooling
```

## Audit depth

| Depth | What it covers | When enough |
|-------|----------------|-------------|
| Baseline | advisory scan + outdated on root lockfile | never for a requested full audit |
| Standard | all CI lockfiles + registry latest for direct runtime | security-only follow-up |
| Full | baseline + standard + OSINT on every hot-path direct and transitive package | default for "audit dependencies" |

State the depth reached. If only baseline ran, call it partial.

## Pass 0 — Deep recon and OSINT

Goal: gather external intelligence about packages in the graph before synthesizing risk. Run this pass for full audits. Scale effort by tier.

### Sources (use what the ecosystem exposes)

Adapt names; concepts are universal.

- registry API — latest version, publish date, download counts, homepage, source URI, license, maintainers;
- upstream source host — last push, default branch, open issues, open pull requests, release tags, contributor count;
- advisory feeds — ecosystem advisory DB, GHSA, CVE, vendor security advisories;
- issue and pull request search — recent security-related threads, unfixed regressions, release-blocking bugs;
- release notes and changelog — breaking changes, security sections, migration cost;
- dependency graph of the upstream package — what it pulls in; overlap with your graph;
- maintainer identity — authors, org membership, overlap across your hot-path packages (trusted cluster vs lone maintainer);
- license and export metadata — SPDX, COPYING, patent or export notices when relevant;
- automation config in the consumer repo — CI advisory gates, dependabot ecosystems, dead bot targets.

### Recon actions by tier

Hot path direct and hot path transitive — for each package:

1. resolve canonical upstream repository from registry metadata;
2. collect activity signals: last commit, last registry publish, latest release tag date;
3. collect strain signals: open issues, open pull requests, issues-per-star;
4. collect adoption signals: download or dependent counts when published;
5. map maintainer cluster: same org or author as sibling packages in your stack;
6. check for duplicate capability in your graph;
7. read recent advisories and open security issues, not only the advisory DB snapshot;
8. note native extension or multi-platform cost when the registry ships platform gems or FFI.

Dev and test only — lighter pass unless advisory DB flags them: registry latest, advisory status, obvious abandonment (no push over ~12 months and meaningful open backlog).

### OSINT synthesis rules

- trusted maintainer cluster: prefer packages whose maintainers and protocol family match the existing hot path; record bus-factor tradeoff when the cluster is one person or org;
- registry publish date beats stale upstream release tags when they disagree;
- high issues-per-star on a small repo is a maintenance-pressure signal, not proof of bugs;
- low downloads on a hot-path micro-package is a supply-chain signal;
- inference must name the source checked and what was not checked.

### Recon output minimum

For each hot-path package audited, report:

- locked version and registry latest;
- upstream repo and last push age;
- open issues and open pull requests (counts);
- adoption metric when available;
- maintainer cluster note (who else in your graph they align with);
- watch / healthy / concern classification with confidence;
- links or identifiers for sources consulted.

## Pass 1 — Security (advisories)

Goal: zero known advisories on every graph CI installs.

Actions (adapt to ecosystem):

- refresh the advisory database and scan root lockfile or equivalent;
- scan each variant lockfile, workspace member, or appraisal gemfile the CI matrix resolves;
- note manifest minimum versions that still allow vulnerable ranges for downstream consumers;
- cross-check hot-path packages against GHSA or vendor advisories when the ecosystem DB lags.

Report: advisory id, affected package, locked version, fixed version, hot-path tier, source URL when available.

## Pass 2 — Freshness (locked vs registry)

Goal: direct runtime and hot-path transitive packages at latest published safe version.

Actions:

- compare locked versions to registry latest for direct runtime dependencies;
- run outdated tooling where the ecosystem provides it; filter noise from dev-only tooling unless it blocks upgrades;
- flag major-version lag and document adapter risk (test mocks, native extensions, breaking API renames);
- use recon publish dates when release tags are stale.

Report: package, locked, latest, gap type (patch, minor, major), tier.

## Pass 3 — Ecosystem synthesis

Goal: combine OSINT signals into actionable watch items before they become security lag.

Synthesize recon data; do not re-query blindly. Heuristics (inferential; state confidence):

| Signal | Healthy read | Watch read |
|--------|--------------|------------|
| Last commit / push | within ~90 days on hot-path deps | over ~180 days with open security-relevant issues |
| Registry publish vs upstream tag | publish date recent | active commits but no publish in ~12 months |
| Open issues per star | under ~5% on small repos | over ~10% with slow merge rate |
| Open PR backlog | low or steady merge | large backlog on a small repo |
| Downloads / dependents | high or clear niche | micro-package on hot path with low adoption |
| Maintainer cluster | same trusted group as existing stack | lone maintainer for critical protocol piece |

Also confirm:

- duplicate capability: two packages for the same job (encrypt, HTTP, JWT, logging);
- native / platform surface: FFI, musl/gnu, alternate language runtimes, cross-compile targets in CI;
- test and mock adapter coupling on major upgrades (discovered during recon or upgrade attempt).

## Tier classification

Apply every rule with tier in mind.

| Tier | Examples | Audit strictness |
|------|----------|------------------|
| Hot path direct | auth, crypto, HTTP client, framework core, RPC | recon mandatory; advisories zero; latest safe version |
| Hot path transitive | OAuth client, JWT, TLS, serializer on boundary | recon mandatory; advisories zero; upgrade with parent or explicitly |
| Dev / test only | linter, test framework, local server, coverage | advisories if installed; recon light unless flagged |
| Automation | CI actions, release tooling | pin hygiene; upstream release notes on bump |

## Required output per finding

| Field | Content |
|-------|---------|
| Tier | hot path direct, hot path transitive, dev/test, automation |
| Kind | recon, security, freshness, ecosystem, policy, automation gap |
| Severity | critical, high, medium, low |
| Confidence | high, medium, low |
| Package | name and locked version |
| Why it matters | one concrete sentence |
| Kind of evidence | observed (command output, API response) vs inference (heuristic) |
| Sources | advisory id, registry URL, repo, issue link, or command run |
| Smallest fix | bump lock, tighten manifest floor, remove duplicate, add CI gate, pin with documented reason |
| Deeper fix | cluster consolidation, vendor/fork, replace package |

## Ranking

Order work by: hot-path exposure, advisory severity, recon watch items on security-sensitive packages, freshness gap, fix cost.

Present manifest floor and lockfile bump together when consumers could resolve vulnerable ranges.

## Selection checks (when audit recommends adding or replacing)

Before recommending a new package, verify with recon:

1. no stdlib, framework, or transitive path already covers it;
2. maintainer cluster and protocol alignment with existing stack;
3. no duplicate stack introduced;
4. adoption, release cadence, and issue velocity acceptable for the tier;
5. CI matrix can absorb native or platform cost;
6. license and upstream source are trustworthy after OSINT pass.

## Alteration checks (when audit recommends upgrades)

1. advisory-clean after bump across all CI graphs;
2. recon confirms upstream is actively maintained or pin is deliberate;
3. tests and adapters updated for major versions;
4. manifest floors updated when needed;
5. vendor exceptions wrapped at boundaries;
6. automation config matches existing ecosystems only.

## Automation expectations

A mature repo should have most of:

- advisory scan in CI before tests;
- local make or script target mirroring CI audit;
- automated lockfile updates for declared ecosystems;
- no bot config for ecosystems without manifests.

Call out missing gates explicitly. Automation does not replace Pass 0 recon for full audits.

## Relationship to dependency-issues

During implementation work, record clear upstream defects under `usr/docs/dependencies/` per the dependency-issues prayer. This audit pass is proactive graph review with recon; dependency-issues is reactive evidence from real tasks.

## Ignore

Dev-only minor lag on linters and test helpers when advisories are clean and runtime is current. Style preferences about package managers. Maintainer intent without issue, commit, release, or registry evidence. Treating a single advisory scan as a complete audit when the user asked for full dependency health.
