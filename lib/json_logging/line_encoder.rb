require "active_support/core_ext/hash/keys"

require_relative "message_parser"
require_relative "severity"
require_relative "payload_builder"
require_relative "structured_hash_json_encoder"

module JsonLogging
  module LineEncoder
    module_function

    def build_line(msg:, severity:, timestamp:, tags:, additional_context:, additional_context_sanitized: false, sanitize_tags: true)
      if simple_string_line?(msg, tags, additional_context)
        return simple_string_json_line(
          message: msg,
          severity: Severity.name_for(severity),
          timestamp: timestamp
        )
      end

      if tagged_simple_string_line?(msg, tags, additional_context)
        return tagged_simple_string_json_line(
          message: msg,
          severity: Severity.name_for(severity),
          timestamp: timestamp,
          tags: tags,
          sanitize_tags: sanitize_tags
        )
      end

      if contextual_simple_string_line?(msg, tags, additional_context, additional_context_sanitized: additional_context_sanitized)
        return contextual_simple_string_json_line(
          message: msg,
          severity: Severity.name_for(severity),
          timestamp: timestamp,
          additional_context: additional_context
        )
      end

      if standalone_hash_line?(msg, tags, additional_context)
        return standalone_hash_json_line(
          message: msg,
          severity: Severity.name_for(severity),
          timestamp: timestamp
        )
      end

      if tagged_hash_line?(msg, tags, additional_context)
        return tagged_hash_json_line(
          message: msg,
          severity: Severity.name_for(severity),
          timestamp: timestamp,
          tags: tags,
          sanitize_tags: sanitize_tags
        )
      end

      if contextual_hash_line?(msg, tags, additional_context, additional_context_sanitized: additional_context_sanitized)
        return contextual_hash_json_line(
          message: msg,
          severity: Severity.name_for(severity),
          timestamp: timestamp,
          additional_context: additional_context
        )
      end

      sev = Severity.name_for(severity)
      payload = PayloadBuilder.build_base_payload(msg, severity: sev, timestamp: timestamp)
      unless tags.empty? && PayloadBuilder.empty_additional_context?(additional_context)
        payload = PayloadBuilder.merge_context(
          payload,
          additional_context: additional_context,
          tags: tags,
          additional_context_sanitized: additional_context_sanitized,
          sanitize_tags: sanitize_tags
        )
      end
      to_json_line(payload)
    end

    def to_json_line(payload_hash)
      compacted = payload_hash.compact
      json_payload = string_keyed_structure?(compacted) ? compacted : compacted.deep_stringify_keys
      "#{json_payload.to_json}\n"
    end

    def string_keyed_structure?(object)
      case object
      when Hash
        object.keys.all?(String) && object.values.all? { |value| string_keyed_structure?(value) }
      when Array
        object.all? { |value| string_keyed_structure?(value) }
      else
        true
      end
    end

    def simple_string_line?(message, tags, additional_context)
      message.is_a?(String) &&
        !MessageParser.json_string?(message) &&
        tags.respond_to?(:empty?) && tags.empty? &&
        additional_context.respond_to?(:empty?) && additional_context.empty?
    end

    def simple_string_json_line(message:, severity:, timestamp:)
      sanitized_message = Sanitizer.sanitize_string(message)
      "#{JSON.generate("message" => sanitized_message, "severity" => severity, "timestamp" => timestamp)}\n"
    end

    def tagged_simple_string_line?(message, tags, additional_context)
      message.is_a?(String) &&
        !MessageParser.json_string?(message) &&
        tags.respond_to?(:empty?) && !tags.empty? &&
        additional_context.respond_to?(:empty?) && additional_context.empty?
    end

    def tagged_simple_string_json_line(message:, severity:, timestamp:, tags:, sanitize_tags:)
      sanitized_message = Sanitizer.sanitize_string(message)
      prepared_tags = sanitize_tags ? Sanitizer.prepare_tags(tags) : tags
      "#{JSON.generate("message" => sanitized_message, "severity" => severity, "timestamp" => timestamp, "tags" => prepared_tags.uniq)}\n"
    end

    def contextual_simple_string_line?(message, tags, additional_context, additional_context_sanitized:)
      message.is_a?(String) &&
        !MessageParser.json_string?(message) &&
        tags.respond_to?(:empty?) && tags.empty? &&
        !PayloadBuilder.empty_additional_context?(additional_context) &&
        additional_context_sanitized
    end

    def contextual_simple_string_json_line(message:, severity:, timestamp:, additional_context:)
      sanitized_message = Sanitizer.sanitize_string(message)
      payload = {
        "message" => sanitized_message,
        "severity" => severity,
        "timestamp" => timestamp
      }
      context = PayloadBuilder.context_payload_portion(additional_context)
      payload["context"] = context unless context.empty?
      "#{JSON.generate(payload)}\n"
    end

    def standalone_hash_line?(message, tags, additional_context)
      hash_message?(message) &&
        tags.respond_to?(:empty?) && tags.empty? &&
        additional_context.respond_to?(:empty?) && additional_context.empty?
    end

    def hash_message?(message)
      message.is_a?(Hash) || (message.respond_to?(:to_hash) && !message.is_a?(String))
    end

    def standalone_hash_json_line(message:, severity:, timestamp:)
      hash = message.is_a?(Hash) ? message : message.to_hash
      line = StructuredHashJsonEncoder.try_encode_line(hash, severity: severity, timestamp: timestamp)
      return line if line

      payload = Sanitizer.sanitize_hash(hash)
      payload["severity"] = severity
      payload["timestamp"] = timestamp
      "#{JSON.generate(payload)}\n"
    end

    def tagged_hash_line?(message, tags, additional_context)
      hash_message?(message) &&
        tags.respond_to?(:empty?) && !tags.empty? &&
        additional_context.respond_to?(:empty?) && additional_context.empty?
    end

    def tagged_hash_json_line(message:, severity:, timestamp:, tags:, sanitize_tags:)
      hash = message.is_a?(Hash) ? message : message.to_hash
      prepared_tags = sanitize_tags ? Sanitizer.prepare_tags(tags) : tags
      merged_tags = (Array(hash[:tags] || hash["tags"]) + prepared_tags).uniq
      field_overrides = {"tags" => merged_tags}

      line = StructuredHashJsonEncoder.try_encode_line(
        hash,
        severity: severity,
        timestamp: timestamp,
        field_overrides: field_overrides
      )
      return line if line

      payload = Sanitizer.sanitize_hash(hash)
      payload["severity"] = severity
      payload["timestamp"] = timestamp
      payload["tags"] = merged_tags
      "#{JSON.generate(payload)}\n"
    end

    def contextual_hash_line?(message, tags, additional_context, additional_context_sanitized:)
      hash_message?(message) &&
        tags.respond_to?(:empty?) && tags.empty? &&
        !PayloadBuilder.empty_additional_context?(additional_context) &&
        additional_context_sanitized
    end

    def contextual_hash_json_line(message:, severity:, timestamp:, additional_context:)
      hash = message.is_a?(Hash) ? message : message.to_hash
      context = PayloadBuilder.context_payload_portion(additional_context)
      merged_context = {}
      unless context.empty?
        existing_context = hash[:context] || hash["context"]
        merged_context = existing_context.is_a?(Hash) ? existing_context.merge(context) : context
      end
      field_overrides = merged_context.empty? ? {} : {"context" => merged_context}

      line = StructuredHashJsonEncoder.try_encode_line(
        hash,
        severity: severity,
        timestamp: timestamp,
        field_overrides: field_overrides
      )
      return line if line

      payload = Sanitizer.sanitize_hash(hash)
      payload["severity"] = severity
      payload["timestamp"] = timestamp
      unless merged_context.empty?
        existing_context = payload["context"].is_a?(Hash) ? payload["context"] : {}
        payload["context"] = existing_context.merge(merged_context)
      end
      "#{JSON.generate(payload)}\n"
    end

    def build_sanitized_hash_payload(message:, severity:, timestamp:)
      hash = message.is_a?(Hash) ? message : message.to_hash
      payload = Sanitizer.sanitize_hash(hash)
      payload["severity"] = severity
      payload["timestamp"] = timestamp
      payload
    end

    def deep_stringify_structure(obj)
      case obj
      when Hash
        obj.deep_stringify_keys
      when Array
        obj.map { |v| deep_stringify_structure(v) }
      else
        obj
      end
    end
  end
end
