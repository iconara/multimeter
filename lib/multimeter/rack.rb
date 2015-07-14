# encoding: utf-8

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
      end

      def call(env)
        if (callback_name = env['QUERY_STRING'][/callback=([^$&]+)/, 1])
          if callback_name =~ /^[\w\d.]+$/
            body = "#{callback_name}(#{@registry.to_json});"
            headers = JSONP_HEADERS
          else
            raise BadRequest
          end
        else
          headers = JSON_HEADERS
          body = @registry.to_json
        end
        [200, headers, [body]]
      rescue BadRequest => e
        [400, ERROR_HEADERS, ['Bad Request']]
      rescue => e
        [500, ERROR_HEADERS, ["Internal Server Error\n\n", e.message, "\n\t", *e.backtrace.join("\n\t")]]
      end
    end

    def create_app(registry)
      App.new(registry)
    end
  end
end
