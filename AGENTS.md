<!-- pray:0 ignore-comments -->

# Agent context

Do not edit managed blocks in `AGENTS.md` or provisioned files under `.agents/`.
To change shared guidance, update `Prayfile` and run `pray install`.

## Shared instructions

<!-- pray:9068e4a2 -->
- when fixing or refactoring code, add or update tests first to expose the current bug/regression path (or missing contract), then implement the fix, then run focused and broader checks, and do not ship behavior changes without proving before/after via specs;
- test only executable logic and user-facing behavior; tests should affect coverage metrics;
- avoid tests that only assert implementation details; avoid file/page content/ordering/regex assertions; avoid duplicating tests;
- user interface texts should never mention implementation technical details;
- prefer files around <=150 LOC when cohesion allows, but never split coherent logic purely to satisfy line count; split only when it improves ownership, readability, and reviewability;
- do not use abbreviations and short names for variables, methods, classes, etc. unless it is a very common abbreviation or short name;
- avoid explanatory comments, but allow intent comments for non-obvious constraints, invariants, concurrency edges, or external contract requirements;
- keep the idea that code reflects user experience, so readability, structure, and clarity are product qualities;
- pull request description should include answers to questions: what problem is solved, why it matters, how the solution works, and any relevant context; if the change is non-trivial, include reproduction steps or a changelog entry with intent;
- pull request checklist: changelog entry with intent or reproduction steps when relevant, test coverage, and quality checks done;
- follow docs-conventions for usr/docs trace filenames and layout;
- validation output must list exact commands run and observed results, and never claim tests pass unless they were executed and passed;
- ignore style-only dust unless it harms correctness, operability, maintainability, or auditability under realistic load.
<!-- pray:9068e4a2 -->

<!-- pray:781b7711 -->
## Credentials and Secrets

- Prefer a secret store or OS credential helper over embedding live secrets in config files, scripts, or documentation. Named managers (for example 1Password, Bitwarden, KeePassXC) are fine; the requirement is isolation, not a specific vendor.
- Config and project files may hold references (vault paths, item ids, redacted fingerprints). They must not hold live tokens, API keys, passwords, or client secrets.
- Do not pass secrets on command lines or in other process-visible arguments. Prefer secret-store lookup, short-lived credentials, or stdin/file descriptors that do not persist in shell history.
- Do not commit secrets, paste them into issues or pull requests, or write them to logs. Rotate anything that may have been exposed.

## Tracking and identification

- A redacted fingerprint above is a hash of a secret for config references. A device fingerprint is fields that combine to identify a person or device across sessions or observers.
- Identifiers, IP addresses, device marks, and combined attributes are personal data. They can unmask a person, a location, or a session secret. Emit them only when the feature they asked for this session needs them and they were shown that this product would.
- Silent analytics ids, leftover marks after logout, and canvas or hardware probes are security events. They can locate a person, stitch sessions, or leak a credential-shaped token.
<!-- pray:781b7711 -->

<!-- pray:bfe6ff38 -->
- `docs/` is for human-facing documentation: setup guides, architecture, migration notes, and operator material meant for users and contributors without agent context; use stable descriptive filenames;
- `usr/docs/` is for durable agent and engineering trace alongside other project-local operator surfaces under `usr/`; keep inference input (AGENTS.md, `.agents/`) separate from human docs;
- four timestamp trees, no README index, filename `YYYYMMDDHHMMSS_<kebab-case-title>.md`: `issues` (live work: contract, findings, open next; pitch, plan, and queue stay here), `changelogs` (what shipped), `meetings` (one sitting: who was there and what they agreed), `dependencies` (upstream defects from real work);
- issues, changelogs, and meetings make five things findable (use `##` headings or equivalent; omit empty sections): **Participants** (humans only; omit agents, tools, and binaries), **Decisions** (what was agreed), **Effects** (done, failed, recovered, rolled back), **Next** (todo, planned, open questions), **Source** (links upstream: meeting, issue, PR, commit, and downstream materializations); git history is the edit log; add an explicit note only when a later pass changes meaning (scope cut, rollback, decision reversed);
- mention software, tools, agents, or binaries in a note only when that detail is needed for execution or later analysis; put it under Decisions, Effects, or Source, not under Participants;
- never put local absolute paths or private material in `docs/` or `usr/docs/`: no home-directory or machine-specific filesystem paths, secrets, credentials, tokens, API keys, or personal private data; prefer repository-relative paths;
<!-- pray:bfe6ff38 -->

<!-- pray:edcc5f67 -->
## Dependency issues

