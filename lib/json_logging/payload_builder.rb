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
      return payload if merge_context_skippable?(payload, additional_context: additional_context, tags: tags)
      return merge_tags_only(payload, tags: tags, sanitize_tags: sanitize_tags) if tags_only_merge?(payload, additional_context: additional_context, tags: tags)

      existing_context = payload["context"].is_a?(Hash) ? payload["context"] : {}
      user_context = filtered_user_context(additional_context, sanitized: additional_context_sanitized)
      deduped = user_context.reject { |key, _| payload.key?(key) || payload.key?(key.to_s) }
      merged_context = existing_context.merge(deduped)

      assign_tags!(payload, tags: tags, sanitize_tags: sanitize_tags) unless tags.empty?
      assign_context!(payload, merged_context) unless merged_context.empty?
      payload
    end

    def filtered_user_context(additional_context, sanitized:)
      context = resolve_additional_context(additional_context, sanitized: sanitized)
      context.except(*SYSTEM_CONTROLLED_KEYS)
    end

    def resolve_additional_context(additional_context, sanitized:)
      if sanitized
        additional_context.is_a?(Hash) ? additional_context : {}
      elsif additional_context.is_a?(Hash) && !additional_context.empty?
        Sanitizer.sanitize_hash(additional_context)
      else
        additional_context || {}
      end
    end

    def assign_tags!(payload, tags:, sanitize_tags:)
      existing_tags = Array(payload["tags"])
      prepared_tags = sanitize_tags ? tags.map { |tag| Sanitizer.sanitize_string(tag.to_s) } : tags
      payload["tags"] = (existing_tags + prepared_tags).uniq
    end

    def assign_context!(payload, merged_context)
      payload["context"] = if merged_context.keys.all? { |key| key.is_a?(String) }
        merged_context
      else
        merged_context.transform_keys(&:to_s)
      end
    end

    def empty_additional_context?(additional_context)
      additional_context.nil? || (additional_context.respond_to?(:empty?) && additional_context.empty?)
    end

    def merge_context_skippable?(payload, additional_context:, tags:)
      tags.empty? &&
        empty_additional_context?(additional_context) &&
        payload_context_empty?(payload)
    end

    def payload_context_empty?(payload)
      existing_context = payload["context"]
      existing_context.nil? || (existing_context.respond_to?(:empty?) && existing_context.empty?)
    end

    def tags_only_merge?(payload, additional_context:, tags:)
      !tags.empty? &&
        empty_additional_context?(additional_context) &&
        payload_context_empty?(payload)
    end

    def merge_tags_only(payload, tags:, sanitize_tags:)
      raw = payload["tags"]
      existing_tags = raw ? Array(raw) : []
      prepared_tags = sanitize_tags ? tags.map { |tag| Sanitizer.sanitize_string(tag.to_s) } : tags
      payload["tags"] = (existing_tags + prepared_tags).uniq
      payload
    end

    def context_payload_portion(additional_context)
      return {} unless additional_context.is_a?(Hash)
      return additional_context if additional_context.empty?

      additional_context.reject do |key, _|
        SYSTEM_CONTROLLED_KEYS.include?(key) || SYSTEM_CONTROLLED_KEYS.include?(key.to_s)
      end
    end
  end
end
