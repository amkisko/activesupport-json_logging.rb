# Engineering audit and release check

## Decisions

- Review log formatting, sanitization, Rails integration, release flow, tests, CI, package contents, resource use, and identifying traces.
- Use the local Ruby 4.0.2 bundle and existing benchmark fixture. Do not infer deployed log retention from library code.

## Effects

- Release confirmation: medium severity, high confidence, observed at usr/bin/release.rb. End of input previously passed the publish prompt. The focused spec failed before the fix and passed afterward.
- CI trigger: medium severity, high confidence, observed at .github/workflows/test.yml. Pull requests did not start the test workflow. The workflow now includes pull_request; YAML parsing confirms the key.
- make test, bundle check, git diff --check, gem build, and Gem::Package#verify passed. The built 1.3.2 gem has 22 files and is 26112 bytes.
- Cold require of activesupport/json_logging used 0.218 user CPU seconds, 0.134 system CPU seconds, and 27836416 bytes peak RSS on this machine. Package build used 0.094 user CPU seconds, 0.045 system CPU seconds, and 30687232 bytes peak RSS. The benchmark suite measured 12109 KB allocated and 0 KB retained over 10000 log writes in its local fixture. No production ceiling was stated.
- The gem writes application-controlled log content and has no independent network client. Host log sinks, retention, and identifying fields were not captured; a deployed sink fixture would establish those values. Browser presentation and service observability are owned by the host.
- The second source and test pass found no further confirmed, fixable findings in this scope.

## Next

- Run the full CI matrix and inspect a host log sink before publishing.

## Source

- lib/json_logging/sanitizer.rb
- lib/json_logging/formatter.rb
- usr/bin/release.rb
- .github/workflows/test.yml
- spec/json_logging_sanitizer_spec.rb
- spec/release_confirmation_spec.rb
- spec/performance/benchmark_spec.rb
