module JsonLogging
  # Some log transports limit each line (Heroku Logplex splits dyno output into
  # 10,000-byte chunks), which leaves every chunk as invalid JSON. The sanitizer
  # caps single strings, so a line made of many medium fields can still overflow.
  module LineCap
    OMISSION = "...[truncated]"
    # Bounds the work spent on a line with many short strings; such a line is
    # replaced by an overflow notice instead.
    MAX_SHRINK_PASSES = 24

    module_function

    def apply(line)
      max_bytes = JsonLogging.max_line_bytes
      return line if max_bytes.nil? || line.bytesize <= max_bytes

      body = line.chomp
      return line if body.bytesize <= max_bytes

      "#{shrink(JSON.parse(body), max_bytes)}\n"
    end

    def shrink(payload, max_bytes)
      payload["truncated"] = true

      MAX_SHRINK_PASSES.times do
        encoded = JSON.generate(payload)
        return encoded if encoded.bytesize <= max_bytes

        string, parent, key = longest_string(payload)
        break if string.nil? || string.bytesize <= OMISSION.bytesize

        kept_bytes = string.bytesize - (encoded.bytesize - max_bytes) - OMISSION.bytesize
        parent[key] = (kept_bytes < 1) ? OMISSION : "#{string.byteslice(0, kept_bytes).scrub("")}#{OMISSION}"
      end

      encoded = JSON.generate(payload)
      (encoded.bytesize <= max_bytes) ? encoded : overflow_notice(payload, max_bytes)
    end

    def longest_string(object, parent = nil, key = nil)
      case object
      when String
        [object, parent, key] if parent
      when Hash
        longest_of(object.map { |child_key, value| longest_string(value, object, child_key) })
      when Array
        longest_of(object.each_with_index.map { |value, index| longest_string(value, object, index) })
      end
    end

    def longest_of(candidates)
      candidates.compact.max_by { |string, _parent, _key| string.bytesize }
    end

    def overflow_notice(payload, max_bytes)
      JSON.generate(
        {
          "severity" => payload["severity"],
          "timestamp" => payload["timestamp"],
          "truncated" => true,
          "message" => "log line exceeded #{max_bytes} bytes"
        }.compact
      )
    end
  end
end
