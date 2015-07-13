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
  class Json
    def initialize
      @object_mapper = Jackson::Databind::ObjectMapper.new
    end

    def setup
      metrics_module = Metrics::Json::MetricsModule.new(rate_unit = Java::JavaUtilConcurrent::TimeUnit::SECONDS, duration_unit = Java::JavaUtilConcurrent::TimeUnit::MILLISECONDS, show_samples = false)
      @object_mapper.register_module(metrics_module)
      self
    end

    def dump(metric)
      stream = Java::JavaIo::ByteArrayOutputStream.new
      @object_mapper.write_value(stream, metric.to_java)
      String.from_java_bytes(stream.to_byte_array)
    end

    def self.dump(metric)
      new.setup.dump(metric)
    end
  end
end