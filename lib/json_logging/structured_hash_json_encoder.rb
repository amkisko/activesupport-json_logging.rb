require_relative "structured_hash_sanitizer"

module JsonLogging
  module StructuredHashJsonEncoder
    LEAF_THRESHOLD = 40

    module_function

    def try_encode_line(hash, severity:, timestamp:, field_overrides: {})
      tree = prepared_tree(hash, field_overrides: field_overrides)
      return nil unless tree

      append_json_line(
        tree,
        severity: severity,
        timestamp: timestamp,
        field_overrides: field_overrides
      )
    end

    def encode_line(hash, severity:, timestamp:, field_overrides: {})
      tree = encode_tree(hash, field_overrides: field_overrides)
      append_json_line(
        tree,
        severity: severity,
        timestamp: timestamp,
        field_overrides: field_overrides
      )
    end

    def encode_tree(hash, field_overrides: {})
      limited_hash = Sanitizer.limited_hash_for_sanitization(hash)
      filter = Sanitizer.rails_parameter_filter
      omit_keys = override_keys(field_overrides)
      jsonable = Sanitizer::StructuredHash.jsonable_tree(limited_hash, omit_keys: omit_keys)
      filtered_jsonable_tree(jsonable, filter: filter)
    end

    def prepared_tree(hash, field_overrides: {})
      return nil if Sanitizer.primitive_log_hash?(hash)

      filter = Sanitizer.rails_parameter_filter
      return nil if filter && Sanitizer.rails_parameter_filter_requires_full_tree_walk?
      return nil unless Sanitizer::StructuredHash.structured_log_hash?(hash)

      limited_hash = Sanitizer.limited_hash_for_sanitization(hash)
      omit_keys = override_keys(field_overrides)
      jsonable = Sanitizer::StructuredHash.jsonable_tree(
        limited_hash,
        omit_keys: omit_keys,
        count_leaves: true
      )
      return nil if jsonable.leaf_count <= LEAF_THRESHOLD

      filtered_jsonable_tree(jsonable, filter: filter)
    end

    def filtered_jsonable_tree(jsonable, filter:)
      return jsonable.tree unless filter
      return jsonable.tree if Sanitizer.rails_parameter_filter_requires_full_tree_walk?

      filter.filter(Sanitizer::StructuredHash.stringify(jsonable.tree))
    end

    def append_json_line(tree, severity:, timestamp:, field_overrides:)
      body = JSON.generate(tree)
      extras = field_overrides.merge("severity" => severity, "timestamp" => timestamp)
      extra_json = extras.map { |key, value| "#{JSON.generate(key.to_s)}:#{JSON.generate(value)}" }.join(",")
      "#{body.chop},#{extra_json}}\n"
    end

    def override_keys(field_overrides)
      field_overrides.keys.map(&:to_s)
    end
  end
end
