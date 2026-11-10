# json 3 removed JSON.fast_generate

## Dependency

json (>= 2.21.2) in activesupport-json_logging.gemspec. Consumers may resolve json 3.x. Root Gemfile.lock may still pin 2.21.2 while some appraisal lockfiles already resolve 3.1.0.

## Symptom

Loading or encoding with json 3 raises `NoMethodError: undefined method 'fast_generate' for module JSON`. Call sites were in `LineEncoder` and `StructuredHashJsonEncoder`.

## Evidence

json 3.0.0.rc1 release notes and CHANGES remove `JSON.fast_generate`. On json 2.x the method still exists (often as a deprecated alias of `JSON.generate`). activesupport-json_logging 1.3.2 called `JSON.fast_generate` on emit paths. A local regression that undefines `fast_generate` reproduces the failure before the fix.

## Suggested fix

Replace every emit-path `JSON.fast_generate` with `JSON.generate`. Keep the gemspec floor at json (>= 2.21.2). Ship 1.3.3. Consumer apps that pinned json to 2.x only for this gem can drop that pin after locking 1.3.3 or newer.

## Next

- Publish 1.3.3.
- Re-run encoder specs and an appraisal lock that resolves json 3.
- Drop consumer-side json 2.x pins once 1.3.3 is locked.

## Source

https://github.com/ruby/json/releases/tag/v3.0.0.rc1
https://github.com/ruby/json/blob/master/CHANGES.md
activesupport-json_logging.gemspec
lib/json_logging/line_encoder.rb
lib/json_logging/structured_hash_json_encoder.rb
