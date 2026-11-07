# Engineering and prose audit before 1.3.2 publish

## Participants

Andrei Makarov (@amkisko)

## Decisions

Re-audit main for the unpublished 1.3.2 cut. Include empty large-hash encoder body after field overrides, home-prefix resolution without ActiveSupport `blank?`, release confirmation and changelog gates, pull_request CI, and ASCII docs punctuation. Leave tag and RubyGems publish to `make release` after commit.

## Effects

Pipeline: logger / Rails event -> Formatter / LineEncoder / PayloadBuilder / MessageParser -> Sanitizer / StructuredHash* -> JSON line -> IO. Boundary mode covered host log sinks. Resource and identification modes: no new person identifiers in gem logs. Queue, worker, learned-system, and physical plant modes skipped (absent).

Ranked fixes applied:

1. Emit a single `JSON.generate` of field overrides when the encoded body is empty after omit (high confidence, observed).
2. Replace `blank?` with nil/empty checks in `home_directory_prefix` (high confidence, observed).
3. Add `pull_request` to `.github/workflows/test.yml` (high confidence, observed; prior review overclaimed this).
4. Align `confirmation_accepted?` and changelog heading gates with sibling gems; expand specs.
5. CHANGELOG dated 2026-11-03; ASCII and marketing-tone pass on README, CHANGELOG, and gemspec.

Deferred (documented in the issue): ParameterFilter cache without sync, duplicated formatter fallback, explicit `require "set"`, shared release-helper gem.

Checks observed in this session:

- bundle exec rubocop on touched Ruby files: 8 files, no offenses.
- bundle exec rbs validate: ok.
- Focused rspec on sanitizer, optimizations, and release_version_check: 78 examples, 0 failures.
- bundle exec polyrun parallel-rspec --workers 5 --merge-failures: exit 0 (285 examples dry-run inventory); coverage/merged-summary.txt 94.49% lines (772 / 817) across 16 files.
- gem build activesupport-json_logging.gemspec and Gem::Package#verify for 1.3.2: ok (22 files, 26112 bytes).

## Next

Superseded by `docs/changelogs/20261107112300_release-1-3-2.md`: commit the expanded 1.3.2 cut, then `make release`.

## Source

- docs/issues/20261103153000_engineering-prose-release-audit.md
- docs/changelogs/20261107112300_release-1-3-2.md
- CHANGELOG.md section 1.3.2 (2026-11-07)
- Prior pass: docs/reviews/20261028094500_engineering-audit.md
