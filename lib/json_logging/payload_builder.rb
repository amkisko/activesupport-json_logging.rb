module JsonLogging
  module PayloadBuilder
    module_function

    def build_base_payload(msg, severity: nil, timestamp: nil)
      parsed = MessageParser.parse_message(msg)
      payload = {}

      if parsed.is_a?(Hash)
        payload.merge!(parsed)
      else
        payload[:message] = parsed
      end

      payload[:severity] = severity if severity
      payload[:timestamp] = timestamp if timestamp

      payload
    end

    def merge_context(payload, additional_context:, tags: [])
      existing_context = payload[:context].is_a?(Hash) ? payload[:context] : {}

      # Sanitize additional context before merging (filters sensitive keys, limits size, sanitizes strings only)
      # Only sanitize if it's a hash - preserve other types
      sanitized_context = if additional_context.is_a?(Hash) && !additional_context.empty?
        Sanitizer.sanitize_hash(additional_context)
      else
        additional_context || {}
      end

      deduped_additional = sanitized_context.reject { |k, _| payload.key?(k) }
      merged_context = existing_context.merge(deduped_additional)

      unless tags.empty?
        existing_tags = Array(merged_context[:tags])
        # Sanitize tag strings (remove control chars, truncate)
        sanitized_tags = tags.map { |tag| Sanitizer.sanitize_string(tag.to_s) }
        merged_context[:tags] = (existing_tags + sanitized_tags).uniq
      end

      payload[:context] = merged_context unless merged_context.empty?
      payload
    end
  end
end
