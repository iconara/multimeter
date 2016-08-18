# encoding: utf-8

require 'metrics-core-jars'
require 'multimeter_metrics'
require 'json'

module Metrics
  include_package 'com.codahale.metrics'
end

module Multimeter
  class MetricRegistry
    def to_h
      h = {}
      metrics.each do |metric_name, metric|
        h[metric_name] = metric.to_h
      end
      h
    end
  end

  class Meter
    def to_h
      {
        :type => :meter,
        :count => count,
        :mean_rate => mean_rate,
        :one_minute_rate => one_minute_rate,
        :five_minute_rate => five_minute_rate,
        :fifteen_minute_rate => fifteen_minute_rate
      }
    end
  end

  class Counter
    def to_h
      {
        :type => :counter,
        :count => count
      }
    end
  end

  class Histogram
    def to_h
      {
        :type => :histogram,
        :count => count,
      }.merge(snapshot.to_h)
    end
  end

  class Timer
    def to_h
      {
        :type => :timer,
        :count => count,
        :mean_rate => mean_rate,
        :one_minute_rate => one_minute_rate,
        :five_minute_rate => five_minute_rate,
        :fifteen_minute_rate => fifteen_minute_rate,
      }.merge(snapshot.to_h(NANO_TO_MILLI_SCALE))
    end
  end

  class Snapshot
    def to_h(scale=1)
      {
        :max => max * scale,
        :min => min * scale,
        :mean => mean * scale,
        :std_dev => std_dev * scale,
        :median => median * scale,
        :percentiles => {
          '75' => p75 * scale,
          '95' => p95 * scale,
          '98' => p98 * scale,
          '99' => p99 * scale,
          '99.9' => p999 * scale,
        }
      }
    end
  end

  class Gauge
    def to_h
      {
        :type => :gauge,
        :value => value,
      }
    end
  end

  def self.create_registry
    MetricRegistry.new
  end

  def self.jmx(registry, options = {})
    Metrics::JmxReporter.forRegistry(registry.to_java).inDomain(options[:domain] || 'multimeter').build.tap(&:start)
  end

  def self.http(registry, rack_handler, options={})
    server_thread = Java::JavaLang::Thread.new do
      rack_handler.run(Http.create_app(registry), options)
    end
    server_thread.daemon = true
    server_thread.name = 'multimeter-http-server'
    server_thread.start
    server_thread
  end

  private

  NANO_TO_MILLI_SCALE = 1.0/1_000_000

  module Http
    class BadRequest < StandardError; end

    COMMON_HEADERS = {'Connection' => 'close'}.freeze
    JSON_HEADERS = COMMON_HEADERS.merge('Content-Type' => 'application/json').freeze
    JSONP_HEADERS = COMMON_HEADERS.merge('Content-Type' => 'application/javascript').freeze
    ERROR_HEADERS = COMMON_HEADERS.merge('Content-Type' => 'text/plain').freeze

    def self.create_app(registry)
      proc do |env|
        begin
          body = registry.to_h.to_json
          headers = JSON_HEADERS
          if (callback_name = env['QUERY_STRING'][/callback=([^$&]+)/, 1])
            if callback_name =~ /^[\w\d.]+$/
              body = "#{callback_name}(#{body});"
              headers = JSONP_HEADERS
            else
              raise BadRequest
            end
          else
            headers = headers.merge('Access-Control-Allow-Origin' => '*')
          end
          [200, headers, [body]]
        rescue BadRequest => e
          [400, ERROR_HEADERS, ['Bad Request']]
        rescue => e
          [500, ERROR_HEADERS, ["Internal Server Error\n\n", e.message, "\n\t", *e.backtrace.join("\n\t")]]
        end
      end
    end
  end
end
