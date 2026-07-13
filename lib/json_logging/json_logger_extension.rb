module JsonLogging
  # Module that extends any Logger with JSON formatting capabilities
  # This is used by JsonLogging.new to wrap standard loggers
  module JsonLoggerExtension
    def formatter
      @formatter_with_tags ||= begin
        formatter_with_tags = FormatterWithTags.new(self)
        instance_variable_set(:@formatter, formatter_with_tags)
        formatter_with_tags
      end
    end

    def formatter=(_ignored)
      # Custom formatters are ignored; JSON output requires FormatterWithTags.
      formatter_with_tags = @formatter_with_tags || FormatterWithTags.new(self)
      instance_variable_set(:@formatter, formatter_with_tags)
      @formatter_with_tags = formatter_with_tags
    end

    def add(severity, message = nil, progname = nil, &block)
      return true if severity < level

      msg = nil
      msg = extract_log_message(message, progname, &block)
      line = LineEncoder.build_line(
        msg: msg,
        severity: severity,
        timestamp: Helpers.current_timestamp,
        tags: formatter.current_tags,
        additional_context: JsonLogging.additional_context_for_payload,
        additional_context_sanitized: true,
        sanitize_tags: false
      )
      @logdev&.write(line)
      true
    rescue => e
      write_add_fallback(severity, msg, e)
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
        # This matches Rails' TaggedLogging behavior
        logger.formatter.extend(LocalTagStorage)
        # Push tags through formatter (matches Rails delegation pattern)
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

    def extract_log_message(message, progname, &block)
      if message.nil?
        block ? block.call : progname
      else
        message
      end
    end

    def write_add_fallback(severity, msg, error)
      msg ||= "<uninitialized>"
      fallback = {
        timestamp: Helpers.current_timestamp,
        severity: Severity.name_for(severity),
        message: Sanitizer.sanitize_string(Helpers.safe_string(msg)),
        logger_error: {
          class: Sanitizer.sanitize_string(error.class.name),
          message: Sanitizer.sanitize_string(Helpers.safe_string(error.message))
        }
      }
      @logdev&.write(LineEncoder.to_json_line(fallback))
    end

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
      flat = Sanitizer.prepare_tags(tags)
      return if flat.empty?

      set_tags(current_tags + flat)
    end

    def clear_tags!
      set_tags([])
    end

    def severity_name(severity)
      Severity.name_for(severity)
    end

    def stringify_keys(obj)
      LineEncoder.deep_stringify_structure(obj)
    end
  end

  # Module for preserving current tags when creating nested tagged loggers
  # Similar to ActiveSupport::TaggedLogging::LocalTagStorage
  # When extended on a formatter, stores tags locally instead of using thread-local storage
  # Uses tag_stack attribute accessor pattern to match Rails' TaggedLogging behavior
  module LocalTagStorage
    attr_accessor :tag_stack

    def self.extended(base)
      base.tag_stack = LocalTagStack.new
    end

    # Simple tag stack implementation for local tag storage
    # Similar to ActiveSupport::TaggedLogging::TagStack but simplified for JSON logging
    class LocalTagStack
      attr_reader :tags

      def initialize
        @tags = []
      end

      def push_tags(tags)
        flat = Sanitizer.prepare_tags(tags)
        return [] if flat.empty?

        @tags.concat(flat)
        flat
      end

      def pop_tags(count = 1)
        return [] if count <= 0

        @tags.pop(count)
      end

      def clear
        @tags.clear
      end
    end
  end
end
