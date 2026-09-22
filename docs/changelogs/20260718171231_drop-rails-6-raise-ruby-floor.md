# Drop Rails 6 and raise Ruby floor to 3.2

## Participants

- amkisko

## Decisions

- Raise required Ruby to 3.2+ so Struct keyword construction works without keyword_init: true.
- Raise runtime activesupport/railties floors to 7.0+ and remove Rails 6 from Appraisal and CI.
- Keep keyword JsonableResult.new(...) call sites; drop only the keyword_init flag (RuboCop Style/RedundantStructKeywordInit).
- Align RuboCop TargetRubyVersion with the new support floor (3.2).

## Effects

- gemspec, Appraisals, test matrix, README, and CHANGELOG updated for Ruby 3.2+ / Rails 7–8.
- Removed gemfiles/rails6.* and gemfiles/rails_6.1.gemfile.
- structured_hash_sanitizer no longer uses keyword_init: true.

## Next

- Run rubocop and rspec on the branch before merge.
- Cut a minor or major release when publishing the support drop.

## Source

- CI rubocop failure on Style/RedundantStructKeywordInit under matrix RuboCop 1.87.
- Prior flip-flop commits around keyword_init and Ruby 3.1 CI.
