module JsonLogging
  module PayloadBuilder
    SYSTEM_CONTROLLED_KEYS = [:tags, "tags", :severity, "severity", :timestamp, "timestamp", :message, "message", :context, "context"].freeze

    module_function

    def build_base_payload(msg, severity: nil, timestamp: nil)
      parsed = MessageParser.parse_message(msg)
      payload = {}

      if parsed.is_a?(Hash)
        payload.merge!(parsed)
      else
        payload["message"] = parsed
      end

      payload["severity"] = severity if severity
      payload["timestamp"] = timestamp if timestamp

      payload
    end

    def merge_context(payload, additional_context:, tags: [], additional_context_sanitized: false, sanitize_tags: true)
      existing_context = payload["context"].is_a?(Hash) ? payload["context"] : {}

      sanitized_context = if additional_context_sanitized
        additional_context.is_a?(Hash) ? additional_context : {}
      elsif additional_context.is_a?(Hash) && !additional_context.empty?
        Sanitizer.sanitize_hash(additional_context)
      else
        additional_context || {}
      end

      user_context_filtered = sanitized_context.except(*SYSTEM_CONTROLLED_KEYS)

      deduped_additional = user_context_filtered.reject { |key, _| payload.key?(key) || payload.key?(key.to_s) }
      merged_context = existing_context.merge(deduped_additional)

      unless tags.empty?
        existing_tags = Array(payload["tags"])
        prepared_tags = sanitize_tags ? tags.map { |tag| Sanitizer.sanitize_string(tag.to_s) } : tags
        payload["tags"] = (existing_tags + prepared_tags).uniq
      end

      payload["context"] = merged_context unless merged_context.empty?
      payload
    end
  end
end
