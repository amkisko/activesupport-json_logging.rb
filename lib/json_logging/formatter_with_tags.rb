module JsonLogging
  # Formatter proxy that delegates current_tags to the logger
  # This is needed for ActiveJob which expects logger.formatter.current_tags
  # Also implements call to ensure JSON formatting when formatter is used directly
  class FormatterWithTags
    def initialize(logger)
      @logger = logger
    end

    def current_tags
      @logger.send(:current_tags)
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

    # Support tagged blocks for formatter
    def tagged(*tags)
      if block_given?
        previous = @logger.send(:current_tags).dup
        @logger.send(:push_tags, tags)
        begin
          yield @logger
        ensure
          @logger.send(:set_tags, previous)
        end
      else
        @logger.send(:push_tags, tags)
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
