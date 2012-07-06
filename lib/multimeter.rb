# encoding: utf-8

$: << File.expand_path('../../../jar-gems/slf4j-jars/lib', __FILE__)
$: << File.expand_path('../../../jar-gems/metrics-core-jars/lib', __FILE__)

require 'metrics-core-jars'


module Yammer
  module Metrics
    import 'com.yammer.metrics.core.MetricsRegistry'
    import 'com.yammer.metrics.core.MetricName'
    import 'com.yammer.metrics.core.Meter'
    import 'com.yammer.metrics.core.Counter'
    import 'com.yammer.metrics.core.Histogram'
    import 'com.yammer.metrics.core.Gauge'
    import 'com.yammer.metrics.core.Timer'
    import 'com.yammer.metrics.reporting.JmxReporter'

    class Meter
      def type
        :meter
      end

      def to_h
        {
          :event_type => event_type,
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
          :count => count,
          :max => max,
          :min => min,
          :mean => mean,
          :std_dev => std_dev,
          :sum => sum
        }
      end
    end

    class Gauge
      def type
        :gauge
      end

      def to_h
        {
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
          :event_type => event_type,
          :count => count,
          :mean_rate => mean_rate,
          :one_minute_rate => one_minute_rate,
          :five_minute_rate => five_minute_rate,
          :fifteen_minute_rate => fifteen_minute_rate,
          :max => max,
          :min => min,
          :mean => mean,
          :std_dev => std_dev,
          :sum => sum
        }
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
  end
end

module JavaConcurrency
  import 'java.util.concurrent.TimeUnit'
  import 'java.util.concurrent.ConcurrentHashMap'
  import 'java.util.concurrent.atomic.AtomicReference'
end

module Multimeter
  def self.global_registry
    GLOBAL_REGISTRY
  end

  def self.registry(group, type)
    Registry.new(::Yammer::Metrics::MetricsRegistry.new, group, type)
  end

  def self.metrics(group, type, &block)
    Class.new do
      include(Metrics)
      group(group)
      type(type)
      instance_eval(&block)
    end.new
  end

  module Metrics
    def self.included(m)
      m.extend(Dsl)
    end

    def multimeter_registry
      case self.class.send(:registry_mode)
      when :instance
        @multimeter_registry ||= begin
          package, _, class_name = self.class.name.rpartition('::')
          group = self.class.send(:group) || package
          type = self.class.send(:type) || class_name
          type = "#{type}-#{self.object_id}"
          ::Multimeter.registry(group, type)
        end
      when :global
        Multimeter.global_registry
      when :linked

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
          g, t = group, type
          g, _, t = self.name.rpartition('::') if !(g && t)
          ::Multimeter.registry(g, t)
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

      def registry_mode(m=nil)
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
      m.send(:registry_mode, :instance)
    end
  end

  module GlobalMetrics
    def self.included(m)
      m.send(:include, Metrics)
      m.send(:registry_mode, :global)
    end
  end

  class Registry
    def initialize(*args)
      @registry, @group, @type = args
    end

    def jmx!
      ::Yammer::Metrics::JmxReporter.start_default(@registry)
    end

    def each_metric
      @registry.all_metrics.each do |metric_name, metric|
        yield metric_name.name, metric
      end
    end

    def get(name)
      @registry.all_metrics[name]
    end

    def gauge(name, options={}, &block)
      @registry.new_gauge(create_name(name), ProcGauge.new(block))
    end

    def counter(name, options={})
      @registry.new_counter(create_name(name))
    end

    def meter(name, options={})
      event_type = (options[:event_type] || '').to_s
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

    TIME_UNITS = {
      :seconds      => JavaConcurrency::TimeUnit::SECONDS,
      :milliseconds => JavaConcurrency::TimeUnit::MILLISECONDS
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

  GLOBAL_REGISTRY = registry('', 'global')
end