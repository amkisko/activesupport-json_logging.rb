# Release confirmation

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Cut patch 1.3.2 for the release operator workflow and the encoder/sanitizer fixes found in the later re-audit.
- Reject end of input at the confirmation prompt while accepting an entered empty line or yes.
- Require a matching `CHANGELOG.md` version heading before publish.
- Start quality, test, and coverage jobs for pull requests to `main`.

## Effects

- Confirmation and changelog-gate specs cover the release helper.
- Updated `CHANGELOG.md`, the version constant, and path-gem lockfile entries.

## Next

- Superseded by `docs/changelogs/20261107112300_release-1-3-2.md`: commit, then `make release`.

## Source

- usr/bin/release.rb
- usr/lib/release_version_check.rb
- spec/release_version_check_spec.rb
