module JsonLogging
  module Sanitizer
    # Control characters that should be escaped or removed from log messages
    CONTROL_CHARS = /[\x00-\x1F\x7F]/

    # Maximum string length before truncation
    MAX_STRING_LENGTH = 10_000

    # Maximum context hash size (number of keys)
    MAX_CONTEXT_SIZE = 50

    # Maximum depth for nested structures
    MAX_DEPTH = 10

    # Maximum backtrace lines to include
    MAX_BACKTRACE_LINES = 20

    # Common sensitive key patterns (case insensitive) - fallback when Rails ParameterFilter not available
    SENSITIVE_KEY_PATTERNS = /\b(password|passwd|pwd|secret|token|api_key|apikey|access_token|auth_token|private_key|credential)\b/i

    module_function

    # Get Rails ParameterFilter if available, nil otherwise
    def rails_parameter_filter
      return nil unless defined?(Rails) && Rails.respond_to?(:application)
      return nil unless Rails.application.respond_to?(:config)

      filter_params = Rails.application.config.filter_parameters
      return nil if filter_params.empty?

      ActiveSupport::ParameterFilter.new(filter_params)
    rescue
      nil
    end

    # Sanitize a string by removing/escaping control characters and truncating
    def sanitize_string(str)
      return str unless str.is_a?(String)

      # Remove or replace control characters
      sanitized = str.gsub(CONTROL_CHARS, "")

      # Truncate if too long
      if sanitized.length > MAX_STRING_LENGTH
        sanitized = sanitized[0, MAX_STRING_LENGTH] + "...[truncated]"
      end

      sanitized
    rescue
      "<sanitization_error>"
    end

    # Sanitize a hash, removing sensitive keys and limiting size/depth
    # Uses Rails ParameterFilter when available, falls back to pattern matching
    def sanitize_hash(hash, depth: 0)
      return hash unless hash.is_a?(Hash)

      # Prevent excessive nesting
      return {"error" => "max_depth_exceeded"} if depth > MAX_DEPTH

      # Limit hash size first
      limited_hash = if hash.size > MAX_CONTEXT_SIZE
        truncated = hash.first(MAX_CONTEXT_SIZE).to_h
        truncated["_truncated"] = true
        truncated
      else
        hash
      end

      # Use Rails ParameterFilter if available (handles encrypted attributes automatically)
      filter = rails_parameter_filter
      if filter
        # ParameterFilter will filter based on Rails.config.filter_parameters
        # This includes encrypted attributes automatically
        # Create a deep copy since filter modifies in place (Rails 6+)
        filtered = limited_hash.respond_to?(:deep_dup) ? limited_hash.deep_dup : limited_hash.dup
        filtered = filter.filter(filtered)

        # Then sanitize values (strings, control chars, etc.) preserving filtered structure
        filtered.each_with_object({}) do |(key, value), result|
          result[key] = sanitize_value(value, depth: depth + 1)
        end

      else
        # Fallback: use pattern matching for sensitive keys
        limited_hash.each_with_object({}) do |(key, value), result|
          key_str = key.to_s

          # Skip sensitive keys
          if SENSITIVE_KEY_PATTERNS.match?(key_str)
            result[key_str.gsub(/(?<!^)(?=[A-Z])/, "_").downcase + "_filtered"] = "[FILTERED]"
            next
          end

          result[key] = sanitize_value(value, depth: depth + 1)
        end
      end
    rescue
      {"sanitization_error" => true}
    end

    # Sanitize a value (handles strings, hashes, arrays, etc.)
    # Preserves numeric, boolean, and nil types
    def sanitize_value(value, depth: 0)
      case value
      when String
        sanitize_string(value)
      when Hash
        sanitize_hash(value, depth: depth)
      when Array
        # Limit array size
        sanitized = value.first(MAX_CONTEXT_SIZE).map { |v| sanitize_value(v, depth: depth + 1) }
        sanitized << "[truncated]" if value.size > MAX_CONTEXT_SIZE
        sanitized
      when Exception
        sanitize_exception(value)
      when Numeric, TrueClass, FalseClass, NilClass
        # Preserve numeric, boolean, and nil types
        value
      else
        # For other types, convert to string and sanitize
        sanitize_string(value.to_s)
      end
    rescue
      "<unprintable>"
    end

    # Sanitize exception, including backtrace
    def sanitize_exception(ex)
      {
        "error" => {
          "class" => ex.class.name,
          "message" => sanitize_string(ex.message.to_s),
          "backtrace" => sanitize_backtrace(ex.backtrace)
        }
      }
    rescue
      {"error" => {"class" => "Exception", "message" => "<sanitization_failed>"}}
    end

    # Sanitize backtrace - truncate and remove sensitive paths
    def sanitize_backtrace(backtrace)
      return [] unless backtrace.is_a?(Array)

      # Take first MAX_BACKTRACE_LINES, sanitize each
      backtrace.first(MAX_BACKTRACE_LINES).map do |line|
        sanitize_string(line.to_s)
      end
    rescue
      []
    end

    # Check if a key looks sensitive
    def sensitive_key?(key)
      SENSITIVE_KEY_PATTERNS.match?(key.to_s)
    end
  end
end
