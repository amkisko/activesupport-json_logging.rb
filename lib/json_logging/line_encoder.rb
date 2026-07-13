require "active_support/core_ext/hash/keys"

require_relative "severity"
require_relative "payload_builder"

module JsonLogging
  module LineEncoder
    module_function

    def build_line(msg:, severity:, timestamp:, tags:, additional_context:, additional_context_sanitized: false, sanitize_tags: true)
      sev = Severity.name_for(severity)
      payload = PayloadBuilder.build_base_payload(msg, severity: sev, timestamp: timestamp)
      payload = PayloadBuilder.merge_context(
        payload,
        additional_context: additional_context,
        tags: tags,
        additional_context_sanitized: additional_context_sanitized,
        sanitize_tags: sanitize_tags
      )
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
