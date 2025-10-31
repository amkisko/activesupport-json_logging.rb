module JsonLogging
  module Helpers
    module_function

    # Normalize timestamp to ISO8601 with microseconds
    def normalize_timestamp(timestamp)
      (timestamp || Time.now).utc.iso8601(6)
    end

    # Safely convert object to string, never raises
    def safe_string(obj)
      obj.to_s
    rescue
      "<unprintable>"
    end
  end
end
