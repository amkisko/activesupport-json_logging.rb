<!-- pray:0 ignore-comments -->

# Agent context

Do not edit managed blocks in `AGENTS.md` or provisioned files under `.agents/`.
To change shared guidance, update `Prayfile` and run `pray install`.

## Shared instructions

<!-- pray:5ef025d3 -->
- when fixing or refactoring code, add or update tests first to expose the current bug/regression path (or missing contract), then implement the fix, then run focused and broader checks, and do not ship behavior changes without proving before/after via specs;
- test only executable logic and user-facing behavior; tests should affect coverage metrics;
- avoid tests that only assert implementation details; avoid file/page content/ordering/regex assertions; avoid duplicating tests;
- user interface texts should never mention implementation technical details;
- prefer files around <=150 LOC when cohesion allows, but never split coherent logic purely to satisfy line count; split only when it improves ownership, readability, and reviewability;
- do not use abbreviations and short names for variables, methods, classes, etc. unless it is a very common abbreviation or short name;
- avoid explanatory comments, but allow intent comments for non-obvious constraints, invariants, concurrency edges, or external contract requirements;
- keep the idea that code reflects user experience, so readability, structure, and clarity are product qualities, not optional polish;
- pull request description should include answers to questions: what problem is solved, why it matters, how the solution works, and any relevant context; if the change is non-trivial, include reproduction steps or a changelog entry with intent;
- pull request checklist: changelog entry with intent or reproduction steps when relevant, test coverage, and quality checks done;
- suggest updating usr/docs/changelogs with a short summary and PR link only when the change is significant enough to be mentioned; changelog files should use `usr/docs/changelogs/#{date +"%Y%m%d%H%M%S"}_<title>.md`;
- when documenting ideas, issues, user requests, new features, bugfixes, chores, etc., use `usr/docs/issues/#{date +"%Y%m%d%H%M%S"}_<title>.md`;
- validation output must list exact commands run and observed results, and never claim tests pass unless they were executed and passed;
- ignore style-only dust unless it harms correctness, operability, maintainability, or auditability under realistic load.
<!-- pray:5ef025d3 -->

<!-- pray:9f724d55 -->
- `docs/` is for human-facing documentation: setup guides, architecture, migration notes, and operator material meant for users and contributors without agent context; use stable descriptive filenames;
- `usr/docs/` is for durable agent and engineering trace alongside other project-local operator surfaces under `usr/`; keep inference input (AGENTS.md, `.agents/`) separate from human docs;
- trace files under `usr/docs/issues`, `usr/docs/plan`, `usr/docs/changelogs`, `usr/docs/meetings`, `usr/docs/dependencies`, `usr/docs/tasks`, and `usr/docs/ideas` use `YYYYMMDDHHMMSS_<kebab-case-title>.md`; no README index in those trees;
- any doc in those trace trees should make five things findable (use `##` headings or equivalent; omit empty sections): **Participants** (who was involved), **Decisions** (what was agreed), **Effects** (done, failed, recovered, rolled back), **Next** (todo, planned, open questions), **Source** (links upstream—meeting, issue, PR, commit—and downstream materializations); git history is the edit log; add an explicit note only when a later pass changes meaning (scope cut, rollback, decision reversed);
<!-- pray:9f724d55 -->

<!-- pray:062b8a8e -->
## Dependency issues

When work surfaces a clearly visible bug or defect in a dependency — wrong behavior, broken API contract, regression between versions, or a fix already merged upstream but not released — say so in the task output and suggest a concrete fix path: upgrade, pin, patch, vendor, workaround, or upstream report.

Store evidence under `usr/docs/dependencies/#{YYYYMMDDHHMMSS}_<kebab-case-title>.md`; no README index in that tree. Each file should make these findable (use `##` headings or equivalent; omit empty sections): **Dependency** (name, version constraint, lockfile entry if any), **Symptom** (what breaks and where), **Evidence** (repro steps, logs, stack traces, links to issues or commits), **Suggested fix** (upgrade, pin, patch, workaround, or upstream report), **Next** (todo, planned, open questions), **Source** (links upstream—issue, PR, release note, commit—and downstream materializations in this repo). Git history is the edit log.

Do not open drive-by dependency hunts; record only issues encountered while doing the requested work and only when the defect is evident from behavior or published upstream facts, not speculation.

For proactive selection, alteration, and audit rules, use `dependency-policy` and the dependency-audit skill.
<!-- pray:062b8a8e -->

