module JsonLogging
  # Module that extends any Logger with JSON formatting capabilities
  # This is used by JsonLogging.new to wrap standard loggers
  module JsonLoggerExtension
    SEVERITY_NAMES = {
      ::Logger::DEBUG => "DEBUG",
      ::Logger::INFO => "INFO",
      ::Logger::WARN => "WARN",
      ::Logger::ERROR => "ERROR",
      ::Logger::FATAL => "FATAL",
      ::Logger::UNKNOWN => "UNKNOWN"
    }.freeze

    def formatter
      @formatter_with_tags ||= begin
        formatter_with_tags = FormatterWithTags.new(self)
        instance_variable_set(:@formatter, formatter_with_tags)
        formatter_with_tags
      end
    end

    def formatter=(formatter)
      # Always use FormatterWithTags to ensure JSON formatting
      formatter_with_tags = @formatter_with_tags || FormatterWithTags.new(self)
      instance_variable_set(:@formatter, formatter_with_tags)
      @formatter_with_tags = formatter_with_tags
    end

    def add(severity, message = nil, progname = nil)
      return true if severity < level

      msg = if message.nil?
        if block_given?
          yield
        else
          progname
        end
      else
        message
      end

      payload = build_payload(severity, progname, msg)

      stringified = stringify_keys(payload)
      @logdev&.write("#{stringified.to_json}\n")
      true
    rescue => e
      # Never fail logging - write a fallback entry
      # Initialize msg if it wasn't set due to error
      msg ||= "<uninitialized>"

      fallback = {
        timestamp: Helpers.normalize_timestamp(Time.now),
        severity: severity_name(severity),
        message: Sanitizer.sanitize_string(Helpers.safe_string(msg)),
        logger_error: {
          class: Sanitizer.sanitize_string(e.class.name),
          message: Sanitizer.sanitize_string(Helpers.safe_string(e.message))
        }
      }
      @logdev&.write("#{fallback.compact.to_json}\n")
      true
    end

    # Override format_message to ensure it uses JSON formatting even if called directly
    def format_message(severity, datetime, progname, msg)
      formatter.call(severity, datetime, progname, msg)
    end

    # Native tag support compatible with Rails.logger.tagged
    def tagged(*tags)
      if block_given?
        formatter.tagged(*tags) { yield self }
      else
        # Return a new wrapped logger with tags applied (similar to TaggedLogging)
        logger = JsonLogging.new(self)
        # Extend formatter with LocalTagStorage to preserve current tags when creating nested loggers
        logger.formatter.extend(LocalTagStorage)
        logger.formatter.push_tags(*formatter.current_tags, *tags)
        logger
      end
    end

    # Flush tags (used by Rails when request completes)
    def flush
      clear_tags!
      super if defined?(super)
    end

    private

    def tags_key
      @tags_key ||= :"json_logging_tags_#{object_id}"
    end

    def current_tags
      # Use IsolatedExecutionState (Rails 7.1+) for better thread/Fiber safety
      # Falls back to Thread.current for Rails 6-7.0
      if defined?(ActiveSupport::IsolatedExecutionState)
        ActiveSupport::IsolatedExecutionState[tags_key] ||= []
      else
        Thread.current[tags_key] ||= []
      end
    end

    def set_tags(new_tags)
      # Use IsolatedExecutionState (Rails 7.1+) for better thread/Fiber safety
      # Falls back to Thread.current for Rails 6-7.0
      if defined?(ActiveSupport::IsolatedExecutionState)
        ActiveSupport::IsolatedExecutionState[tags_key] = new_tags
      else
        Thread.current[tags_key] = new_tags
      end
    end

    def push_tags(tags)
      flat = tags.flatten.compact.map(&:to_s).reject(&:empty?)
      return if flat.empty?
      set_tags(current_tags + flat)
    end

    def clear_tags!
      set_tags([])
    end

    def build_payload(severity, _progname, msg)
      payload = PayloadBuilder.build_base_payload(
        msg,
        severity: severity_name(severity),
        timestamp: Helpers.normalize_timestamp(Time.now)
      )
      payload = PayloadBuilder.merge_context(
        payload,
        additional_context: JsonLogging.additional_context.compact,
        tags: current_tags
      )

      payload.compact
    end

    def severity_name(severity)
      SEVERITY_NAMES[severity] || severity.to_s
    end

    def stringify_keys(hash)
      case hash
      when Hash
        hash.each_with_object({}) do |(k, v), result|
          result[k.to_s] = stringify_keys(v)
        end
      when Array
        hash.map { |v| stringify_keys(v) }
      else
        hash
      end
    end
  end

  # Module for preserving current tags when creating nested tagged loggers
  # Similar to ActiveSupport::TaggedLogging::LocalTagStorage
  # When extended on a formatter, stores tags locally instead of using thread-local storage
  module LocalTagStorage
    def self.extended(base)
      base.instance_variable_set(:@local_tags, [])
    end

    def push_tags(*tags)
      flat = tags.flatten.compact.map(&:to_s).reject(&:empty?)
      return if flat.empty?
      @local_tags = (@local_tags || []) + flat
    end

    def current_tags
      @local_tags || []
    end
  end
end
