# Rails 8.1 EventReporter subscriber

## Participants

- amkisko

## Decisions

- Ship JsonLogging::EventSubscriber as the integration point for Rails.event.
- Keep subscription opt-in (manual Rails.event.subscribe or config.json_logging.subscribe_event_reporter).

## Effects

- Apps on Rails 8.1+ can emit structured Rails.event payloads as safe single-line JSON through this gem.
- Older Rails versions are unaffected; EventReporter specs skip when the constant is missing.
- Emit path tolerates string-keyed hashes, serializable tag objects, and destination write failures without raising.

## Next

- Link pull request after open.
- Include in next gem release notes under CHANGELOG.md version heading.

## Source

- https://github.com/amkisko/activesupport-json_logging.rb/issues/2
- Branch feature/rails-event-reporter-subscriber
