# encoding: utf-8

$: << File.expand_path('../../../jar-gems/slf4j-jars/lib', __FILE__)
$: << File.expand_path('../../../jar-gems/metrics-core-jars/lib', __FILE__)

require 'metrics-core-jars'


module Yammer
  module Metrics
    import 'com.yammer.metrics.core.MetricsRegistry'
    import 'com.yammer.metrics.core.MetricName'
    import 'com.yammer.metrics.core.Gauge'
    import 'com.yammer.metrics.core.Timer'
    import 'com.yammer.metrics.reporting.JmxReporter'

    class Timer
      def measure
        ctx = self.time
        begin
          yield
        ensure
          ctx.stop
        end
      end
    end
  end
end

module Multimeter
  def self.registry(group, type)
    Registry.new(::Yammer::Metrics::MetricsRegistry.new, group, type)
  end

  module Metrics
    def self.included(m)
      m.extend(Dsl)
    end

    def multimeter_registry
      if self.class.send(:mode) == :instance
        @multimeter_registry ||= begin
          package, _, class_name = self.class.name.rpartition('::')
          group = self.class.send(:group) || package
          type = self.class.send(:type) || class_name
          type = "#{type}-#{self.object_id}"
          ::Multimeter.registry(group, type)
        end
      else
        self.class.multimeter_registry
      end
    end

    def multimeter_cache(type, name, options)
      @multimeter_cache ||= {}
      @multimeter_cache[name] ||= multimeter_registry.send(type, name, options)
    end

    module Dsl
      def multimeter_registry
        @multimeter_registry ||= begin
          package, _, class_name = self.name.rpartition('::')
          ::Multimeter.registry(group || package, type || class_name)
        end
      end

    private

      def group(g=nil)
        @multimeter_registry_group = g.to_s if g
        @multimeter_registry_group
      end

      def type(t=nil)
        @multimeter_registry_type = t.to_s if t
        @multimeter_registry_type
      end

      def mode(m=nil)
        @multimeter_registry_mode = m if m
        @multimeter_registry_mode
      end

      %w[counter meter histogram timer].each do |type|
        define_method(type) do |name, options={}|
          define_method(name) do
            multimeter_cache(type, name, options)
          end
        end
      end
    end
  end

  module InstanceMetrics
    def self.included(m)
      m.send(:include, Metrics)
      m.send(:mode, :instance)
    end
  end

  class Registry
    def initialize(*args)
      @registry, @group, @type = args
    end

    def jmx!
      ::Yammer::Metrics::JmxReporter.start_default(@registry)
    end

    def all_metrics
      @registry.all_metrics.map do |metric_name, metric|
        {
          :group => metric_name.group, 
          :type  => metric_name.type, 
          :name  => metric_name.name, 
          :value => metric.respond_to?(:value) ? metric.value : metric.count
        }
      end
    end

    def gauge(name, options={}, &block)
      name = ::Yammer::Metrics::MetricName.new(@group, @type, name)
      @registry.new_gauge(name, ProcGauge.new(block))
    end

    def counter(name, options={})
      @registry.new_counter(create_name(name))
    end

    def meter(name, options={})
      raise ArgumentError unless options[:event_type]
      event_type = options[:event_type].to_s
      time_unit = TIME_UNITS[options[:time_unit] || :seconds]
      @registry.new_meter(create_name(name), event_type, time_unit)
    end

    def histogram(name, options={})
      @registry.new_histogram(create_name(name), !!options[:biased])
    end

    def timer(name, options={})
      duration_unit = TIME_UNITS[options[:duration_unit] || :milliseconds]
      rate_unit = TIME_UNITS[options[:rate_unit] || :seconds]
      @registry.new_timer(create_name(name), duration_unit, rate_unit)
    end

  private

    import 'java.util.concurrent.TimeUnit'

    TIME_UNITS = {
      :seconds      => TimeUnit::SECONDS,
      :milliseconds => TimeUnit::MILLISECONDS
    }.freeze

    def create_name(name)
      ::Yammer::Metrics::MetricName.new(@group, @type, name.to_s)
    end
  end

  class ProcGauge < ::Yammer::Metrics::Gauge
    def initialize(proc)
      super()
      @proc = proc
    end

    def value
      @proc.call
    end
  end
end