When work surfaces a clearly visible bug or defect in a dependency (wrong behavior, broken API contract, regression between versions, or a fix already merged upstream but not released), say so in the task output and suggest a concrete fix path: upgrade, pin, patch, vendor, workaround, or upstream report.

Store evidence under `usr/docs/dependencies/#{YYYYMMDDHHMMSS}_<kebab-case-title>.md`; no README index in that tree. Each file should make these findable (use `##` headings or equivalent; omit empty sections): **Dependency** (name, version constraint, lockfile entry if any), **Symptom** (what breaks and where), **Evidence** (repro steps, logs, stack traces, links to issues or commits), **Suggested fix** (upgrade, pin, patch, workaround, or upstream report), **Next** (todo, planned, open questions), **Source** (links upstream: issue, PR, release note, commit, and downstream materializations in this repo). Git history is the edit log.

Do not open drive-by dependency hunts; record only issues encountered while doing the requested work and only when the defect is evident from behavior or published upstream facts, not speculation.

For proactive selection, alteration, and audit rules, use `dependency-policy` and the dependency-audit skill.
<!-- pray:edcc5f67 -->

<!-- pray:3ac5d6ce -->
## Dependency policy

Rules for adding, changing, or removing third-party packages. Apply across languages. Names vary by ecosystem; concepts do not.

Terminology:

- package manifest — declares intent (`gemspec`, `package.json`, `Cargo.toml`, `mix.exs`, etc.)
- lockfile — pins the resolved graph CI and developers install
- registry — published versions consumers resolve (`RubyGems`, `npm`, `crates.io`, `Hex`, etc.)
- hot path — code on the security, auth, crypto, IO, or request/response boundary users rely on

Stop until one of these applies before adding a dependency:

- stdlib or the framework for this tree already covers it;
- an installed transitive dependency already covers it without a second library for the same job;
- the feature needs a new package and tests will prove behavior.

Run the dependency-audit skill when adding, replacing, or removing a direct dependency; when asked for a dependency audit; before a release that changes hot-path packages; or after a published advisory names a package in the graph.

Related: `dependency-issues` records upstream defects found during real work; `minimal-implementation` covers YAGNI before adding deps; `engineering-audit` covers code and pipeline review.
<!-- pray:3ac5d6ce -->

<!-- pray:ad13bd27 -->
- test coverage must follow @spec/README.md guidelines;
- use ruby and Rails features according to the codebase versions;
- follow ruby and Rails coding conventions, principles, and best practices;
- never put data migrations in schema migrations, use the db/data_migrations pattern instead;
<!-- pray:ad13bd27 -->

<!-- pray:bf7304a6 -->
## Minimal implementation

Efficient means the smallest correct change.

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
- security and accessibility;
- calibration against real hardware and production drift when the platform ideal is not the spec;
- anything explicitly requested in the task or ticket;
- tests for non-trivial behavior per @spec/README.md and the testing bullets above; trivial one-liners need no new spec.

Related: `keep-the-work` covers staying on the failed place and keeping answers after a refusal.
<!-- pray:bf7304a6 -->

<!-- pray:120c3507 -->
## Finite state machines

- model lifecycles with explicit finite state machines when status, allowed transitions, and side effects matter; prefer named states and guarded transitions over scattered conditionals and implicit enums alone;
- finite state machines can compactly represent ordered sets or maps of strings supporting fast prefix, suffix, and fuzzy search; consider tries and automata when matching catalogs, codes, routes, or searchable vocabularies at scale;
- when digital reported state and physical process state can diverge, name both machines and the observation that couples them; occupancy listing is not the lock; a reported identity is not the person or sample at the station.

Related: `engineering-audit` boundary mode asks when those states disagree without an alarm; `io-simulation` injects the faults that cause the split.
<!-- pray:120c3507 -->

<!-- pray:26f3566a -->
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
<!-- pray:26f3566a -->

<!-- pray:f528eeca -->
## Preferred stack and tools

- native-first approach for all platforms and languages
- ruby for web application and API development, and for its rich ecosystem of libraries and frameworks
- elixir for concurrent and distributed systems, and for its actor model and fault tolerance
- rust for system programming and performance-critical code
- javascript, html, css for native browser experience
- humane and accessible design principles for UI/UX, and for clear communication of intent and feedback

Related: `keep-the-work` covers staying on the failed place and keeping answers after a refusal.
<!-- pray:f528eeca -->

<!-- pray:d3b0d939 -->
## IO simulation

