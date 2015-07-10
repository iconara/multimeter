# encoding: utf-8

require 'metrics-json-jars'

module Metrics
  module Json
    include_package 'com.codahale.metrics.json'
  end
end

module Jackson
  module Databind
    include_package 'com.fasterxml.jackson.databind'
  end
end

module Multimeter
  module Rack
    class BadRequest < StandardError; end

    COMMON_HEADERS = {'Connection' => 'close'}.freeze
    JSON_HEADERS = COMMON_HEADERS.merge('Content-Type' => 'application/json', 'Access-Control-Allow-Origin' => '*').freeze
    JSONP_HEADERS = COMMON_HEADERS.merge('Content-Type' => 'application/javascript').freeze
    ERROR_HEADERS = COMMON_HEADERS.merge('Content-Type' => 'text/plain').freeze

    class App
      def initialize(registry)
        @registry = registry
        @object_mapper = Jackson::Databind::ObjectMapper.new
      end

      def setup
        metrics_module = Metrics::Json::MetricsModule.new(rate_unit = Java::JavaUtilConcurrent::TimeUnit::SECONDS, duration_unit = Java::JavaUtilConcurrent::TimeUnit::MILLISECONDS, show_samples = false)
        @object_mapper.register_module(metrics_module)
        self
      end

      def call(env)
        if (callback_name = env['QUERY_STRING'][/callback=([^$&]+)/, 1])
          if callback_name =~ /^[\w\d.]+$/
            body = "#{callback_name}(#{generate_json});"
            headers = JSONP_HEADERS
          else
            raise BadRequest
          end
        else
          headers = JSON_HEADERS
          body = generate_json
        end
        [200, headers, [body]]
      rescue BadRequest => e
        [400, ERROR_HEADERS, ['Bad Request']]
      rescue => e
        [500, ERROR_HEADERS, ["Internal Server Error\n\n", e.message, "\n\t", *e.backtrace.join("\n\t")]]
      end

      private

      def generate_json
        stream = Java::JavaIo::ByteArrayOutputStream.new
        @object_mapper.write_value(stream, @registry.to_java)
        String.from_java_bytes(stream.to_byte_array)
      end
    end

    def create_app(registry)
      App.new(registry).setup
    end
  end
end