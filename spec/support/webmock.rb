begin
  require "webmock/rspec"
  allowed_urls = []
  WebMock.disable_net_connect!(allow_localhost: true, allow: allowed_urls)
rescue LoadError
  warn "webmock not available; real HTTP connections are not blocked in this run"
end