- when a product depends on live IO from an external virtual or physical service, ship a simulation of that plant that speaks the same protocol the product already uses;
- give the simulation a control UI so a person can set the parameters that produce that IO while using the product: position, clock, amount, device state, and faults;
- injectable faults: unavailable, slow, valid but false, stale, protocol meaning change, partition, clock disagreement, reset, freeze, drift, duplicated command, command after timeout, reconnect replay, two authorities, obsolete operator display;
- keep the product on its production adapter; the simulation is a plant the adapter talks to;
- point the product at a vendor station when that station already covers those parameters (testmode dashboards, device emulator extended controls);
- a library that only answers request and response has no plant, so it does not need this workbench.

Related: `engineering-audit` enumerates those boundary conditions; `finite-state-machines` models the plant lifecycle; `preferred-stack` covers humane control UI; `minimal-implementation` still requires later calibration on real hardware.
<!-- pray:d3b0d939 -->

<!-- pray:ca94e22d -->
## Writing and changelog prose checks

Read once for marketing odor, once for negation-led sentences, once for stray em dashes, and once for paragraphs that break on clause instead of on scene; keep live notes and metadata honest and plain.
- repo trace under usr/docs: plain prose readable without a rendered preview. No markdown tables, bold, italic, or other styling. Prioritize factual accuracy over presentation.
- Ease, lexical diversity, coherence, mechanics, and claim integrity are separate constructs. Automated matches, readability grades, similarity, and model preference are review prompts; rewrite for meaning.
- Keep agency on the person who acts. Tools and process nouns do mechanical work.
- Technical names, APIs, CLI verbs, RFC titles, identifiers, and UI copy use instrument and protocol words: check-in, last-seen, probe, monitor, expected tick. Body and organism metaphors such as heartbeat, pulse, and organ stay out of contracts and code. HTTP `/health` remains the liveness probe until a later RFC.
- One sentence holds one beat. Consecutive short sentences that only restated the same beat are a punchline stack.
- For material external claims, quotations, dates, or research summaries, use the claims-audit skill.
<!-- pray:ca94e22d -->

<!-- pray:d893ab3d -->
## Claims and testimony

Treat checkable facts, quotations, dates, quantities, and causal statements as claims. Treat author memory and clearly framed interpretation as testimony.

- Inventing scenes, sources, numbers, or quotations is out of scope.
- A link or citation in the text is not verification. The cited passage must support the claim's scope, date, population, and causal strength.
- If a material external claim cannot be checked in this run, mark it unverifiable rather than rounding it to certainty.
- Run the claims-audit skill when asked to verify, fact-check, or research checkable claims, or when prose under edit states material external facts, quotations, dates, or research summaries.

Related: `writing-prose` covers voice and quality constructs; `engineering-audit` covers code and pipeline behavior.
<!-- pray:d893ab3d -->

<!-- pray:b1ea9b07 -->
## RFC process

Significant user-facing contract changes start as an RFC. Skip a bugfix, typo, or refactor that leaves those contracts in place.

Claim `rfcs/ids/NNNN` before writing `rfcs/NNNN-slug.md`. Copy `rfcs/0000-template.md`. Omit unused header fields and empty sections. Implementation PRs cite `RFC-NNNN`. Numbering bands, isolation, and extra product tests live in `rfcs/README.md`. Follow the rfc-process skill. Product RFCs specify a design. Version numbers belong in changelogs. Keep existing RFC numbers. RFC titles, registrar names, and identifiers use instrument and protocol words; body and organism metaphors stay out of contracts and code.
<!-- pray:b1ea9b07 -->

<!-- pray:08c294fb -->
## Likely rejected changes

- features whose complexity outweighs user value
- giant refactors
- non-trivial changes without tests
- style-only rewrites without behavior change
- AI-generated-looking code the author does not understand
<!-- pray:08c294fb -->

<!-- pray:2543c1cc -->
## Checks before publish (engineering)

- verify the change is wanted; discuss first for unconfirmed larger features
- describe what problem is solved and why it matters
- include tests
- add screenshots or screen recordings for UI changes
- keep one pull request to one concern
- understand any AI-assisted code you submit
<!-- pray:2543c1cc -->

<!-- pray:48e8a6b3 -->
## Collaboration workflow

- agent-assisted work with ongoing project value must leave a trace in the repo;
- store only specific, decision-bearing, high-signal material; do not commit generic notes, copied chat logs, or filler;
- use the lightest process that preserves traceability; design-only work does not need branch ceremony unless implementation work starts;
- follow docs-conventions for docs/ versus usr/docs/ layout.
<!-- pray:48e8a6b3 -->
