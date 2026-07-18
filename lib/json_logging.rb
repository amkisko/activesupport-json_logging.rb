require "logger"
require "json"
require "time"

require_relative "json_logging/version"
require_relative "json_logging/helpers"
require_relative "json_logging/sanitizer"
require_relative "json_logging/message_parser"
require_relative "json_logging/payload_builder"
require_relative "json_logging/line_encoder"
require_relative "json_logging/formatter"
require_relative "json_logging/formatter_with_tags"
require_relative "json_logging/json_logger_extension"
require_relative "json_logging/json_logger"
require_relative "json_logging/event_subscriber"

module JsonLogging
  THREAD_CONTEXT_KEY = :__json_logging_context
  SANITIZED_CONTEXT_CACHE_KEY = :__json_logging_sanitized_context
  @additional_context_warned = Set.new
  @additional_context_transformer = nil

  def self.context_storage
    if defined?(ActiveSupport::IsolatedExecutionState)
      ActiveSupport::IsolatedExecutionState
    else
      Thread.current
    end
  end
  private_class_method :context_storage

  def self.with_context(extra_context)
    storage = context_storage
    original = storage[THREAD_CONTEXT_KEY]
    storage[THREAD_CONTEXT_KEY] = (original || {}).merge(safe_hash(extra_context))
    invalidate_sanitized_context_cache(storage)
    yield
  ensure
    storage[THREAD_CONTEXT_KEY] = original
    invalidate_sanitized_context_cache(storage)
  end

  # Returns the current thread-local context when called without arguments,
  # or sets a transformer when called with a block or assigned a proc.
  #
  # @example Getting context
  #   JsonLogging.additional_context  # => {user_id: 123, ...}
  #
  # @example Setting transformer with block
  #   JsonLogging.additional_context do |context|
  #     context.merge(environment: Rails.env, hostname: Socket.gethostname)
  #   end
  #
  # @example Setting transformer with assignment
  #   JsonLogging.additional_context = ->(context) { context.merge(env: Rails.env) }
  def self.additional_context(*args, &block)
    if args.any? || block_given?
      return public_send(:additional_context=, args.first || block)
    end

    begin
      base_context = (context_storage[THREAD_CONTEXT_KEY] || {}).dup
    rescue => e
      warn_additional_context_once(:dup, "thread context dup failed", e)
      base_context = {}
    end

    transformer = @additional_context_transformer
    if transformer.is_a?(Proc)
      begin
        transformer.call(base_context)
      rescue => e
        warn_additional_context_once(:transformer, "additional_context transformer failed", e)
        base_context
      end
    else
      base_context
    end
  end

  def self.additional_context=(proc_or_block)
    @additional_context_transformer = proc_or_block
    invalidate_sanitized_context_cache(context_storage)
  end

  def self.additional_context_for_payload
    if @additional_context_transformer.is_a?(Proc)
      return sanitized_context_from(compact_context(additional_context))
    end

    storage = context_storage
    cached = storage[SANITIZED_CONTEXT_CACHE_KEY]
    return cached if cached

    raw_context = storage[THREAD_CONTEXT_KEY]
    if raw_context.nil? || (raw_context.is_a?(Hash) && raw_context.empty?)
      return storage[SANITIZED_CONTEXT_CACHE_KEY] = {}.freeze
    end

    sanitized = sanitized_context_from(compact_context(raw_context))
    storage[SANITIZED_CONTEXT_CACHE_KEY] = sanitized.freeze
    sanitized
  end

  def self.safe_hash(obj)
    obj.is_a?(Hash) ? obj : {}
  rescue
    {}
  end

  def self.warn_additional_context_once(key, message, error)
    return if @additional_context_warned.include?(key)

    @additional_context_warned.add(key)
    warn "[activesupport-json_logging] #{message} (#{error.class}: #{error.message})"
  end
  private_class_method :warn_additional_context_once

  def self.compact_context(context)
    return {} unless context.is_a?(Hash)
    return {} if context.empty?

    context.compact
  end
  private_class_method :compact_context

  def self.sanitized_context_from(compacted_context)
    return {} if compacted_context.empty?

    Sanitizer.sanitize_hash(compacted_context)
  end
  private_class_method :sanitized_context_from

  def self.invalidate_sanitized_context_cache(storage)
    storage[SANITIZED_CONTEXT_CACHE_KEY] = nil
  end
  private_class_method :invalidate_sanitized_context_cache

  # Returns an `ActiveSupport::Logger` that has already been wrapped with JSON logging concern.
  #
  # @param *args Arguments passed to ActiveSupport::Logger.new
  # @param **kwargs Keyword arguments passed to ActiveSupport::Logger.new
  # @return [Logger] A logger wrapped with JSON formatting and tagged logging support
  #
  # @example
  #   logger = JsonLogging.logger($stdout)
  #   logger.info("Stuff")  # Logs JSON formatted entry
  def self.logger(*args, **kwargs)
    new(ActiveSupport::Logger.new(*args, **kwargs))
  end

  # Wraps any standard Logger object to provide JSON formatting capabilities.
  # Similar to ActiveSupport::TaggedLogging.new
  #
  # @param logger [Logger] Any standard Logger object (Logger, ActiveSupport::Logger, etc.)
  # @return [Logger] A logger extended with JSON formatting and tagged logging support
  #
  # @example
  #   logger = JsonLogging.new(Logger.new(STDOUT))
  #   logger.info("Stuff")  # Logs JSON formatted entry
  #
  # @example With tagged logging
  #   logger = JsonLogging.new(Logger.new(STDOUT))
  #   logger.tagged("BCX") { logger.info("Stuff") }  # Logs with tags
  #   logger.tagged("BCX").info("Stuff")  # Logs with tags (non-block form)
  def self.new(logger)
    logger = prepare_logger_clone(logger)
    logger.extend(JsonLoggerExtension)
    formatter_with_tags = FormatterWithTags.new(logger)
    logger.instance_variable_set(:@formatter_with_tags, formatter_with_tags)
    # Custom formatters are not supported: JSON output requires FormatterWithTags.
    logger.formatter = formatter_with_tags

    logger
  end

  def self.prepare_logger_clone(logger)
    logger = logger.clone
    if logger.formatter
      logger.formatter = logger.formatter.clone

      # Workaround for https://bugs.ruby-lang.org/issues/20250
      # Can be removed when Ruby 3.4 is the least supported version.
      logger.formatter.object_id if logger.formatter.is_a?(Proc)
    else
      # Ensure we set a default formatter so we aren't extending nil!
      # Use ActiveSupport::Logger::SimpleFormatter if available, otherwise default Logger::Formatter
      logger.formatter = if defined?(ActiveSupport::Logger::SimpleFormatter)
        ActiveSupport::Logger::SimpleFormatter.new
      else
        ::Logger::Formatter.new
      end
    end

    logger
  end
  private_class_method :prepare_logger_clone
end