<!-- pray:33096566 -->
## Dependency policy

Rules for adding, changing, or removing third-party packages. Apply across languages (Ruby, Rust, Elixir, JavaScript, and others). Names vary by ecosystem; concepts do not.

Terminology:

- package manifest — declares intent (`gemspec`, `package.json`, `Cargo.toml`, `mix.exs`, etc.)
- lockfile — pins the resolved graph CI and developers install
- registry — published versions consumers resolve (`RubyGems`, `npm`, `crates.io`, `Hex`, etc.)
- hot path — code on the security, auth, crypto, IO, or request/response boundary users rely on

### Before adding a dependency

Stop until one of these applies:

- stdlib or the framework for this tree already covers it;
- an installed transitive dependency already covers it without a second library for the same job;
- the feature genuinely needs a new package and tests will prove behavior.

Then prefer packages that:

- share a trusted maintainer cluster and spec family with dependencies already on the hot path (same author group, same protocol stack, same RFC family);
- align with the domain protocol being implemented (do not bolt on a parallel HTTP client, JWT stack, or crypto helper when the main stack already carries one);
- show real adoption on the registry and recent maintenance (commits and published versions; registry publish date matters when upstream release tags lag);
- keep bus factor visible: a coherent maintainer cluster is good for integration; a lone micro-package on a hot path is a supply-chain risk unless adoption and release cadence are strong.

Reject or defer when:

- the capability duplicates an existing node in the graph;
- issues-per-star and open pull request backlog suggest maintainer strain on a small package;
- a major version adds native extensions or platform matrices the CI matrix does not exercise;
- license or export-control terms conflict with product use.

### When altering dependencies

- run advisory scans on every lockfile or variant graph CI installs (root lockfile alone is not enough when matrix gemfiles, workspaces, or target-specific locks exist);
- keep hot-path and direct runtime packages at the latest safe registry version unless a documented exception explains the pin;
- tighten package manifest floors when security fixes require a minimum version; lockfiles protect this repo, manifests protect downstream consumers;
- on major upgrades, grep for adapters (HTTP mocks, test doubles, middleware, FFI shims) and run the full CI matrix;
- delete redundant packages when a transitive or cluster dependency subsumes them; wrap remaining vendor exceptions at trust boundaries with project error types, not raw vendor exceptions in user-facing paths;
- list exact commands and observed results in validation output; never claim a clean audit without running it.

### Automation

- gate CI on advisory checks for the ecosystems that exist in the repository; drop automated update config for ecosystems with no manifest;
- use grouped automated update pull requests for lockfiles; human review still applies selection rules above;
- run the dependency-audit skill when asked for a dependency audit, before a release that changes hot-path packages, or after a published advisory names a package in the graph.

Full dependency audits rely on deep recon and OSINT, not only lockfile scanners. Automated advisory and outdated checks are necessary baseline; they are not sufficient for hot-path packages or for add/replace decisions.

### Relationship to other prayers

- `dependency-issues` — record upstream defects encountered during real work; do not open drive-by hunts;
- `minimal-implementation` — no new dependency when an existing path suffices;
- `engineering-audit` — code and pipeline review; dependency-audit focuses on the supply graph.
<!-- pray:33096566 -->

<!-- pray:7c468b51 -->
- test coverage must follow @spec/README.md guidelines;
- use ruby and Rails features according to the codebase versions;
- follow ruby and Rails coding conventions, principles, and best practices;
- never put data migrations in schema migrations, use the db/data_migrations pattern instead;
<!-- pray:7c468b51 -->

<!-- pray:b2a3d4d7 -->
## Minimal implementation

Efficient means the smallest correct change, not careless or under-tested.

Before writing code, stop at each step until one applies:
- does the feature need to exist at all (YAGNI)?
- does the language stdlib or framework for this tree already cover it?
- does an existing implementation or dependency already solve it?
- can the change be one line; if so, make it one line?
- only then write the minimum code that works.

Rules:
- match the language of the directory you are changing (see Preferred stack and tools above);
- no abstractions unless the request or clear reuse needs them;
- no new dependency when stdlib, the framework for this tree, or an installed dependency suffices;
- no boilerplate the task did not ask for;
- deletion over addition; boring over clever; fewest files that stay readable (see file size guidance above);
- when a request sounds overbuilt, ask whether a simpler existing path already covers it;
- when two stdlib approaches are the same size, pick the edge-case-correct one; less code is not an excuse for a flimsier algorithm;
- document deliberate shortcuts with an intent comment: name the known ceiling (global lock, O(n²) scan, naive heuristic) and the upgrade path when that ceiling matters.

