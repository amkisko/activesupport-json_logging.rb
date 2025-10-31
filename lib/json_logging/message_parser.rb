module JsonLogging
  module MessageParser
    module_function

    def parse_message(msg)
      if msg.is_a?(Hash) || (msg.respond_to?(:to_hash) && !msg.is_a?(String))
        # Sanitize hash messages
        Sanitizer.sanitize_hash(msg.to_hash)
      elsif msg.is_a?(String) && json_string?(msg)
        begin
          parsed = JSON.parse(msg)
          # Sanitize parsed JSON structure
          Sanitizer.sanitize_value(parsed)
        rescue JSON::ParserError
          # If JSON parsing fails, sanitize the raw string
          Sanitizer.sanitize_string(msg)
        end
      elsif msg.is_a?(Exception)
        # Handle exceptions specially with sanitization
        Sanitizer.sanitize_exception(msg)
      else
        # Sanitize other types
        Sanitizer.sanitize_value(msg)
      end
    end

    def json_string?(str)
      (str.start_with?("{") && str.end_with?("}")) ||
        (str.start_with?("[") && str.end_with?("]"))
    end
  end
end
