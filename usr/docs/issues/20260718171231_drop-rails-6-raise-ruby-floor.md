# Drop Rails 6 and raise Ruby floor for Struct keyword init

## Participants

- amkisko

## Decisions

- Fix the keyword_init flip-flop by raising the language floor instead of positional Struct args or a permanent RuboCop disable.
- Ruby 3.2+ is the floor because keyword Struct members without keyword_init require it.
- Rails 6 leaves the matrix with that floor; Rails 7.2 remains the lowest CI appraisal.

## Effects

- Documented and implemented on branch patch/drop-rails-6-raise-ruby-floor.

## Next

- Merge after green CI on remaining matrix (rails72, rails8*, truffleruby).

## Source

- OpenSSF / CI discussion on Style/RedundantStructKeywordInit vs Ruby 3.1 CI floor.
