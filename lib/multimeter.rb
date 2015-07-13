# encoding: utf-8

require 'metrics-core-jars'
require 'multimeter_metrics'
require 'json'
require 'multimeter/http'
require 'multimeter/rack'
require 'multimeter/json'

module Metrics
  include_package 'com.codahale.metrics'
end

module Multimeter
  extend Http
  extend Rack

  class MetricRegistry
    def to_json
      Json.dump(self)
    end
  end

  class Meter
    def to_json
      Json.dump(self)
    end
  end

  class Counter
    def to_json
      Json.dump(self)
    end
  end

  class Histogram
    def to_json
      Json.dump(self)
    end
  end

  class Timer
    def to_json
      Json.dump(self)
    end
  end

  class Snapshot
    def to_json
      Json.dump(self)
    end
  end

  class Gauge
    def to_json
      Json.dump(self)
    end
  end

  def self.create_registry
    MetricRegistry.new
  end

  def self.jmx(registry, options = {})
    Metrics::JmxReporter.forRegistry(registry.to_java).inDomain(options[:domain] || 'multimeter').build.tap(&:start)
  end

  private

  NANO_TO_MILLI_SCALE = 1.0/1_000_000
end
