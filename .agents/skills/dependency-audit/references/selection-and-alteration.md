# Selection and alteration

Use with the dependency-audit skill when adding, changing, or removing packages. The AGENTS fragment holds terminology and the stop-before-add gate.

## Prefer packages that

- share a trusted maintainer cluster and spec family with dependencies already on the hot path (same author group, same protocol stack, same RFC family);
- align with the domain protocol being implemented (do not bolt on a parallel HTTP client, JWT stack, or crypto helper when the main stack already carries one);
- show real adoption on the registry and recent maintenance (commits and published versions; registry publish date matters when upstream release tags lag);
- keep bus factor visible: a coherent maintainer cluster is good for integration; a lone micro-package on a hot path is a supply-chain risk unless adoption and release cadence are strong.

## Reject or defer when

- the capability duplicates an existing node in the graph;
- issues-per-star and open pull request backlog suggest maintainer strain on a small package;
- a major version adds native extensions or platform matrices the CI matrix does not exercise;
- license or export-control terms conflict with product use.

## When altering dependencies

- run advisory scans on every lockfile or variant graph CI installs (root lockfile alone is not enough when matrix gemfiles, workspaces, or target-specific locks exist);
- keep hot-path and direct runtime packages at the latest safe registry version unless a documented exception explains the pin;
- tighten package manifest floors when security fixes require a minimum version; lockfiles protect this repo, manifests protect downstream consumers;
- on major upgrades, grep for adapters (HTTP mocks, test doubles, middleware, FFI shims) and run the full CI matrix;
- delete redundant packages when a transitive or cluster dependency subsumes them; wrap remaining vendor exceptions at trust boundaries with project error types, not raw vendor exceptions in user-facing paths;
- list exact commands and observed results in validation output; never claim a clean audit without running it.

## Automation

- gate CI on advisory checks for the ecosystems that exist in the repository; drop automated update config for ecosystems with no manifest;
- use grouped automated update pull requests for lockfiles; human review still applies selection rules above.

Full dependency audits rely on deep recon and OSINT, not only lockfile scanners. Automated advisory and outdated checks are necessary baseline; they are not sufficient for hot-path packages or for add/replace decisions.
