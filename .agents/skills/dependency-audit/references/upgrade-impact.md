# Upgrade impact

Use with the dependency-audit skill when adding, changing, replacing, or
removing a package, or when reviewing an automated or human upgrade pull
request. This procedure answers what changed upstream and whether this tree
uses those surfaces. Resource deltas stay in `upgrade-resource-compare.md`.
Freshness lag stays in `libyears.md`. Advisories stay in
`vulnerability-assessment.md`.

## When required

- hot-path direct package bump (any patch, minor, or major);
- major version bump of a hot-path transitive package (or of its parent);
- any upgrade that changes public API, config keys, runtime peers, or native
  extensions the tree exercises;
- replace or remove decisions that follow a fitness failure.

Tier scaling:

- hot path direct - every release note or changelog entry from locked base
  through target; map each breaking, behavior, security, deprecation, config,
  and runtime or peer change to usage in this tree;
- hot path transitive - parent bump notes plus only the surfaces this tree
  reaches;
- dev or test only - security entries and changes that break CI or local
  tooling; skip feature adoption;
- grouped automated update pull requests - one impact summary for the group;
  expand per package only when a member is hot path or the summary is unclear.

Skip when the resolved graph and shipped bytes are unchanged, or when the edit
is a documentation-only dependency note. State the skip and the evidence.

## Procedure

1. Record locked base and target versions from the lockfile (and manifest when
   floors move). For transitive packages, name the direct parent that pulls
   them in.
2. Fetch changelog or release notes for every published version in the open
   interval (base, target]. Prefer the upstream project's notes; fall back to
   registry release text, then to the git log between tags when notes are
   missing. Say which source was used and which versions lacked notes.
3. List every entry marked breaking, deprecated, behavior-changed, security,
   config, or runtime or peer requirement. Ignore pure internal refactors that
   do not name a public surface.
4. For each listed change, search this tree for usage (call sites, config keys,
   adapters, FFI, middleware, test doubles). Record path and symbol when found.
   No hit means the change is observed upstream and not applicable here until
   proven otherwise.
5. Check peer and engine requirements of the target against what this tree
   runs. Block when a companion or runtime upgrade is a prerequisite.
6. Classify the upgrade:
   - `patch-safe` - no breaking or behavior change on used surfaces;
   - `adapt-needed` - used surfaces require known adaptations;
   - `blocked` - missing prerequisite, or no clear adaptation for a used break.
7. Split follow-up work:
   - must-adapt - required for a correct bump;
   - may-adopt - new upstream capability that could replace a local shim or
     reduce first-party code; still pass `minimal-implementation` YAGNI before
     adopting;
   - do-not-adopt - unused new surface; do not expand scope for novelty.
8. Stop and present the assessment before merge when classification is
   `adapt-needed` or `blocked`, or when must-adapt work is incomplete.

## Report contract

Return for each assessed package or group:

- base and target versions, tier, and parent when transitive;
- source of notes (URL or path) and gaps;
- breaking, behavior, security, deprecation, config, and runtime or peer items
  with usage hits or `not_used`;
- classification (`patch-safe`, `adapt-needed`, `blocked`);
- must-adapt, may-adopt, and do-not-adopt lists;
- next human step when blocked or incomplete.

Do not claim the bump is safe from version numbers alone. Missing notes raise
uncertainty; default to caution on hot path (`adapt-needed` or incomplete), not
to `patch-safe`.

## Fitness reassessment

Use when pressure benchmarking, engineering-audit resource and budget mode, or
a named production requirement shows the dependency no longer meets the job it
was selected for (latency, memory, correctness under load, license, platform
matrix, or maintainer viability).

Record in the live-work note:

- the named requirement and the measured or evidenced gap;
- whether tuning, configuration, or a different registry package closes the gap;
- then choose the smallest credible path: keep with documented exception,
  replace package, remove and use stdlib or an installed transitive, vendor or
  fork a thin wrap, or narrow first-party code.

Custom first-party code is last among those options. It still passes the
stop-before-add gates in the compose fragment and `minimal-implementation`:
scope stays narrow, tests prove behavior, and crypto or auth stay out unless
the tree already owns that expertise. OpenSSF guidance treats reinvention as
its own defect surface; do not prefer custom for control alone.

Pressure-benchmarking owns detection under load (primary series stuck inside
the dependency after cooker rules). This procedure owns the replace, remove,
or custom disposition after that signal. One-change upgrade resource deltas
stay in `upgrade-resource-compare.md`; do not fold a pressure cooker into an
ordinary bump review.

## Related

- `selection-and-alteration.md` - run this impact pass with alteration checks;
- `upgrade-resource-compare.md` - base/head resource samples after impact;
- `dependency-audit.md` - Pass 0 lists changelog as a recon source; this file
  makes the usage map mandatory on upgrade;
- `minimal-implementation` - YAGNI for may-adopt and for custom replacement;
- `pressure-benchmarking` - escalate fitness failure here after measured stall.
