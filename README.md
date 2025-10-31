# activesupport-json_logging

[![Gem Version](https://badge.fury.io/rb/activesupport-json_logging.svg)](https://badge.fury.io/rb/activesupport-json_logging) [![Test Status](https://github.com/amkisko/activesupport-json_logging.rb/actions/workflows/ci.yml/badge.svg)](https://github.com/amkisko/activesupport-json_logging.rb/actions/workflows/ci.yml) [![codecov](https://codecov.io/gh/amkisko/activesupport-json_logging.rb/graph/badge.svg?token=UX80FTO0Y0)](https://codecov.io/gh/amkisko/activesupport-json_logging.rb)

Structured JSON logging for Rails and ActiveSupport with a safe, single-line formatter.
No dependencies beyond Rails and Activesupport.
Supports Rails versions from 6 to 8.

Sponsored by [Kisko Labs](https://www.kiskolabs.com).

## Installation

Add to your Gemfile:

```ruby
gem "activesupport-json_logging"
```

Run bundler:

```bash
bundle install
```

Update configuration:

```ruby
Rails.application.configure do
  config.logger = JsonLogging.new(Logger.new(STDOUT))
end
```

### Development: Using from Local Repository

When developing the gem or testing changes in your application, you can point your Gemfile to a local path:

```ruby
# In your application's Gemfile
gem "activesupport-json_logging", path: "../activesupport-json_logging.rb"
```

Then run:

```bash
bundle install
```

**Note:** When using `path:` in your Gemfile, Bundler will use the local gem directly. Changes you make to the gem code will be immediately available in your application without needing to rebuild or reinstall the gem. This is ideal for development and testing.

## What you get

- `JsonLogging.new(logger)` - Wraps any standard Logger object to provide JSON formatting (similar to `ActiveSupport::TaggedLogging.new`)
- `JsonLogging.logger(*args)` - Convenience method that creates an `ActiveSupport::Logger` and wraps it
- Safe JSON serialization that never raises from the formatter
- `JsonLogging.with_context` to attach contextual fields per-thread
- Smart message parsing (handles hashes, JSON strings, plain strings, and Exception objects)
- Native `tagged` method support - use it just like Rails' tagged logger
- Automatic Rails integration via Railtie (auto-requires the gem in Rails apps)

## Basic usage

```ruby
# Wrap any standard logger
logger = JsonLogging.new(Logger.new(STDOUT))
logger.info("Booted")

# Or use the convenience method
logger = JsonLogging.logger($stdout)
logger.info("Booted")

# Tagged logging - works just like Rails.logger.tagged
logger.tagged("REQUEST", request_id) do
  logger.info("Processing request")
end

# Tagged logging without block (returns new logger with tags)
logger.tagged("BCX").info("Stuff")
logger.tagged("BCX", "Jason").info("Stuff")
logger.tagged("BCX").tagged("Jason").info("Stuff")

# Add context
JsonLogging.with_context(user_id: 123) do
  logger.warn({event: "slow_query", duration_ms: 250})
end

# Log exceptions (automatically formatted with class, message, and backtrace)
begin
  raise StandardError.new("Something went wrong")
rescue => e
  logger.error(e)  # Exception is automatically parsed and formatted
end
```

## Rails configuration

This gem does **not** automatically configure your Rails app. You set it up manually in initializers or environment configs.

**Note:** 
- In Rails apps, the gem is automatically required via Railtie, so you typically don't need to manually `require "json_logging"` in initializers (though it's harmless if you do).
- In Rails 7.1+, Rails automatically wraps your logger in `ActiveSupport::BroadcastLogger` to enable writing to multiple destinations (e.g., STDOUT and file simultaneously). This works seamlessly with our logger - your JSON logger will be wrapped and all method calls will delegate correctly. No special handling needed.
- In Rails 7.1+, tag storage uses `ActiveSupport::IsolatedExecutionState` for improved thread/Fiber safety.

### Basic setup

Create `config/initializers/json_logging.rb`:

```ruby
# Note: In Rails apps, the gem is automatically required via Railtie,
# so the require below is optional but harmless
# require "json_logging"

Rails.application.configure do
  # Build JSON logger
  base_logger = ActiveSupport::Logger.new($stdout)
  json_logger = JsonLogging.new(base_logger)

  # Set as Rails logger
  config.logger = json_logger
  
  # Optional: set log tags for request_id, etc.
  config.log_tags = [:request_id, :remote_ip]

  # Set component loggers
  config.active_record.logger = json_logger
  config.action_view.logger = json_logger
  config.action_mailer.logger = json_logger
  config.active_job.logger = json_logger
end
```

### Environment-specific examples

#### Development (`config/environments/development.rb`)

```ruby
Rails.application.configure do
  config.log_level = ENV["DEBUG"].present? ? :debug : :info

  # Set up JSON logging
  base_logger = ActiveSupport::Logger.new($stdout)
  base_logger.level = config.log_level
  json_logger = JsonLogging.new(base_logger)
  config.logger = json_logger
  config.log_tags = [:request_id]

  # Set component loggers
  config.active_record.logger = json_logger
  config.action_view.logger = json_logger
  config.action_mailer.logger = json_logger
  config.active_job.logger = json_logger

  # Disable verbose enqueue logs to reduce noise
  config.active_job.verbose_enqueue_logs = false

  # ... rest of your development config
end
```

#### Production (`config/environments/production.rb`)

```ruby
Rails.application.configure do
  config.log_level = :info
  config.log_tags = [:request_id]

  # Set up JSON logging
  logdev = Rails.root.join("log", "production.log")
  base_logger = ActiveSupport::Logger.new(logdev)
  base_logger.level = config.log_level
  json_logger = JsonLogging.new(base_logger)
  config.logger = json_logger

  # Set component loggers
  config.active_record.logger = json_logger
  config.action_view.logger = json_logger
  config.action_mailer.logger = json_logger
  config.active_job.logger = json_logger

  # ... rest of your production config
end
```

#### Test (`config/environments/test.rb`)

```ruby
Rails.application.configure do
  # Set log level to fatal to reduce noise during tests
  config.log_level = ENV["DEBUG"].present? ? :debug : :fatal

  # Optionally use JSON logger in tests too
  if ENV["JSON_LOGS"] == "true"
    base_logger = ActiveSupport::Logger.new($stdout)
    base_logger.level = config.log_level
    json_logger = JsonLogging.new(base_logger)
    config.logger = json_logger
  end

  # ... rest of your test config
end
```

### Lograge integration

If you use Lograge, configure it to feed raw hashes and let this gem handle JSON formatting. This example shows a complete setup including all Rails component loggers and common third-party libraries:

```ruby
# config/initializers/lograge.rb
# Note: require is optional in Rails apps (auto-loaded via Railtie)
# require "json_logging"

Rails.application.configure do
  # Configure Lograge
  config.lograge.enabled = true
  # Use Raw formatter so we pass a Hash to our JSON logger and avoid double serialization
  config.lograge.formatter = Lograge::Formatters::Raw.new
  config.lograge.keep_original_rails_log = ENV["DEBUG"] ? true : false

  # Merge additional context into Lograge output
  config.lograge.custom_options = ->(_event) { JsonLogging.additional_context }

  # Build unified JSON logger
  logdev = Rails.env.production? ? Rails.root.join("log", "#{Rails.env}.log") : $stdout
  base_logger = ActiveSupport::Logger.new(logdev)
  base_logger.level = config.log_level
  json_logger = JsonLogging.new(base_logger)

  # Set the main Rails logger
  config.logger = json_logger
  config.log_tags = [:request_id, :remote_ip]

  # Override Rails.logger to ensure it uses our formatter
  Rails.logger = json_logger

  # Set all Rails component loggers to use the same tagged logger
  config.active_record.logger = json_logger
  config.action_view.logger = json_logger
  config.action_mailer.logger = json_logger
  config.active_job.logger = json_logger

  # Configure third-party library loggers (if gems are present)
  OmniAuth.config.logger = json_logger if defined?(OmniAuth)
  Sidekiq.logger = json_logger if defined?(Sidekiq)
  Shrine.logger = json_logger if defined?(Shrine)
  Sentry.configuration.sdk_logger = json_logger if defined?(Sentry)
  Dotenv::Rails.logger = json_logger if defined?(Dotenv::Rails)
  Webpacker.logger = json_logger if defined?(Webpacker)

  # Disable verbose enqueue logs to reduce noise
  config.active_job.verbose_enqueue_logs = false

  # Optional: Customize log tags based on request
  # config.log_tags = [
  #   :request_id,
  #   ->(request) { request.remote_ip },
  #   ->(request) { request.subdomain }
  # ]
end
```

### Puma integration

To make Puma output JSON lines, configure it in `config/puma.rb`:

```ruby
# config/puma.rb
# Note: require is optional in Rails apps (auto-loaded via Railtie)
# require "json_logging"

# ... puma config ...

log_formatter do |message|
  formatter = JsonLogging::Formatter.new(tags: ["Puma"])
  formatter.call(nil, Time.current, nil, message).strip
end

# Optional: handle low-level errors
lowlevel_error_handler do |e|
  # Your error reporting logic here
  [
    500,
    {"Content-Type" => "application/json"},
    [{error: "Critical error has occurred"}.to_json]
  ]
end
```

## API

### JsonLogging.logger(*args, **kwargs)

Returns an `ActiveSupport::Logger` that has already been wrapped with JSON logging concern. Convenience method for creating a logger and wrapping it in one call.

```ruby
logger = JsonLogging.logger($stdout)
logger.info("message")
```

### JsonLogging.new(logger)

Wraps any standard Logger object to provide JSON formatting capabilities. Similar to `ActiveSupport::TaggedLogging.new`.

```ruby
# Wrap any standard logger
logger = JsonLogging.new(Logger.new(STDOUT))
logger.info("message")
logger.info({event: "test", value: 123})  # Hashes are merged into payload

# Log exceptions (automatically formatted with class, message, and backtrace)
begin
  raise StandardError.new("Error message")
rescue => e
  logger.error(e)  # Exception parsed and formatted automatically
end

# Tagged logging with block
logger.tagged("REQUEST", request_id) do
  logger.info("tagged message")
end

# Tagged logging without block (returns new logger with tags)
logger.tagged("BCX").info("Stuff")
logger.tagged("BCX", "Jason").info("Stuff")
logger.tagged("BCX").tagged("Jason").info("Stuff")
```

**Wrapping Compatibility:** You can wrap loggers that have already been wrapped with `ActiveSupport::TaggedLogging`:

```ruby
# Wrap a TaggedLogging logger - works perfectly
tagged_logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
json_logger = JsonLogging.new(tagged_logger)
json_logger.tagged("TEST") { json_logger.info("message") }  # Tags appear in JSON context
```

**Note:** If you wrap a `JsonLogging` logger with `ActiveSupport::TaggedLogging`, the TaggedLogging's text-based tags will appear as part of the message string in the JSON output, not as structured tags in the context. For best results, wrap loggers with `JsonLogging` last.

### JsonLogging::JsonLogger

`JsonLogging::JsonLogger` is a class that extends `ActiveSupport::Logger` directly. While still fully functional, the recommended approach is to use `JsonLogging.new` to wrap any logger, as it provides more flexibility and works with any Logger implementation (including loggers already wrapped with `ActiveSupport::TaggedLogging`).

```ruby
# Direct usage (still supported)
logger = JsonLogging::JsonLogger.new($stdout)
logger.info("message")

# Recommended: wrap any logger
logger = JsonLogging.new(ActiveSupport::Logger.new($stdout))
logger.info("message")
```

### JsonLogging::Formatter

A standalone formatter that can be used independently (e.g., in Puma's `log_formatter`). Supports adding tags via the constructor.

```ruby
# Basic usage without tags
formatter = JsonLogging::Formatter.new
formatter.call("INFO", Time.now, nil, "message")

# With tags (useful for Puma or other standalone use cases)
formatter = JsonLogging::Formatter.new(tags: ["Puma"])
formatter.call("INFO", Time.now, nil, "message")  # Output includes "Puma" tag in context

# Multiple tags
formatter = JsonLogging::Formatter.new(tags: ["Puma", "Worker"])
formatter.call("INFO", Time.now, nil, "message")  # Output includes both tags
```

**Note:** When used with a logger (via `JsonLogging.new`), the logger uses `FormatterWithTags` which automatically includes tags from the logger's tagged context. Use `Formatter` directly only when you need a standalone formatter without a logger instance.

### JsonLogging.with_context

Add thread-local context that appears in all log entries within the block:

```ruby
JsonLogging.with_context(user_id: 123, request_id: "abc") do
  logger.info("message")  # Will include user_id and request_id in context
end
```

### JsonLogging.additional_context

Returns the current thread-local context when called without arguments, or sets a transformer when called with a block or assigned a proc.

**Getting context:**
```ruby
JsonLogging.with_context(user_id: 5) do
  JsonLogging.additional_context  # => {user_id: 5}
end
```

**Setting a transformer:**
You can customize how `additional_context` is built by setting a transformer. This is useful for adding default fields, computed values, or filtering context. Supports both block and assignment syntax. Note: keys are automatically stringified, so no key transformation is needed.

```ruby
# Using a block (recommended)
JsonLogging.additional_context do |context|
  context.merge(
    environment: Rails.env,
    hostname: Socket.gethostname,
    app_version: MyApp::VERSION
  )
end

# Using assignment with a proc
JsonLogging.additional_context = ->(context) do
  context.merge(environment: Rails.env, hostname: Socket.gethostname)
end

# Add computed values based on current request
JsonLogging.additional_context do |context|
  context.merge(
    request_id: Current.request_id,
    user_agent: Current.user_agent,
    ip_address: Current.ip_address
  )
end

# Filter out nil values
JsonLogging.additional_context do |context|
  context.compact
end
```

The transformer receives the current thread-local context hash and should return a hash. If the transformer raises an error, the base context will be returned to avoid breaking logging.

**Note:** The transformer is called every time a log entry is created, so keep it lightweight to avoid performance issues.

### Inherited Rails Logger Features

Since `JsonLogging::JsonLogger` extends `ActiveSupport::Logger`, it inherits all standard Rails logger features:

#### Silencing Logs

Temporarily silence logs below a certain severity level:

```ruby
logger.silence(Logger::ERROR) do
  logger.debug("This won't be logged")
  logger.info("This won't be logged")
  logger.warn("This won't be logged")
  logger.error("This WILL be logged")
end
```

#### Thread-Local Log Levels (Rails 7.1+)

Set a log level that only affects the current thread/Fiber:

```ruby
# Set thread-local level
logger.local_level = :debug

# Only this thread will log at debug level
logger.debug("Debug message") # Will be logged

# Other threads still use the global level
```

This is useful for:
- Debugging specific requests without changing global log level
- Temporary verbose logging in background jobs
- Per-request log level changes

**Note:** `local_level` is available in Rails 7.1+. In Rails 6-7.0, only the global `level` is available.

#### Standard Logger Methods

All standard Ruby Logger and ActiveSupport::Logger methods work:

```ruby
logger.level = Logger::WARN           # Set log level
logger.level                         # Get current level
logger.debug?                        # Check if debug level is enabled
logger.info?                         # Check if info level is enabled
logger.close                         # Close the logger
logger.reopen                       # Reopen the logger (if supported by logdev)
```

## Features

- **Native tagged logging**: Use `logger.tagged("TAG")` just like Rails' tagged logger
- **Smart message parsing**: Automatically handles hashes, JSON strings, plain strings, and Exception objects (with class, message, and backtrace)
- **Thread-safe context**: `JsonLogging.with_context` works across threads
- **Rails 7.1+ thread/Fiber safety**: Uses `ActiveSupport::IsolatedExecutionState` for improved concurrency
- **Never raises**: Formatter and logger methods handle errors gracefully with fallback entries
- **Single-line JSON**: Each log entry is a single line, safe for log aggregation tools

## Security & privacy

- **Rails ParameterFilter integration**: Automatically uses `Rails.application.config.filter_parameters` to filter sensitive data (passwords, tokens, etc.). This includes encrypted attributes automatically. See [Rails parameter filtering guide](https://thoughtbot.com/blog/parameter-filtering).
- **Input sanitization**: Removes control characters, truncates long strings, and limits structure depth/size:
  - Maximum string length: 10,000 characters (truncated with `...[truncated]` suffix)
  - Maximum context hash size: 50 keys (additional keys are truncated)
  - Maximum nesting depth: 10 levels (deeper structures return `{"error" => "max_depth_exceeded"}`)
  - Maximum backtrace lines: 20 lines per exception
- **Single-line JSON**: Emits single-line JSON to avoid log injection via newlines
- **Never fails**: Formatter and logger never raise; fallback to safe entries on serialization errors
- **Sensitive key detection**: Falls back to pattern matching when Rails ParameterFilter isn't available
- **You control context**: You decide what goes into context via `JsonLogging.with_context`; avoid sensitive data

### Configuring sensitive parameter filtering

This gem automatically uses Rails' `config.filter_parameters` when available. Configure it in `config/initializers/filter_parameter_logging.rb`:

```ruby
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn
]
```

The gem will automatically filter these from all log entries, including context data. Encrypted attributes (using Rails 7+ `encrypts`) are automatically filtered as well.

## Development

```bash
# Install dependencies
bundle install
bundle exec appraisal install

# Run tests for current Rails version
bundle exec rspec

# Run tests for all Rails versions (6.0, 6.1, 7.0, 7.1, 7.2, 8.0)
bin/appraisals

# Run tests for specific Rails version
bin/appraisals rails-7.0

# Run tests for multiple versions
bin/appraisals rails-7.0 rails-8.0

# Or use appraisal directly
bundle exec appraisal rails-7.0 rspec

bundle exec standardrb --fix
```

## License

MIT
