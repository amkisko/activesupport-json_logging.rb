require "active_support"
require "active_support/logger"

module JsonLogging
  class JsonLogger < ActiveSupport::Logger
    # Include the extension module to get all JSON logging functionality
    include JsonLoggerExtension

    def initialize(*args, **kwargs)
      # Initialize with minimal args to avoid ActiveSupport::Logger threading issues
      logdev = args.first || $stdout
      shift_age = args[1] || 0
      shift_size = args[2]

      # Handle both positional and keyword arguments for Rails 7–8 compatibility
      if kwargs.empty? && shift_size
        super(logdev, shift_age, shift_size)
      elsif kwargs.empty?
        super(logdev, shift_age)
      else
        super
      end

      @formatter_with_tags = FormatterWithTags.new(self)
      # Ensure parent class (Logger) also uses our formatter in case it uses it directly
      instance_variable_set(:@formatter, @formatter_with_tags)
    end
  end
end
