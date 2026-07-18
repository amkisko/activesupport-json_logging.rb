module JsonLogging
  # Opt-in subscriber for ActiveSupport::EventReporter (Rails 8.1+).
  # Preserves the Rails event hash shape as a single JSON line.
  class EventSubscriber
    def initialize(logger: nil, io: nil)
      if !logger.nil? && !io.nil?
        raise ArgumentError, "JsonLogging::EventSubscriber accepts only one of logger: or io:"
      end
      if logger.nil? && io.nil?
        raise ArgumentError, "JsonLogging::EventSubscriber requires logger: or io:"
      end

      @logger = logger
      @io = io
    end

    def emit(event)
      line = begin
        encode_event(event)
      rescue => error
        encode_fallback(event, error)
      end

      write_line(line)
    rescue => error
      report_write_error(error)
      nil
    end

    private

    def encode_event(event)
      payload = {
        "name" => Helpers.safe_string(event_field(event, :name)),
        "payload" => serialize_payload(event_field(event, :payload)),
        "tags" => serialize_tags(event_field(event, :tags)),
        "context" => hash_or_empty(event_field(event, :context)),
        "timestamp" => event_field(event, :timestamp)
      }
      source_location = event_field(event, :source_location)
      payload["source_location"] = hash_or_empty(source_location) if source_location

      LineEncoder.to_json_line(Sanitizer.sanitize_hash(payload))
    end

    def encode_fallback(event, error)
      event_name = begin
        Helpers.safe_string(event && event_field(event, :name))
      rescue
        nil
      end

      LineEncoder.to_json_line(
        Sanitizer.sanitize_hash(
          {
            "name" => "json_logging.event_encode_error",
            "event_name" => event_name,
            "error" => {
              "class" => error.class.name,
              "message" => Helpers.safe_string(error.message)
            }
          }
        )
      )
    end

    def event_field(event, key)
      return nil unless event.is_a?(Hash)

      if event.key?(key)
        event[key]
      elsif event.key?(key.to_s)
        event[key.to_s]
      end
    end

    def serialize_payload(payload)
      case payload
      when Hash
        payload
      when nil
        {}
      else
        serialize_object(payload)
      end
    end

    def serialize_tags(tags)
      return {} unless tags.is_a?(Hash)

      tags.transform_values { |value| serialize_tag_value(value) }
    end

    def serialize_tag_value(value)
      case value
      when Hash, TrueClass, FalseClass, Numeric, NilClass, String
        value
      else
        serialize_object(value)
      end
    end

    def serialize_object(object)
      if object.respond_to?(:serialize)
        serialized = object.serialize
        serialized.is_a?(Hash) ? serialized : {"value" => serialized}
      elsif object.respond_to?(:to_h)
        object.to_h
      else
        {
          "class" => object.class.name,
          "value" => Helpers.safe_string(object)
        }
      end
    end

    def hash_or_empty(value)
      value.is_a?(Hash) ? value : {}
    end

    def write_line(line)
      if @io
        @io.write(line)
      else
        resolve_logger << line
      end
    end

    def resolve_logger
      logger = @logger
      # Proc responds to << (composition); Logger responds to add.
      return logger.call if logger.respond_to?(:call) && !logger.respond_to?(:add)

      logger
    end

    def report_write_error(error)
      return unless defined?(ActiveSupport) && ActiveSupport.respond_to?(:error_reporter)
      return if ActiveSupport.error_reporter.nil?

      ActiveSupport.error_reporter.report(error, handled: true, severity: :error)
    rescue
      nil
    end
  end
end
