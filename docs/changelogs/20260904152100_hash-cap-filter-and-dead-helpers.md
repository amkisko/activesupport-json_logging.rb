# Hash cap filter and dead helpers

## Participants

Repository maintainer asked to continue the engineering audit with findings 8 and 9.

## Decisions

Keep the 50-key DoS cap. After the first 50 keys, scan remaining keys only. If a key matches SENSITIVE_KEY_PATTERNS or a configured filter_parameters token (string, symbol, or regexp; skip Proc and dotted tokens), include it as [FILTERED] without copying the value. Cap extra filtered keys at 50 so a large token_* hash cannot explode the line. Do not ParameterFilter-walk dropped values.

The large-hash encoder still applies limited_hash_for_sanitization at the top level only. Nested hashes on that path keep walking every key. Nested overflow secrets that match patterns are still renamed or filtered; they are not dropped by first(50).

Remove LineEncoder.build_sanitized_hash_payload, StructuredHashJsonEncoder.eligible?, and large_structured_hash?. Specs assert try_encode_line returns a line or nil. Drop the unused webmock development dependency and spec/support/webmock.rb. Add spec/activesupport/json_logging_spec.rb as a public-entry smoke spec.

## Effects

A password or custom filter_parameters key past the 50-key cap appears as [FILTERED] and the secret is absent from the JSON line. The source hash is unchanged. Later plain keys stay omitted. Encoder eligibility is covered by try_encode_line. The gem entry require writes one JSON line. webmock is no longer in the gemspec or lockfiles.

## Next

Nested encoder hashes still omit the 50-key cap. JSON strings under the length cap still expand into root fields. EventSubscriber timestamp stays an integer.

## Source

usr/docs/issues/20260904145000_engineering-audit.md
lib/json_logging/sanitizer.rb
lib/json_logging/sanitizer_hash_limit.rb
lib/json_logging/structured_hash_json_encoder.rb
lib/json_logging/line_encoder.rb
activesupport-json_logging.gemspec
spec/json_logging_sanitizer_spec.rb
spec/json_logging_optimizations_spec.rb
spec/activesupport/json_logging_spec.rb
