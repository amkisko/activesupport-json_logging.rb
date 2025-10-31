require "json_logging"

module JsonLogging
  class Railtie < ::Rails::Railtie
    # This Railtie ensures json_logging is automatically required when Rails loads
    # Without this, users would need to manually require "json_logging" in initializers
  end
end
