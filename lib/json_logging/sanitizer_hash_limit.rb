module JsonLogging
  module SanitizerHashLimit
    FILTERED = "[FILTERED]"

    module_function

    def apply(hash, filter_config:)
      return hash if hash.size <= Sanitizer::MAX_CONTEXT_SIZE

      truncated = {}
      kept = 0
      extra_filtered = 0
      hash.each do |key, value|
        if kept < Sanitizer::MAX_CONTEXT_SIZE
          truncated[key] = value
          kept += 1
        elsif extra_filtered < Sanitizer::MAX_CONTEXT_SIZE && key_requires_filtering?(key, filter_config)
          truncated[key] = FILTERED
          extra_filtered += 1
        end
      end
      truncated["_truncated"] = true
      truncated
    end

    def key_requires_filtering?(key, filter_config)
      return true if Sanitizer.sensitive_key?(key)

      Array(filter_config).any? do |filter|
        next false if filter.is_a?(Proc)

        key_string = key.to_s
        if filter.is_a?(Regexp)
          filter.match?(key_string)
        else
          token = filter.to_s
          !token.empty? && !token.include?(".") && key_string.match?(/#{Regexp.escape(token)}/i)
        end
      end
    end
  end
end
