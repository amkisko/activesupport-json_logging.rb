# Dependency audit: upgrade, drop, absorb

## Decisions

Depth: full. Commands and sources: `bundle outdated --only-explicit`, `bundle-audit update` then `bundle-audit check --no-update` on Gemfile.lock and every gemfiles/*.gemfile.lock (ruby-advisory-db commit bc80fbb, 1353 advisories, last updated 2026-11-09), Rubygems API for json / activesupport / railties latest, GHSA-8474-xrp6-wh69 advisory text, gemspec and lib usage grep, standard-* runtime dependency inspection, Appraisals vs gemfiles listing, dependabot.yml vs present manifests.

Runtime hot path stays three declared peers: activesupport, railties, json. Do not invent a first-party JSON encoder or ParameterFilter. Keep the json floor at >= 2.21.2. Prefer lock bumps and gemspec slim-downs over new packages.

Upgrade first:

1. Bump appraisal and root locks so activesupport and railties resolve to 8.1.4.1 on the 8.1 line and 7.2.4 on the 7.2 line (Appraisals floors today are >= 8.1.3.1 / >= 7.2.3.2). Root and active CI locks are still on 8.1.3.1 / 7.2.3.2; orphan rails_8.1 / rails_7.2 locks already sit on 8.1.4.1 / 7.2.4.
2. After 1.3.3 encode fix is the tree under test, bump json from 2.21.2 to 3.1.0 on Gemfile.lock and the four CI appraisal locks. Keep gemspec >= 2.21.2.

Drop or stop declaring:

1. Delete orphan gemfiles/rails_7.2.gemfile(+lock) and gemfiles/rails_8.1.gemfile(+lock). They are not in Appraisals and not in test.yml matrix.
2. Remove direct gemspec development entries for rubocop-rails and rubocop-rspec. standard-rails already requires rubocop-rails; standard-rspec already requires rubocop-rspec. Keep them on the RuboCop plugins list via the transitive gems. Keep rubocop-thread_safety as a direct dep (nothing in the standard cluster pulls it).
3. Remove dependabot npm and docker update blocks. This repo has no package.json and no Dockerfile.
4. Optional maintainer slim: move stackprof and benchmark-ips out of the gemspec into an optional local group or document `gem install` for STACKPROF=1 profiling. They are not on make test. Keep memory_profiler while benchmark_spec requires it unconditionally.

Absorb / soften (no new package):

1. Soften railties: stop declaring railties as a gemspec runtime dependency. Railtie already loads only when Rails is defined. Appraisals keep railties for matrix coverage. That removes actionpack, actionview, rack, nokogiri, loofah, and rails-html-sanitizer from the root lock once railties is gone from the path gem, cutting most advisory noise that is not on the encode hot path.
2. Do not absorb activesupport Logger, ParameterFilter, OrderedOptions, or deep_stringify_keys into first-party copies. Those APIs are the product peer surface.
3. Do not drop the json gem declaration in favor of "stdlib only". The floor exists for advisory and consumer resolve control.

Security dispositions for flagged packages (assessment target: this library encode/boot path vs CI lock graph):

- activesupport 8.1.3.1 GHSA-8474-xrp6-wh69 (safe_constantize / Action Cable): not_affected for this gem's call sites (no safe_constantize usage). Lock still needs 8.1.4.1 for a clean audit graph and for consumers who copy appraisal pins.
- activesupport 8.1.3.1 GHSA-2w9f-fxwj-w2qf (MessagePack): not_affected (no MessagePack usage).
- actionpack, actionview, rack, loofah, nokogiri, crass, rails-html-sanitizer advisories: not_affected for encode paths; they enter only through railties. Disposition for CI graph: upgrade or drop railties from root as above.
- json: no open advisory at 2.21.2 or 3.1.0 in this scan. Freshness gap only on locks still at 2.21.2.

Freshness (direct explicit from bundle outdated): rbs 3.10.4 vs 4.2.0 (major, low priority), rubocop-rails 2.34.3 vs 2.38.0 (may follow standard-rails pin ~> 2.34), rubocop-thread_safety 0.7.3 vs 0.8.0, standard 1.56.0 vs 1.57.0, standard-rspec 0.5.0 vs 0.5.1. Hot-path lag that matters: json major (2 -> 3), Rails patch (8.1.3.1 -> 8.1.4.1). Band: compact gem graph; treat Rails patch and json major as the only high-value freshness work.

Automation: dependency-audit.yml remains workflow_dispatch only by prior decision. Scorecard and Dependabot bundler + github-actions stay. Dead npm/docker Dependabot targets should go.

## Effects

Audit completed; no lock or gemspec edits in this pass. Findings above are recommendations.

## Next

1. Upgrade CI and root Rails locks to 8.1.4.1 / 7.2.4 and raise Appraisals floors to match.
2. Upgrade json locks to 3.1.0; run polyrun and lint.
3. Delete orphan rails_7.2 / rails_8.1 gemfiles; trim Dependabot npm/docker; drop duplicate rubocop-rails / rubocop-rspec gemspec lines.
4. Spike soft railties: remove from gemspec, keep appraisal pins, confirm Railtie specs and a Rails boot path.
5. Decide whether stackprof / benchmark-ips leave the gemspec.

## Source

https://rubygems.org/gems/json
https://rubygems.org/gems/activesupport
https://rubygems.org/gems/railties
https://github.com/rails/rails/security/advisories/GHSA-8474-xrp6-wh69
https://github.com/rubysec/ruby-advisory-db
activesupport-json_logging.gemspec
Appraisals
.github/dependabot.yml
.github/workflows/dependency-audit.yml
docs/issues/20260917123253_ci-drop-automatic-dependency-audit.md
docs/dependencies/20261110172512_json-3-removed-fast-generate.md
