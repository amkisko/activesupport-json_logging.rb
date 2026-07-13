# Testing

## Commands

Full suite (matches CI: parallel shards via Polyrun):

```bash
make test
```

Lint (RuboCop and RBS):

```bash
make lint
```

Focused runs:

```bash
bundle exec rspec spec/activesupport/json_logging_spec.rb
```

See `polyrun.yml`. `make test` runs `hooks.before_suite` before specs.

## Layout

- `spec/` — formatter, subscriber, and allocation-related specs

## Guidelines

- Test log shape and filtering behavior, not formatter implementation details.
- Mock only I/O and time boundaries where needed.
- Add or update specs before bugfixes; run `make lint && make test` before a PR.
- Coverage threshold: `config/polyrun_coverage.yml` when `POLYRUN_COVERAGE=1`.
