require "spec_helper"
require "stringio"

RSpec.describe JsonLogging do
  describe JsonLogging::Sanitizer do
    describe ".sanitize_string" do
      it "returns the same string object for clean ASCII text", :aggregate_failures do
        message = "request completed"
        result = described_class.sanitize_string(message)
        expect(result).to eq(message)
        expect(result).to be(message)
      end

      it "still strips control characters when present" do
        result = described_class.sanitize_string("hello\x00world")
        expect(result).to eq("helloworld")
      end
    end

    describe ".sanitize_hash" do
      it "stringifies primitive hashes without deep copying nested structures", :aggregate_failures do
        hash = {"event" => "test", "value" => 42, "active" => true}
        result = described_class.sanitize_hash(hash)

        expect(result).to eq(hash)
      end

      it "still filters sensitive keys on primitive hashes", :aggregate_failures do
        result = described_class.sanitize_hash({"password" => "secret", "event" => "login"})

        expect(result).to include("password_filtered" => "[FILTERED]", "event" => "login")
        expect(result).not_to have_key("password")
      end

      it "still deep-sanitizes nested structures" do
        nested = {"user" => {"email" => "test@example.com"}}
        result = described_class.sanitize_hash(nested)

        expect(result).to eq("user" => {"email" => "test@example.com"})
      end

      it "sanitizes one-level nested primitive hashes without a deep copy", :aggregate_failures do
        nested = {
          "event" => "login",
          "user" => {"id" => 42, "email" => "test@example.com"}
        }

        result = described_class.sanitize_hash(nested)

        expect(result).to eq(nested)
      end

      it "sanitizes deeply nested primitive structures without a deep copy", :aggregate_failures do
        nested = {
          "user" => {
            "id" => 123,
            "profile" => {
              "name" => "Test User",
              "preferences" => {"theme" => "dark", "language" => "en"}
            }
          },
          "request" => {"path" => "/api/users"}
        }

        result = described_class.sanitize_hash(nested)

        expect(result).to eq(nested)
      end

      it "does not mutate the source hash when the sanitized result is updated", :aggregate_failures do
        source = {
          "user" => {
            "id" => 123,
            "profile" => {"name" => "Test User"}
          }
        }

        result = described_class.sanitize_hash(source)
        result["severity"] = "INFO"

        expect(source).not_to have_key("severity")
        expect(result["severity"]).to eq("INFO")
      end
    end

    describe JsonLogging::StructuredHashJsonEncoder do
      let(:timestamp) { "2026-01-01T00:00:00.000000Z" }

      after do
        JsonLogging::Sanitizer.reset_rails_parameter_filter_cache!
      end

      def stub_rails_filter_parameters(filter_parameters)
        rails_module = Module.new
        rails_application = double("application")
        rails_configuration = double("configuration", filter_parameters: filter_parameters)

        allow(rails_application).to receive(:config).and_return(rails_configuration)
        stub_const("Rails", rails_module)
        allow(Rails).to receive(:respond_to?).with(:application).and_return(true)
        allow(Rails).to receive(:application).and_return(rails_application)
      end

      def benchmark_large_hash
        {
          user: {
            id: 123,
            email: "test@example.com",
            profile: {
              name: "Test User",
              bio: "A" * 1000,
              preferences: (1..50).map { |index| ["pref_#{index}", "value_#{index}"] }.to_h
            }
          },
          request: {
            path: "/api/users",
            params: (1..20).map { |index| ["param_#{index}", "value_#{index}"] }.to_h
          }
        }
      end

      it "encodes structured hashes in one pass with the same JSON as sanitize_hash", :aggregate_failures do
        hash = benchmark_large_hash
        expect(described_class.eligible?(hash)).to be(true)
        expect(JsonLogging::Sanitizer::StructuredHash.jsonable_tree(hash).owned).to be(false)

        sanitized = JsonLogging::Sanitizer.sanitize_hash(hash.dup)
        sanitized["severity"] = "INFO"
        sanitized["timestamp"] = timestamp
        expected_line = "#{JSON.generate(sanitized)}\n"

        line = described_class.encode_line(hash, severity: "INFO", timestamp: timestamp)

        expect(line).to eq(expected_line)
        expect(JSON.parse(line)).to eq(JSON.parse(expected_line))
      end

      it "filters sensitive keys while encoding", :aggregate_failures do
        hash = {"event" => "login", "password" => "secret"}
        line = described_class.encode_line(hash, severity: "INFO", timestamp: timestamp)
        payload = JSON.parse(line)

        expect(payload).to include("password_filtered" => "[FILTERED]", "event" => "login")
        expect(payload).not_to have_key("password")
      end

      it "keeps flat primitive hashes on the copy path", :aggregate_failures do
        hash = {"event" => "login", "value" => 42}
        expect(described_class.eligible?(hash)).to be(false)
      end

      it "defers to the copy path when Rails uses deep parameter filters", :aggregate_failures do
        skip "ActiveSupport::ParameterFilter not available" unless defined?(ActiveSupport::ParameterFilter)

        stub_rails_filter_parameters(["credit_card.code"])
        JsonLogging::Sanitizer.reset_rails_parameter_filter_cache!

        hash = {"credit_card" => {"code" => "secret", "number" => "4111"}}
        expect(JsonLogging::Sanitizer.rails_parameter_filter_requires_full_tree_walk?).to be(true)
        expect(described_class.eligible?(hash)).to be(false)
      end

      it "keeps the encoder path for shallow Rails parameter filters", :aggregate_failures do
        skip "ActiveSupport::ParameterFilter not available" unless defined?(ActiveSupport::ParameterFilter)

        stub_rails_filter_parameters([:password])
        JsonLogging::Sanitizer.reset_rails_parameter_filter_cache!

        expect(JsonLogging::Sanitizer.rails_parameter_filter_requires_full_tree_walk?).to be(false)
        expect(described_class.eligible?(benchmark_large_hash)).to be(true)
      end

      it "omits overridden tags from the encoded body when merging logger tags", :aggregate_failures do
        hash = benchmark_large_hash.merge(tags: ["OLD"])

        line = JsonLogging::LineEncoder.build_line(
          msg: hash,
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: ["NEW"],
          additional_context: {},
          sanitize_tags: false
        )

        payload = JSON.parse(line)
        expect(payload["tags"]).to eq(["OLD", "NEW"])
        expect(line.scan('"tags"').size).to eq(1)
      end

      it "omits overridden context from the encoded body when merging logger context", :aggregate_failures do
        hash = benchmark_large_hash.merge(context: {"request_id" => "old"})

        line = JsonLogging::LineEncoder.build_line(
          msg: hash,
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: [],
          additional_context: {"user_id" => 42},
          additional_context_sanitized: true
        )

        payload = JSON.parse(line)
        expect(payload["context"]).to eq("request_id" => "old", "user_id" => 42)
        expect(line.scan('"context"').size).to eq(1)
      end
    end

    describe ".rails_parameter_filter" do
      it "reuses the same filter instance for unchanged filter_parameters", :aggregate_failures do
        skip "ActiveSupport::ParameterFilter not available" unless defined?(ActiveSupport::ParameterFilter)

        filter_parameters = [:password]
        rails_module = Module.new
        rails_application = double("application")
        rails_configuration = double("configuration", filter_parameters: filter_parameters)

        allow(rails_application).to receive(:config).and_return(rails_configuration)
        stub_const("Rails", rails_module)
        allow(Rails).to receive(:respond_to?).with(:application).and_return(true)
        allow(Rails).to receive(:application).and_return(rails_application)

        described_class.reset_rails_parameter_filter_cache!

        first_filter = described_class.rails_parameter_filter
        second_filter = described_class.rails_parameter_filter

        expect(first_filter).to be_a(ActiveSupport::ParameterFilter)
        expect(second_filter).to equal(first_filter)
      end
    end
  end

  describe "additional context caching" do
    after do
      described_class.send(:context_storage)[described_class::THREAD_CONTEXT_KEY] = nil
      described_class.send(:context_storage)[described_class::SANITIZED_CONTEXT_CACHE_KEY] = nil
      described_class.additional_context = nil
      JsonLogging::Sanitizer.reset_rails_parameter_filter_cache!
    end

    describe ".additional_context_for_payload" do
      it "sanitizes context once per with_context scope across multiple log lines", :aggregate_failures do
        io = StringIO.new
        logger = described_class::JsonLogger.new(io)
        sanitize_calls = 0

        allow(JsonLogging::Sanitizer).to receive(:sanitize_hash).and_wrap_original do |original, *args, **kwargs|
          sanitize_calls += 1
          original.call(*args, **kwargs)
        end

        described_class.with_context(user_id: 42, password: "secret") do
          logger.info("first")
          logger.info("second")
        end

        expect(sanitize_calls).to eq(1)

        io.rewind
        lines = io.readlines
        expect(lines.length).to eq(2)
        lines.each do |line|
          payload = JSON.parse(line)
          expect(payload.dig("context", "user_id")).to eq(42)
          expect(payload.dig("context", "password_filtered")).to eq("[FILTERED]")
        end
      end

      it "re-sanitizes when a transformer is configured", :aggregate_failures do
        io = StringIO.new
        logger = described_class::JsonLogger.new(io)
        counter = 0

        described_class.additional_context = lambda do |context|
          counter += 1
          context.merge(sequence: counter)
        end

        described_class.with_context(user_id: 1) do
          logger.info("first")
          logger.info("second")
        end

        io.rewind
        payloads = io.readlines.map { |line| JSON.parse(line) }
        expect(payloads.map { |payload| payload.dig("context", "sequence") }).to eq([1, 2])
      end
    end
  end

  describe JsonLogging::JsonLogger do
    describe "tag sanitization at push time" do
      it "strips control characters from tags before they reach the payload", :aggregate_failures do
        io = StringIO.new
        logger = described_class.new(io)

        logger.tagged("REQUEST\x00ID") do
          logger.info("done")
        end

        io.rewind
        payload = JSON.parse(io.gets)
        expect(payload["tags"]).to eq(["REQUESTID"])
      end
    end
  end

  describe JsonLogging::Helpers do
    describe ".normalize_timestamp" do
      it "returns an already normalized UTC timestamp string unchanged" do
        timestamp = "2026-01-01T00:00:00.000000Z"

        expect(described_class.normalize_timestamp(timestamp)).to equal(timestamp)
      end

      it "formats the current time in one call", :aggregate_failures do
        result = described_class.current_timestamp

        expect(result).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}Z\z/)
      end
    end
  end

  describe JsonLogging::PayloadBuilder do
    describe ".merge_context" do
      it "returns the payload unchanged when tags and additional context are empty" do
        payload = {"event" => "test", "value" => 1}

        result = described_class.merge_context(
          payload,
          additional_context: {},
          tags: []
        )

        expect(result).to equal(payload)
      end
    end
  end

  describe JsonLogging::LineEncoder do
    describe ".build_line" do
      let(:timestamp) { "2026-01-01T00:00:00.000000Z" }

      it "emits message, severity, and timestamp for simple string messages", :aggregate_failures do
        line = described_class.build_line(
          msg: "request completed",
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: [],
          additional_context: {}
        )

        expect(JSON.parse(line)).to eq(
          "message" => "request completed",
          "severity" => "INFO",
          "timestamp" => timestamp
        )
      end

      it "still includes context when additional context is present", :aggregate_failures do
        line = described_class.build_line(
          msg: "request completed",
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: [],
          additional_context: {"user_id" => 42},
          additional_context_sanitized: true
        )

        payload = JSON.parse(line)
        expect(payload["message"]).to eq("request completed")
        expect(payload.dig("context", "user_id")).to eq(42)
      end

      it "still includes tags when tags are present", :aggregate_failures do
        line = described_class.build_line(
          msg: "request completed",
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: ["REQUEST"],
          additional_context: {},
          sanitize_tags: false
        )

        payload = JSON.parse(line)
        expect(payload["tags"]).to eq(["REQUEST"])
      end

      it "emits primitive hash messages without tags or context", :aggregate_failures do
        line = described_class.build_line(
          msg: {event: "test", value: 42},
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: [],
          additional_context: {}
        )

        expect(JSON.parse(line)).to eq(
          "event" => "test",
          "value" => 42,
          "severity" => "INFO",
          "timestamp" => timestamp
        )
      end

      it "emits tagged simple string messages", :aggregate_failures do
        line = described_class.build_line(
          msg: "request completed",
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: ["REQUEST"],
          additional_context: {},
          sanitize_tags: false
        )

        expect(JSON.parse(line)).to eq(
          "message" => "request completed",
          "severity" => "INFO",
          "timestamp" => timestamp,
          "tags" => ["REQUEST"]
        )
      end

      it "emits simple string messages with sanitized context", :aggregate_failures do
        line = described_class.build_line(
          msg: "request completed",
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: [],
          additional_context: {"user_id" => 42},
          additional_context_sanitized: true
        )

        expect(JSON.parse(line)).to eq(
          "message" => "request completed",
          "severity" => "INFO",
          "timestamp" => timestamp,
          "context" => {"user_id" => 42}
        )
      end

      it "emits tagged primitive hash messages", :aggregate_failures do
        line = described_class.build_line(
          msg: {event: "test", value: 42},
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: ["REQUEST"],
          additional_context: {},
          sanitize_tags: false
        )

        expect(JSON.parse(line)).to eq(
          "event" => "test",
          "value" => 42,
          "severity" => "INFO",
          "timestamp" => timestamp,
          "tags" => ["REQUEST"]
        )
      end

      it "emits primitive hash messages with sanitized context", :aggregate_failures do
        line = described_class.build_line(
          msg: {event: "test", value: 42},
          severity: Logger::INFO,
          timestamp: timestamp,
          tags: [],
          additional_context: {"user_id" => 7},
          additional_context_sanitized: true
        )

        expect(JSON.parse(line)).to eq(
          "event" => "test",
          "value" => 42,
          "severity" => "INFO",
          "timestamp" => timestamp,
          "context" => {"user_id" => 7}
        )
      end
    end

    describe ".to_json_line" do
      it "skips deep_stringify_keys when payload already uses string keys", :aggregate_failures do
        payload = {"message" => "hello", "context" => {"user_id" => 1}}
        allow(payload).to receive(:deep_stringify_keys).and_call_original

        line = described_class.to_json_line(payload)

        expect(payload).not_to have_received(:deep_stringify_keys)
        expect(JSON.parse(line)).to eq(payload)
      end

      it "still stringifies symbol keys when present", :aggregate_failures do
        line = described_class.to_json_line({message: "hello"})
        expect(JSON.parse(line)).to eq("message" => "hello")
      end
    end
  end
end
