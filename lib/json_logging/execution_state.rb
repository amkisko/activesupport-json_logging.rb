# frozen_string_literal: true

module JsonLogging
  # Storage for request-scoped logging state (context, tags, hot-path caches).
  #
  # Default +:thread+ follows ActiveSupport::IsolatedExecutionState when present
  # (Rails 7.1+), otherwise Thread.current.
  #
  # Experimental +:fiber+ stores JsonLogging keys on the current Fiber so concurrent
  # Fibers on one Thread do not share context or tags. Does not change Rails'
  # ActiveSupport::IsolatedExecutionState.isolation_level; Falcon-style apps should
  # still set config.active_support.isolation_level = :fiber for the rest of Rails.
  module ExecutionState
    PREPARED_TAGS_CACHE_KEY = :__json_logging_prepared_tags

    module_function

    def [](key)
      backend[key]
    end

    def []=(key, value)
      backend[key] = value
    end

    def delete(key)
      backend.delete(key)
    end

    def key?(key)
      backend.key?(key)
    end

    def prepared_tags_cache
      self[PREPARED_TAGS_CACHE_KEY] ||= {}
    end

    def backend
      if JsonLogging.isolation_level == :fiber
        fiber_backend
      else
        thread_backend
      end
    end

    def fiber_backend
      state = Fiber.current.json_logging_execution_state
      unless state
        state = {}
        Fiber.current.json_logging_execution_state = state
      end
      state
    end

    def thread_backend
      if defined?(ActiveSupport::IsolatedExecutionState)
        ActiveSupport::IsolatedExecutionState
      else
        Thread.current
      end
    end
  end
end

Fiber.attr_accessor :json_logging_execution_state unless Fiber.method_defined?(:json_logging_execution_state)
