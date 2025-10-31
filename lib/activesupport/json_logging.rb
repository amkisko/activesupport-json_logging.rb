# Auto-require file for activesupport-json_logging gem
# This file is automatically loaded by Bundler when the gem is required
require "json_logging"

# Ensure Railtie is loaded so Rails auto-discovers it
require "activesupport/json_logging/railtie" if defined?(Rails)

