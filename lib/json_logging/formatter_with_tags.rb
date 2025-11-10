module JsonLogging
  # Formatter proxy that delegates current_tags to the logger
  # This is needed for ActiveJob which expects logger.formatter.current_tags
  # Also implements call to ensure JSON formatting when formatter is used directly
  class FormatterWithTags
    def initialize(logger)
      @logger = logger
    end

    def current_tags
      # If LocalTagStorage is extended on this formatter, use its tag_stack
      # This matches Rails' TaggedLogging behavior where tag_stack attribute shadows the method
      if respond_to?(:tag_stack, true) && instance_variable_defined?(:@tag_stack)
        tag_stack.tags
      else
        @logger.send(:current_tags)
      end
    end

    def call(severity, timestamp, progname, msg)
      tags = current_tags
      timestamp_str = Helpers.normalize_timestamp(timestamp)
      payload = PayloadBuilder.build_base_payload(msg, severity: severity, timestamp: timestamp_str)
      payload = PayloadBuilder.merge_context(payload, additional_context: JsonLogging.additional_context.compact, tags: tags)

      "#{payload.compact.to_json}\n"
    rescue => e
      build_fallback_output(severity, timestamp, msg, e)
    end

    def push_tags(*tags)
      # If LocalTagStorage is present, use it; otherwise use logger's thread-local storage
      if respond_to?(:tag_stack, true) && instance_variable_defined?(:@tag_stack)
        tag_stack.push_tags(tags)
      else
        @logger.send(:push_tags, tags)
      end
    end

    # Support tagged blocks for formatter
    def tagged(*tags)
      if block_given?
        # If LocalTagStorage is present, use it; otherwise use logger's thread-local storage
        if respond_to?(:tag_stack, true) && instance_variable_defined?(:@tag_stack)
          previous_count = tag_stack.tags.size
          tag_stack.push_tags(tags)
          begin
            yield @logger
          ensure
            tag_stack.pop_tags(tag_stack.tags.size - previous_count)
          end
        else
          previous = @logger.send(:current_tags).dup
          @logger.send(:push_tags, tags)
          begin
            yield @logger
          ensure
            @logger.send(:set_tags, previous)
          end
        end
      else
        if respond_to?(:tag_stack, true) && instance_variable_defined?(:@tag_stack)
          tag_stack.push_tags(tags)
        else
          @logger.send(:push_tags, tags)
        end
        self
      end
    end

    private

    def build_fallback_output(severity, timestamp, msg, error)
      timestamp_str = Helpers.normalize_timestamp(timestamp)
      fallback_payload = {
        timestamp: timestamp_str,
        severity: severity,
        message: Helpers.safe_string(msg),
        formatter_error: {
          class: Sanitizer.sanitize_string(error.class.name),
          message: Sanitizer.sanitize_string(Helpers.safe_string(error.message))
        }
      }
      "#{fallback_payload.compact.to_json}\n"
    end
  end
end
