module JsonLogging
  module Sanitizer
    module StructuredHash
      JsonableResult = Struct.new(:tree, :owned, :leaf_count)

      module_function

      def structured_log_hash?(hash, seen = nil)
        seen ||= Set.new.compare_by_identity
        return false unless seen.add?(hash)

        result = hash.all? { |_key, value| structured_log_value?(value, seen) }
        seen.delete(hash)
        result
      end

      def structured_log_value?(value, seen = nil)
        case value
        when String, Numeric, TrueClass, FalseClass, NilClass
          Sanitizer.primitive_log_value?(value)
        when Hash
          structured_log_hash?(value, seen)
        when Array
          structured_log_array?(value, seen)
        else
          false
        end
      end

      def structured_log_array?(array, seen = nil)
        array.all? { |value| structured_log_value?(value, seen) }
      end

      def sanitize(hash, depth: 0)
        return {"error" => "max_depth_exceeded"} if depth > Sanitizer::MAX_DEPTH

        filter = Sanitizer.rails_parameter_filter
        if filter
          filter.filter(stringify(hash))
        else
          sanitize_without_filter(hash, depth: depth)
        end
      end

      def sanitize_without_filter(hash, depth: 0)
        jsonable = jsonable_tree(hash, depth: depth)
        if jsonable.owned
          stringify(jsonable.tree)
        else
          jsonable.tree.dup
        end
      end

      def jsonable_tree(hash, depth: 0, seen: nil, parent_key: nil, omit_keys: nil, count_leaves: false, leaf_counter: nil)
        seen ||= Set.new.compare_by_identity
        leaf_counter = [0] if count_leaves && leaf_counter.nil?
        if depth > Sanitizer::MAX_DEPTH
          return JsonableResult.new(tree: {"error" => "max_depth_exceeded"}, owned: true, leaf_count: leaf_counter&.[](0))
        end
        unless seen.add?(hash)
          return JsonableResult.new(tree: {"error" => "cyclic_reference"}, owned: true, leaf_count: leaf_counter&.[](0))
        end

        entries = []
        owned = false

        hash.each do |key, value|
          entry = process_jsonable_entry(
            key,
            value,
            depth: depth,
            seen: seen,
            parent_key: parent_key,
            omit_keys: omit_keys,
            leaf_counter: leaf_counter
          )
          next unless entry

          key_string, encoded_value, pair_owned = entry
          owned ||= pair_owned
          entries << [key_string, encoded_value, pair_owned]
        end

        seen.delete(hash)
        leaf_count = leaf_counter&.[](0)
        unless owned
          tree = omit_root_keys(hash, omit_keys, depth: depth)
          return JsonableResult.new(tree: tree, owned: false, leaf_count: leaf_count)
        end

        result = entries.each_with_object({}) do |(key_string, encoded_value, _pair_owned), object|
          object[key_string] = encoded_value
        end
        JsonableResult.new(tree: result, owned: true, leaf_count: leaf_count)
      end

      def jsonable_value(value, depth:, seen:, parent_key:, leaf_counter: nil)
        case value
        when String
          leaf_counter[0] += 1 if leaf_counter
          sanitized = Sanitizer.sanitize_string(value)
          JsonableResult.new(tree: sanitized, owned: sanitized != value, leaf_count: nil)
        when Hash
          jsonable_tree(value, depth: depth + 1, seen: seen, parent_key: parent_key, leaf_counter: leaf_counter)
        when Array
          jsonable_array(value, depth: depth, seen: seen, parent_key: parent_key, leaf_counter: leaf_counter)
        else
          leaf_counter[0] += 1 if leaf_counter
          JsonableResult.new(tree: value, owned: false, leaf_count: nil)
        end
      end

      def jsonable_array(array, depth:, seen:, parent_key:, leaf_counter: nil)
        owned = false
        result = nil

        array.each_with_index do |entry, index|
          child = jsonable_value(entry, depth: depth, seen: seen, parent_key: parent_key, leaf_counter: leaf_counter)
          next unless child.owned

          owned = true
          result ||= array.dup
          result[index] = child.tree
        end

        JsonableResult.new(tree: owned ? result : array, owned: owned, leaf_count: nil)
      end

      def process_jsonable_entry(key, value, depth:, seen:, parent_key:, omit_keys:, leaf_counter:)
        key_string = key.to_s
        if root_key_omitted?(depth, key_string, omit_keys)
          count_leaves_in_value(value, leaf_counter, depth: depth, seen: seen) if leaf_counter
          return
        end

        if Sanitizer::SENSITIVE_KEY_PATTERNS.match?(key_string)
          return [Sanitizer.sensitive_filtered_key_name(key_string), "[FILTERED]", true]
        end

        nested_parent = parent_key ? "#{parent_key}.#{key_string}" : key_string
        child = jsonable_value(
          value,
          depth: depth,
          seen: seen,
          parent_key: nested_parent,
          leaf_counter: leaf_counter
        )
        encoded_value = child.owned ? child.tree : value
        [key_string, encoded_value, child.owned]
      end

      def root_key_omitted?(depth, key_string, omit_keys)
        depth.zero? && omit_keys&.include?(key_string)
      end

      def omit_root_keys(hash, omit_keys, depth:)
        return hash unless depth.zero? && omit_keys&.any?

        hash.each_with_object({}) do |(key, value), object|
          object[key] = value unless omit_keys.include?(key.to_s)
        end
      end

      def count_leaves_in_value(value, leaf_counter, depth:, seen:)
        case value
        when Hash
          return unless seen.add?(value)

          value.each_value do |entry|
            count_leaves_in_value(entry, leaf_counter, depth: depth + 1, seen: seen)
          end
          seen.delete(value)
        when Array
          value.each { |entry| count_leaves_in_value(entry, leaf_counter, depth: depth, seen: seen) }
        else
          leaf_counter[0] += 1
        end
      end

      def stringify(hash)
        hash.each_with_object({}) do |(key, value), result|
          result[key.to_s] = stringify_value(value)
        end
      end

      def stringify_value(value)
        case value
        when Hash
          stringify(value)
        when Array
          value.map { |entry| stringify_value(entry) }
        when String
          Sanitizer.sanitize_string(value)
        else
          value
        end
      end

      def stringify_keys_copy(hash)
        return hash if hash.keys.all? { |key| key.is_a?(String) }

        hash.transform_keys(&:to_s)
      end
    end
  end
end