Not optional even when minimizing scope:
- input validation at trust boundaries;
- error handling that prevents data loss;
- security and accessibility (see UI/UX checks);
- calibration against real hardware and production drift when the platform ideal is not the spec;
- anything explicitly requested in the task or ticket;
- tests for non-trivial behavior per @spec/README.md and the testing bullets above; trivial one-liners need no new spec.
<!-- pray:b2a3d4d7 -->

<!-- pray:2b9051df -->
## Finite state machines

- model lifecycles with explicit finite state machines when status, allowed transitions, and side effects matter; prefer named states and guarded transitions over scattered conditionals and implicit enums alone;
- finite state machines are not only for workflow logic: they can compactly represent ordered sets or maps of strings supporting fast prefix, suffix, and fuzzy search; consider tries and automata when matching catalogs, codes, routes, or searchable vocabularies at scale.
<!-- pray:2b9051df -->

<!-- pray:7317586a -->
## Branch naming

Use kebab-case after the prefix.

Prefixes:

- `feature/<title>` — new capability
- `patch/<title>` — bugfix or chore
- `trunk/<title>` — release candidate or integration work before `main`
- `plan/<title>` — exploration or ideation

Examples:

- `feature/user-access-control`
- `patch/fix-translation`
- `trunk/2026w15`
- `trunk/2026-august-pack`
- `plan/auth-redesign-notes`
- `plan/2026-q2-roadmap`
<!-- pray:7317586a -->

<!-- pray:6aea78d0 -->
## Preferred stack and tools

- native-first approach for all platforms and languages
- ruby for web application and API development, and for its rich ecosystem of libraries and frameworks
- elixir for concurrent and distributed systems, and for its actor model and fault tolerance
- rust for system programming and performance-critical code
- javascript, html, css for native browser experience
- humane and accessible design principles for UI/UX, and for clear communication of intent and feedback
<!-- pray:6aea78d0 -->

<!-- pray:c7597e52 -->
## Writing and changelog prose checks

Read once for marketing odor, once for negation-led sentences, once for stray em dashes, and once for paragraphs that break on clause instead of on scene; keep live notes and metadata honest and plain.
- repo trace under usr/docs/issues, usr/docs/tasks, and usr/docs/changelogs: plain prose readable without a rendered preview—no markdown tables, bold, italic, or other styling; prioritize factual accuracy over presentation.
<!-- pray:c7597e52 -->

<!-- pray:8cf2baf2 -->
## Likely rejected changes

- features whose complexity outweighs user value
- giant refactors
- non-trivial changes without tests
- style-only rewrites without behavior change
- AI-generated-looking code the author does not understand
<!-- pray:8cf2baf2 -->

<!-- pray:e662c764 -->
## Checks before publish (engineering)

Verify the change is wanted, discuss first for unconfirmed larger features, describe what problem is solved and why it matters, include tests, add screenshots or screen recordings for UI changes, keep one PR to one concern, and understand any AI-assisted code you submit.
<!-- pray:e662c764 -->

<!-- pray:0b30e782 -->
## Collaboration workflow

- keep human-facing documentation in `docs/`;
- keep durable agent and engineering trace in `usr/docs/`; use folders such as `usr/docs/changelogs`, `usr/docs/issues`, `usr/docs/plan`, `usr/docs/tasks`, and `usr/docs/ideas`;
- agent-assisted work with ongoing project value must leave a trace in the repo;
- store only specific, decision-bearing, high-signal material; do not commit generic notes, copied chat logs, or filler;
- use the lightest process that preserves traceability; design-only work does not need branch ceremony unless implementation work starts.
<!-- pray:0b30e782 -->

<!-- pray:5f23b29e -->
## Shared prayers

This project uses [pray](https://github.com/kiskolabs/pray) to install and lock shared inference input from the amkisko prayers distribution.

Install the CLI:

```sh
cargo install --git https://github.com/kiskolabs/pray --locked pray
```

Initialize or update managed input:

```sh
pray install
pray plan
pray apply
pray verify
```

Declare dependencies in `Prayfile`. Do not edit managed spans in `AGENTS.md` or `.agents/skills/`.

To refresh shared guidance after publishers release new versions:

```sh
pray update
pray plan
pray apply
```

Distribution source for amkisko-wide packages: [amkisko/prayers](https://github.com/amkisko/prayers).
<!-- pray:5f23b29e -->
