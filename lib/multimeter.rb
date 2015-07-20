# encoding: utf-8

require 'metrics-core-jars'
require 'metrics-json-jars'
require 'multimeter_metrics'
require 'multimeter/rack'

module Metrics
  include_package 'com.codahale.metrics'
end

module Multimeter
  extend Rack

  def self.create_registry
    MetricRegistry.new
  end

  def self.jmx(registry, options = {})
    Metrics::JmxReporter.forRegistry(registry.to_java).inDomain(options[:domain] || 'multimeter').build.tap(&:start)
  end
end
