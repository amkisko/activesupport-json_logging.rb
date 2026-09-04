# Sanitizer copy, fallback filters, and EventSubscriber level

## Participants

Repository maintainer asked for root-cause sanitizer, encoder, context, filter, parser, and event fixes after the engineering audit.

## Decisions

Copy the jsonable tree with StructuredHash.stringify before ActiveSupport::ParameterFilter.filter on the large-hash encoder path. stringify_keys_copy is removed. jsonable_tree skips the fallback _filtered rename when a Rails ParameterFilter is present so encoder output keeps the same key names as sanitize_hash. Nested hashes in a with_context payload are copied the same way in sanitize_without_filter so the sanitized cache does not share objects with the caller. A nested password added after the first log in that scope is omitted on later lines because the cache is stale by design.

Fallback SENSITIVE_KEY_PATTERNS now uses the Rails default substring set: passw, pwd, email, secret, token, _key, crypt, salt, certificate, otp, ssn, cvv, cvc, credential. authorization is not added. When a Rails ParameterFilter is present, key names stay as Rails left them. The fallback path still renames keys with the _filtered suffix.

rails_parameter_filter stores a frozen dup of filter_parameters and compares that snapshot to the live array so an in-place append rebuilds the compiled filter.

MessageParser skips JSON.parse when a brace or bracket string is longer than Sanitizer::MAX_STRING_LENGTH. Shorter JSON strings still expand into root fields.

sanitize_string replaces a home-directory prefix from ENV HOME or Dir.home with a tilde at a path boundary. EventSubscriber still writes through Logger#<< after skipping when logger.info? is false. IO destinations always write. timestamp stays the Rails event integer.

Findings 8 and 9 from the audit were closed in a later pass. See usr/docs/changelogs/20260904152100_hash-cap-filter-and-dead-helpers.md.

## Effects

Logging a large string-key hash with filter_parameters including email no longer overwrites the caller email field. Nested context hashes are independent of the caller after the first log. Fallback filtering covers email, otp, ssn, credentials, and refresh_token. In-place filter_parameters appends take effect. Oversized JSON strings stay truncated text. Home paths in strings and backtraces become tilde paths. EventSubscriber honors logger.level for INFO.

## Next

Closed by usr/docs/changelogs/20260904152100_hash-cap-filter-and-dead-helpers.md.

## Source

usr/docs/issues/20260904145000_engineering-audit.md
lib/json_logging/sanitizer.rb
lib/json_logging/structured_hash_sanitizer.rb
lib/json_logging/structured_hash_json_encoder.rb
lib/json_logging/message_parser.rb
lib/json_logging/event_subscriber.rb
spec/json_logging_optimizations_spec.rb
spec/json_logging_sanitizer_spec.rb
spec/json_logging_message_parser_spec.rb
spec/json_logging_event_subscriber_spec.rb
