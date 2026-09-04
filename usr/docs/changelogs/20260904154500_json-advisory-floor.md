# json advisory floor

## Participants

Repository maintainer asked to clear bundle-audit flags on this branch.

## Decisions

Raise the gemspec runtime floor to json 2.21.2 or newer. Lock json 2.21.2 in Gemfile.lock and the four appraisal lockfiles. That version is the published patch for CVE-2026-71847 (GHSA-9hj4-r449-hfvc). The gem already requires json and calls JSON.parse and JSON.generate on the log line path. The advisory path is JSON::ResumableParser, which this gem does not call. The floor still belongs because the native json gem is loaded in-process and because consumers resolve from the gemspec, not this repo lockfile.

sqlite3 is not in this repository graph. Do not add it. The sqlite3 2.9.5 flag does not apply here.

## Effects

activesupport-json_logging declares json (>= 2.21.2). All five lockfiles pin json 2.21.2. sqlite3 remains absent.

## Next

Nested encoder hashes still omit the 50-key cap. JSON strings under the length cap still expand into root fields. EventSubscriber timestamp stays an integer.

## Source

https://github.com/ruby/json/security/advisories/GHSA-9hj4-r449-hfvc
https://github.com/ruby/json/blob/master/CHANGES.md
usr/docs/issues/20260904145000_engineering-audit.md
activesupport-json_logging.gemspec
Gemfile.lock
gemfiles/rails72.gemfile.lock
gemfiles/rails8ruby34.gemfile.lock
gemfiles/rails8ruby4.gemfile.lock
gemfiles/rails8truffleruby.gemfile.lock
