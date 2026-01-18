module JsonLogging
  module Helpers
    module_function

    # Normalize timestamp to ISO8601 with microseconds
    def normalize_timestamp(timestamp)
      time = timestamp || current_time
      time.utc.iso8601(6)
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
