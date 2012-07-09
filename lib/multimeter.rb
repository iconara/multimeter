# encoding: utf-8

$: << File.expand_path('../../../jar-gems/slf4j-jars/lib', __FILE__)
$: << File.expand_path('../../../jar-gems/metrics-core-jars/lib', __FILE__)

require 'metrics-core-jars'
require 'json'


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
          :type => :meter,
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
  import 'java.lang.Thread'
end

module Multimeter
  def self.global_registry
    GLOBAL_REGISTRY
  end

  def self.registry(group, scope)
    Registry.new(group, scope)
  end

  def self.metrics(group, scope, &block)
    Class.new do
      include(Metrics)
      group(group)
      scope(scope)
      instance_eval(&block)
    end.new
  end

  module Metrics
    def self.included(m)
      m.extend(Dsl)
    end

    def initialize(*args)
      super
      self.class.instance_gauges.each do |name, block|
        instance_block = proc { instance_exec(&block) }
        multimeter_registry.gauge(name, &instance_block)
      end
      self.class.instance_metrics.each do |type, name, options|
        multimeter_registry.send(type, name, options)
      end
    end

    def multimeter_registry
      registry_mode = self.class.send(:registry_mode)
      case registry_mode
      when :instance, :linked_instance
        @multimeter_registry ||= begin
          package, _, class_name = self.class.name.rpartition('::')
          group = self.class.send(:group) || package
          scope = self.class.send(:scope) || class_name
          scope = "#{scope}-#{self.object_id}"
          if registry_mode == :linked_instance
            ::Multimeter.global_registry.sub_registry(scope)
          else
            ::Multimeter.registry(group, scope)
          end
        end
      when :global
        ::Multimeter.global_registry
      else
        self.class.multimeter_registry
      end
    end

    module Dsl
      def multimeter_registry
        @multimeter_registry ||= begin
          package, _, class_name = self.name.rpartition('::')
          g = group || package
          s = scope || class_name
          case registry_mode
          when :linked
            ::Multimeter.global_registry.sub_registry(s)
          when :global
            ::Multimeter.global_registry
          else
            ::Multimeter.registry(g, s)
          end
        end
      end

      def instance_gauges
        @instance_gauges || []
      end

      def instance_metrics
        @instance_metrics || []
      end

      private

      def group(g=nil)
        @multimeter_registry_group = g.to_s if g
        @multimeter_registry_group
      end

      def scope(t=nil)
        @multimeter_registry_scope = t.to_s if t
        @multimeter_registry_scope
      end

      def registry_mode(m=nil)
        @multimeter_registry_mode = m if m
        @multimeter_registry_mode
      end

      def add_instance_gauge(name, block)
        @instance_gauges ||= []
        @instance_gauges << [name, block]
      end

      def add_instance_metric(type, name, options)
        @instance_metrics ||= []
        @instance_metrics << [type, name, options]
      end

      %w[counter meter histogram timer].each do |t|
        type = t.to_sym
        define_method(type) do |name, options={}|
          case registry_mode
          when :instance, :linked_instance
            add_instance_metric(type, name, options)
          else
            multimeter_registry.send(type, name, options)
          end
          define_method(name) do
            multimeter_registry.get(name)
          end
        end
      end

      def gauge(name, &block)
        case registry_mode
        when :instance, :linked_instance
          add_instance_gauge(name, block)
        else
          multimeter_registry.gauge(name, &block)
        end
        define_method(name) do
          multimeter_registry.gauge(name)
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

  module LinkedMetrics
    def self.included(m)
      m.send(:include, Metrics)
      m.send(:registry_mode, :linked)
    end
  end

  module LinkedInstanceMetrics
    def self.included(m)
      m.send(:include, Metrics)
      m.send(:registry_mode, :linked_instance)
    end
  end

  module Jmx
    def jmx!
      ::Yammer::Metrics::JmxReporter.start_default(@registry)
    end
  end

  module Http
    def http!(rack_handler, options={})
      app = proc do |env|
        metrics = {}
        each_metric do |metric_name, metric|
          metrics[metric_name] = metric.to_h
        end
        [200, {}, [metrics.to_json]]
      end
      server_thread = JavaConcurrency::Thread.new do
        rack_handler.run(app, options)
      end
      server_thread.daemon = true
      server_thread.name = 'multimeter-http-server'
      server_thread.start
    end
  end

  class Registry
    include Enumerable
    include Jmx
    include Http

    attr_reader :group, :scope

    def initialize(*args)
      @group, @scope = args
      @registry = ::Yammer::Metrics::MetricsRegistry.new
      @sub_registries = JavaConcurrency::ConcurrentHashMap.new
    end

    def sub_registry(scope)
      r = @sub_registries.get(scope)
      unless r
        r = self.class.new(@group, scope)
        @sub_registries.put_if_absent(scope, r)
        r = @sub_registries.get(scope)
      end
      r
    end

    def sub_registries
      @sub_registries.values.to_a
    end

    def each_metric
      return self unless block_given?
      @registry.all_metrics.each do |metric_name, metric|
        yield metric_name.name, metric
      end
    end
    alias_method :each, :each_metric

    def get(name)
      @registry.all_metrics[create_name(name)]
    end

    def gauge(name, options={}, &block)
      if get(name) && block_given?
        raise ArgumentError, %(Cannot redeclare gauge #{name})
      end
      @registry.new_gauge(create_name(name), ProcGauge.new(block))
    end

    def counter(name, options={})
      error_translation do
        @registry.new_counter(create_name(name))
      end
    end

    def meter(name, options={})
      error_translation do
        event_type = (options[:event_type] || '').to_s
        time_unit = TIME_UNITS[options[:time_unit] || :seconds]
        @registry.new_meter(create_name(name), event_type, time_unit)
      end
    end

    def histogram(name, options={})
      error_translation do
        @registry.new_histogram(create_name(name), !!options[:biased])
      end
    end

    def timer(name, options={})
      error_translation do
        duration_unit = TIME_UNITS[options[:duration_unit] || :milliseconds]
        rate_unit = TIME_UNITS[options[:rate_unit] || :seconds]
        @registry.new_timer(create_name(name), duration_unit, rate_unit)
      end
    end

    def to_h
      h = {}
      [self, *sub_registries].each do |registry|
        m = h[registry.scope] ||= {}
        registry.each_metric do |metric_name, metric|
          m[metric_name.to_sym] = metric.to_h
        end
      end
      h
    end

    private

    TIME_UNITS = {
      :seconds      => JavaConcurrency::TimeUnit::SECONDS,
      :milliseconds => JavaConcurrency::TimeUnit::MILLISECONDS
    }.freeze

    def create_name(name)
      ::Yammer::Metrics::MetricName.new(@group, @scope, name.to_s)
    end

    def error_translation
      begin
        yield
      rescue java.lang.ClassCastException => cce
        raise ArgumentError, %(Cannot redeclare a metric as another type)
      end
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

  GLOBAL_REGISTRY = registry('global', 'global')
end