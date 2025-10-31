require "logger"
require "json"
require "time"

require_relative "json_logging/version"
require_relative "json_logging/helpers"
require_relative "json_logging/sanitizer"
require_relative "json_logging/message_parser"
require_relative "json_logging/payload_builder"
require_relative "json_logging/formatter"
require_relative "json_logging/formatter_with_tags"
require_relative "json_logging/json_logger_extension"
require_relative "json_logging/json_logger"

module JsonLogging
  THREAD_CONTEXT_KEY = :__json_logging_context

  def self.with_context(extra_context)
    original = Thread.current[THREAD_CONTEXT_KEY]
    Thread.current[THREAD_CONTEXT_KEY] = (original || {}).merge(safe_hash(extra_context))
    yield
  ensure
    Thread.current[THREAD_CONTEXT_KEY] = original
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
      base_context = (Thread.current[THREAD_CONTEXT_KEY] || {}).dup
    rescue
      base_context = {}
    end

    transformer = @additional_context_transformer
    if transformer.is_a?(Proc)
      begin
        transformer.call(base_context)
      rescue
        base_context
      end
    else
      base_context
    end
  end

  def self.additional_context=(proc_or_block)
    @additional_context_transformer = proc_or_block
  end

  def self.safe_hash(obj)
    obj.is_a?(Hash) ? obj : {}
  rescue
    {}
  end

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

    logger.extend(JsonLoggerExtension)
    formatter_with_tags = FormatterWithTags.new(logger)
    logger.instance_variable_set(:@formatter_with_tags, formatter_with_tags)
    logger.formatter = formatter_with_tags

    logger
  end
end
