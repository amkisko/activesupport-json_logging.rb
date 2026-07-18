require "spec_helper"
require "stringio"

RSpec.describe "JsonLogging::EventSubscriber" do
  before do
    skip "ActiveSupport::EventReporter requires Rails 8.1+" unless defined?(ActiveSupport::EventReporter)
  end

  let(:io) { StringIO.new }
  let(:logger) { JsonLogging.logger(io) }
  let(:subscriber) { JsonLogging::EventSubscriber.new(logger: logger) }

  def last_payload(from_io = io)
    from_io.rewind
    line = from_io.gets
    expect(line).not_to be_nil
    JSON.parse(line)
  end

  describe "#initialize" do
    it "requires logger: or io:" do
      expect {
        JsonLogging::EventSubscriber.new
      }.to raise_error(ArgumentError, /logger: or io:/)
    end

    it "rejects logger: and io: together" do
      expect {
        JsonLogging::EventSubscriber.new(logger: logger, io: StringIO.new)
      }.to raise_error(ArgumentError, /only one of logger: or io:/)
    end
  end

  describe "#emit" do
    it "writes a single JSON line preserving Rails event fields", :aggregate_failures do
      subscriber.emit(
        name: "user.signup",
        payload: {user_id: 123, email: "user@example.com"},
        tags: {graphql: true},
        context: {request_id: "abc123"},
        timestamp: 1_738_964_843_208_679_035,
        source_location: {filepath: "app/models/user.rb", lineno: 10, label: "User#create"}
      )

      payload = last_payload
      expect(payload["name"]).to eq("user.signup")
      expect(payload["payload"]).to eq("user_id" => 123, "email" => "user@example.com")
      expect(payload["tags"]).to eq("graphql" => true)
      expect(payload["context"]).to eq("request_id" => "abc123")
      expect(payload["timestamp"]).to eq(1_738_964_843_208_679_035)
      expect(payload["source_location"]).to include(
        "filepath" => "app/models/user.rb",
        "lineno" => 10,
        "label" => "User#create"
      )
      expect(payload).not_to have_key("severity")
    end

    it "reads string-keyed event hashes", :aggregate_failures do
      subscriber.emit(
        "name" => "string.keys",
        "payload" => {"ok" => true},
        "tags" => {"area" => "api"},
        "context" => {"request_id" => "r1"},
        "timestamp" => 9,
        "source_location" => {"filepath" => "a.rb", "lineno" => 1, "label" => "x"}
      )

      payload = last_payload
      expect(payload["name"]).to eq("string.keys")
      expect(payload["payload"]).to eq("ok" => true)
      expect(payload["tags"]).to eq("area" => "api")
      expect(payload["context"]).to eq("request_id" => "r1")
      expect(payload["timestamp"]).to eq(9)
      expect(payload["source_location"]).to include("filepath" => "a.rb", "lineno" => 1)
    end

    it "serializes event objects that implement #serialize", :aggregate_failures do
      event_object = Class.new do
        def initialize(id:)
          @id = id
        end

        def serialize
          {id: @id}
        end
      end.new(id: 42)

      subscriber.emit(
        name: "UserCreatedEvent",
        payload: event_object,
        tags: {},
        context: {},
        timestamp: 1
      )

      payload = last_payload
      expect(payload["name"]).to eq("UserCreatedEvent")
      expect(payload["payload"]).to eq("id" => 42)
    end

    it "serializes tag objects that implement #serialize", :aggregate_failures do
      tag_object = Class.new do
        def serialize
          {operation: "signup"}
        end
      end.new

      subscriber.emit(
        name: "tagged.event",
        payload: {id: 1},
        tags: {GraphqlTag: tag_object},
        context: {},
        timestamp: 1
      )

      payload = last_payload
      expect(payload["tags"]).to eq("GraphqlTag" => {"operation" => "signup"})
    end

    it "never raises when encoding fails and still writes a fallback line", :aggregate_failures do
      broken_payload = Object.new
      def broken_payload.serialize
        raise "boom"
      end

      expect {
        subscriber.emit(
          name: "broken.event",
          payload: broken_payload,
          tags: {},
          context: {},
          timestamp: 1
        )
      }.not_to raise_error

      payload = last_payload
      expect(payload["name"]).to eq("json_logging.event_encode_error")
      expect(payload["event_name"]).to eq("broken.event")
      expect(payload["error"]).to include("class" => "RuntimeError")
    end

    it "never raises when the destination write fails", :aggregate_failures do
      failing_io = Object.new
      def failing_io.write(*)
        raise IOError, "disk full"
      end

      failing_subscriber = JsonLogging::EventSubscriber.new(io: failing_io)
      expect {
        failing_subscriber.emit(
          name: "write.fail",
          payload: {ok: true},
          tags: {},
          context: {},
          timestamp: 1
        )
      }.not_to raise_error
    end

    it "writes through an IO destination without a logger", :aggregate_failures do
      io_only = StringIO.new
      io_subscriber = JsonLogging::EventSubscriber.new(io: io_only)
      io_subscriber.emit(
        name: "direct.io",
        payload: {ok: true},
        tags: {},
        context: {},
        timestamp: 2
      )

      payload = last_payload(io_only)
      expect(payload["name"]).to eq("direct.io")
      expect(payload["payload"]).to eq("ok" => true)
    end

    it "resolves a callable logger on each emit", :aggregate_failures do
      first_io = StringIO.new
      second_io = StringIO.new
      current = JsonLogging.logger(first_io)
      lazy_subscriber = JsonLogging::EventSubscriber.new(logger: -> { current })

      lazy_subscriber.emit(name: "first", payload: {}, tags: {}, context: {}, timestamp: 1)
      current = JsonLogging.logger(second_io)
      lazy_subscriber.emit(name: "second", payload: {}, tags: {}, context: {}, timestamp: 2)

      expect(last_payload(first_io)["name"]).to eq("first")
      expect(last_payload(second_io)["name"]).to eq("second")
    end

    it "fans out through BroadcastLogger when available", :aggregate_failures do
      skip "BroadcastLogger requires Rails 7.1+" unless defined?(ActiveSupport::BroadcastLogger)

      primary_io = StringIO.new
      secondary_io = StringIO.new
      broadcast = ActiveSupport::BroadcastLogger.new(JsonLogging.logger(primary_io))
      broadcast.broadcast_to(JsonLogging.logger(secondary_io))

      JsonLogging::EventSubscriber.new(logger: broadcast).emit(
        name: "broadcast.event",
        payload: {n: 1},
        tags: {},
        context: {},
        timestamp: 1
      )

      expect(last_payload(primary_io)["name"]).to eq("broadcast.event")
      expect(last_payload(secondary_io)["name"]).to eq("broadcast.event")
    end
  end

  describe "ActiveSupport::EventReporter integration" do
    it "receives notified events from Rails.event-compatible reporter", :aggregate_failures do
      reporter = ActiveSupport::EventReporter.new
      reporter.subscribe(subscriber)

      reporter.notify("order.paid", order_id: 9, amount_cents: 500)

      payload = last_payload
      expect(payload["name"]).to eq("order.paid")
      expect(payload["payload"]).to include("order_id" => 9, "amount_cents" => 500)
      expect(payload["tags"]).to eq({})
      expect(payload["context"]).to eq({})
      expect(payload["timestamp"]).to be_a(Integer)
      expect(payload["source_location"]).to be_a(Hash)
    end

    it "includes tags and context from the reporter", :aggregate_failures do
      reporter = ActiveSupport::EventReporter.new
      reporter.subscribe(subscriber)

      reporter.set_context(request_id: "req-1")
      reporter.tagged("billing") do
        reporter.notify("invoice.created", invoice_id: 3)
      end

      payload = last_payload
      expect(payload["name"]).to eq("invoice.created")
      expect(payload["tags"]).to eq("billing" => true)
      expect(payload["context"]).to eq("request_id" => "req-1")
    ensure
      reporter.clear_context
    end
  end
end
