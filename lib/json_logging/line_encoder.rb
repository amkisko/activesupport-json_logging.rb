require "active_support/core_ext/hash/keys"

require_relative "severity"
require_relative "payload_builder"

module JsonLogging
  module LineEncoder
    module_function

    def build_line(msg:, severity:, timestamp:, tags:, additional_context:)
      sev = Severity.name_for(severity)
      payload = PayloadBuilder.build_base_payload(msg, severity: sev, timestamp: timestamp)
      payload = PayloadBuilder.merge_context(payload, additional_context: additional_context, tags: tags)
      to_json_line(payload)
    end

    def to_json_line(payload_hash)
      "#{payload_hash.compact.deep_stringify_keys.to_json}\n"
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
