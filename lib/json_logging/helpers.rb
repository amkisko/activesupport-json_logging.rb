module JsonLogging
  module Helpers
    ISO8601_MICROSECOND_UTC_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z\z/

    # Microsecond bundle exec / hot add path: avoid fresh iso8601(6) every line when still in the same UTC second.
    TIMESTAMP_CACHE_KEY = :__json_logging_ts_cache

    module_function

    # Normalize timestamp to ISO8601 with microseconds
    def normalize_timestamp(timestamp)
      return timestamp if iso8601_microsecond_utc?(timestamp)

      format_timestamp(timestamp || current_time)
    end

    def current_timestamp
      cached_log_timestamp
    end

    def cached_log_timestamp
      storage = JsonLogging.send(:context_storage)
      now = current_time
      sec_key = now.to_i
      cache = storage[TIMESTAMP_CACHE_KEY]
      if cache.is_a?(Array) && cache[0] == sec_key && cache[1]
        return cache[1]
      end

      formatted = format_timestamp(now)
      storage[TIMESTAMP_CACHE_KEY] = [sec_key, formatted]
      formatted
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
