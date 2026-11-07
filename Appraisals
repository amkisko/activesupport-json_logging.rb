appraise "rails72" do
  gem "activesupport", "~> 7.2", ">= 7.2.3.2"
  gem "railties", "~> 7.2", ">= 7.2.3.2"
  # polyrun >= 2.2.9 requires Ruby >= 3.4; keep rails72 on 3.4 in CI
  gem "parallel", "< 2"
end

appraise "rails8ruby34" do
  ruby ">= 3.4.0"
  gem "activesupport", "~> 8.1", ">= 8.1.3.1"
  gem "railties", "~> 8.1", ">= 8.1.3.1"
end

appraise "rails8ruby4" do
  ruby ">= 4.0.0"
  gem "activesupport", "~> 8.1", ">= 8.1.3.1"
  gem "railties", "~> 8.1", ">= 8.1.3.1"
end

appraise "rails8truffleruby" do
  # Use TruffleRuby engine in CI/environment; the ruby directive helps bundler select engine
  ruby ">= 3.2.0"
  gem "activesupport", "~> 8.1", ">= 8.1.3.1"
  gem "railties", "~> 8.1", ">= 8.1.3.1"
end
