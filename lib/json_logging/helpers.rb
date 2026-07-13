module JsonLogging
  module Helpers
    ISO8601_MICROSECOND_UTC_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z\z/

    module_function

    # Normalize timestamp to ISO8601 with microseconds
    def normalize_timestamp(timestamp)
      return timestamp if iso8601_microsecond_utc?(timestamp)

      format_timestamp(timestamp || current_time)
    end

    def current_timestamp
      format_timestamp(current_time)
    end

    def format_timestamp(time)
      time.utc.iso8601(6)
    end

    def iso8601_microsecond_utc?(timestamp)
      timestamp.is_a?(String) && timestamp.match?(ISO8601_MICROSECOND_UTC_PATTERN)
    end

    # Get current time, using Time.zone if available, otherwise Time.now
    def current_time
      if defined?(Time.zone) && Time.zone
        Time.zone.now
      else
        Time.now
      end
    end

    # Safely convert object to string, never raises
    def safe_string(obj)
      obj.to_s
    rescue
      "<unprintable>"
    end
  end
end
