# Rails 8.1 EventReporter subscriber

## Participants

- amkisko

## Decisions

- Resolve GitHub issue 2 with an opt-in JsonLogging::EventSubscriber for ActiveSupport::EventReporter (Rails 8.1+), not a logger rewrite.
- Preserve the Rails event hash shape as a single JSON line (name, payload, tags, context, timestamp, source_location).
- Write through Logger#<< or a raw IO so the JSON logger formatter does not wrap events again.
- Railtie flag config.json_logging.subscribe_event_reporter defaults to false.
- Do not bridge JsonLogging.with_context and Rails.event.set_context.
- Gate specs with defined?(ActiveSupport::EventReporter) so older matrix cells skip cleanly.
- Accept only one of logger: or io:; callable logger: resolves on each emit (Railtie uses -> { Rails.logger }).
- Read event fields with symbol or string keys; serialize tag object values like payloads.
- Never raise from #emit on encode or write failure; report write errors through ActiveSupport.error_reporter when present.

## Effects

- Added lib/json_logging/event_subscriber.rb and require from lib/json_logging.rb.
- Extended Railtie with OrderedOptions and optional subscribe initializer.
- Added spec/json_logging_event_subscriber_spec.rb covering string keys, tag objects, write failure, callable logger, and BroadcastLogger fan-out.
- Documented setup in README and CHANGELOG Unreleased.
- Applied engineering-audit follow-ups for write rescue, tag serialize, string keys, lazy logger, and logger/io exclusivity.

## Next

- Open pull request for issue 2.
- After merge, cut a release that moves the Unreleased changelog bullet under a version heading.

## Source

- https://github.com/amkisko/activesupport-json_logging.rb/issues/2
- https://github.com/rails/rails/pull/55334
- https://guides.rubyonrails.org/v8.1/8_1_release_notes.html
