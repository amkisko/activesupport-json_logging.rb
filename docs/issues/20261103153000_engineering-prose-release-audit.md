# Engineering and prose audit before 1.3.2 publish

## Participants

Andrei Makarov (@amkisko)

## Decisions

Re-audit main for the unpublished 1.3.2 cut after the 2026-10-28 release-tooling pass. Include empty large-hash encoder body after field overrides, home-prefix resolution without ActiveSupport `blank?`, release confirmation and changelog gates, pull_request CI, and ASCII docs punctuation. Leave tag and RubyGems publish to `make release` after commit.

## Effects

Pipeline: logger / Rails event -> Formatter / LineEncoder / PayloadBuilder / MessageParser -> Sanitizer / StructuredHash* -> JSON line -> IO. Boundary mode covered host log sinks; the library path has no independent network client. Resource and identification modes: gem writes application-controlled log content; host sink retention stays outside scope. Queue, worker, learned-system, and physical plant modes skipped (absent).

Ranked fixes applied:

1. Emit a single `JSON.generate` of field overrides when the encoded body is empty after omit (high confidence, observed).
2. Replace `blank?` with nil/empty checks in `home_directory_prefix` (high confidence, observed).
3. Add `pull_request` to `.github/workflows/test.yml` (high confidence, observed; prior review overclaimed this).
4. Align `confirmation_accepted?` and changelog heading gates with sibling gems; expand specs.
5. ASCII and marketing-tone pass on README, CHANGELOG, gemspec, and related docs.

Deferred:

- Module-level ParameterFilter cache without synchronization under threads.
- Duplicated `build_fallback_output` in Formatter / FormatterWithTags.
- Explicit `require "set"` for StructuredHash / JsonLogging Set usage.
- Shared release-helper gem across house repositories.

## Next

Superseded by `docs/changelogs/20261107112300_release-1-3-2.md`: fold later hot-path work into the same unpublished 1.3.2 cut, commit, then `make release`.

## Source

- docs/reviews/20261103153000_engineering-prose-release-audit.md
- docs/changelogs/20261107112300_release-1-3-2.md
- CHANGELOG.md section 1.3.2 (2026-11-07)
- Prior pass: docs/reviews/20261028094500_engineering-audit.md
