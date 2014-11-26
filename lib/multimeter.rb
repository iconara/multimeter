# encoding: utf-8

require 'metrics-core-jars'
require 'json'


module Multimeter
  module Metrics
    include_package 'com.codahale.metrics'

    java_import 'com.codahale.metrics.MetricRegistry'
    java_import 'com.codahale.metrics.Meter'
    java_import 'com.codahale.metrics.Counter'
    java_import 'com.codahale.metrics.Histogram'
    java_import 'com.codahale.metrics.Gauge'
    java_import 'com.codahale.metrics.Timer'
    java_import 'com.codahale.metrics.Snapshot'

    class MetricRegistry
      def gauge(name, &proc)
        error_translation do
          register(name, ProcGauge.new(proc))
        end
      end

      alias java_counter counter
      def counter(name)
        error_translation do
          java_counter(name)
        end
      end

      alias java_meter meter
      def meter(name)
        error_translation do
          java_meter(name)
        end
      end

      alias java_histogram histogram
      def histogram(name)
        error_translation do
          java_histogram(name)
        end
      end

      alias java_timer timer
      def timer(name)
        error_translation do
          java_timer(name)
        end
      end

      def to_h
        h = {}
        metrics.each do |metric_name, metric|
          h[metric_name] = metric.to_h
        end
        h
      end

      private

      def error_translation
        begin
          yield
        rescue Java::JavaLang::IllegalArgumentException => iae
          raise ArgumentError, iae.message, iae.backtrace
        end
      end
    end

    class Meter
      def type
        :meter
      end

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
      def type
        :counter
      end

      def to_h
        {
          :type => :counter,
          :count => count
        }
      end
    end

    class Histogram
      def type
        :histogram
      end

      def to_h
        {
          :type => :histogram,
          :count => count,
        }.merge(snapshot.to_h(NANO_TO_MILLI))
      end
    end

    module Gauge
      def type
        :gauge
      end

      def to_h
        {
          :type => :gauge,
          :value => value
        }
      end
    end

    class Timer
      def type
        :timer
      end

      def to_h
        {
          :type => :timer,
          :count => count,
          :mean_rate => mean_rate,
          :one_minute_rate => one_minute_rate,
          :five_minute_rate => five_minute_rate,
          :fifteen_minute_rate => fifteen_minute_rate,
        }.merge(snapshot.to_h(NANO_TO_MILLI))
      end

      def measure
        ctx = self.time
        begin
          yield
        ensure
          ctx.stop
        end
      end
    end

    class Snapshot
      def to_h(scale = 1)
        {
          :max => max * scale,
          :min => min * scale,
          :mean => mean * scale,
          :std_dev => std_dev * scale,
          :median => median * scale,
          :percentiles => {
            '75' => get75thPercentile * scale,
            '95' => get95thPercentile * scale,
            '98' => get98thPercentile * scale,
            '99' => get99thPercentile * scale,
            '99.9' => get999thPercentile * scale,
          }
        }
      end
    end

    private

    NANO_TO_MILLI = 1.0/1_000_000
  end

  def self.create_registry
    Metrics::MetricRegistry.new
  end

  def self.jmx!(registry, options = {})
    Metrics::JmxReporter.forRegistry(registry).inDomain(options[:domain] || 'metrics').build.tap(&:start)
  end

  def self.http!(registry, rack_handler, options={})
    server_thread = Java::JavaLang::Thread.new do
      rack_handler.run(Http.create_app(registry), options)
    end
    server_thread.daemon = true
    server_thread.name = 'multimeter-http-server'
    server_thread.start
    server_thread
  end

  private

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

  class ProcGauge
    include Metrics::Gauge

    def initialize(proc)
      @proc = proc
    end

    def value
      @proc.call
    end
  end
end
