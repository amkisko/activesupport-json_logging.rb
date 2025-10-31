module JsonLogging
  class Formatter < ::Logger::Formatter
    def initialize(tags: [])
      super()
      @tags = Array(tags)
    end

    attr_reader :tags

    def call(severity, timestamp, progname, msg)
      timestamp_str = Helpers.normalize_timestamp(timestamp)
      payload = PayloadBuilder.build_base_payload(msg, severity: severity, timestamp: timestamp_str)
      payload = PayloadBuilder.merge_context(payload, additional_context: JsonLogging.additional_context.compact, tags: @tags)

      "#{payload.compact.to_json}\n"
    rescue => e
      build_fallback_output(severity, timestamp, msg, e)
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
