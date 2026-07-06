module JsonLogging
  module Severity
    NAMES = {
      ::Logger::DEBUG => "DEBUG",
      ::Logger::INFO => "INFO",
      ::Logger::WARN => "WARN",
      ::Logger::ERROR => "ERROR",
      ::Logger::FATAL => "FATAL",
      ::Logger::UNKNOWN => "UNKNOWN"
    }.freeze

    module_function

    def name_for(severity)
      NAMES[severity] || severity.to_s
    end
  end
end
