module JsonLogging
  class Formatter < ::Logger::Formatter
    def initialize(tags: [])
      super()
      @tags = Array(tags)
    end

    attr_reader :tags

    def call(severity, timestamp, progname, msg)
      LineEncoder.build_line(
        msg: msg,
        severity: severity,
        timestamp: Helpers.normalize_timestamp(timestamp),
        tags: @tags,
        additional_context: JsonLogging.additional_context.compact
      )
    rescue => e
      build_fallback_output(severity, timestamp, msg, e)
    end

    private

    def build_fallback_output(severity, timestamp, msg, error)
      timestamp_str = Helpers.normalize_timestamp(timestamp)
      fallback_payload = {
        timestamp: timestamp_str,
        severity: Severity.name_for(severity),
        message: Sanitizer.sanitize_string(Helpers.safe_string(msg)),
        formatter_error: {
          class: Sanitizer.sanitize_string(error.class.name),
          message: Sanitizer.sanitize_string(Helpers.safe_string(error.message))
        }
      }
      LineEncoder.to_json_line(fallback_payload)
    end
  end
end
