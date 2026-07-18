require "json_logging"

module JsonLogging
  class Railtie < ::Rails::Railtie
    config.json_logging = ActiveSupport::OrderedOptions.new
    config.json_logging.subscribe_event_reporter = false

    # This Railtie ensures json_logging is automatically required when Rails loads
    # Without this, users would need to manually require "json_logging" in initializers

    initializer "json_logging.subscribe_event_reporter", after: :load_config_initializers do |app|
      next unless app.config.json_logging.subscribe_event_reporter
      next unless defined?(ActiveSupport::EventReporter)
      next unless Rails.respond_to?(:event)

      Rails.event.subscribe(JsonLogging::EventSubscriber.new(logger: -> { Rails.logger }))
    end
  end
end
