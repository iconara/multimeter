# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe MetricRegistry do
    let :metric_registry do
      described_class.new
    end

    describe '#counter' do
      it 'creates a counter metric' do
        counter = metric_registry.counter('foo')
        expect(counter).to be_a(Counter)
      end

      it 'returns an existing counter' do
        counter = metric_registry.counter('foo')
        counter.inc
        counter = metric_registry.counter('foo')
        expect(counter.count).to eq(1)
      end
    end

    describe '#meter' do
      it 'creates a meter metric' do
        meter = metric_registry.meter('foo')
        expect(meter).to be_a(Meter)
      end

      it 'returns an existing meter' do
        meter = metric_registry.meter('foo')
        meter.mark
        meter = metric_registry.meter('foo')
        expect(meter.count).to eq(1)
      end
    end

    describe '#timer' do
      it 'creates a timer metric' do
        timer = metric_registry.timer('foo')
        expect(timer).to be_a(Timer)
      end

      it 'returns an existing timer' do
        timer = metric_registry.timer('foo')
        timer.time { }
        timer = metric_registry.timer('foo')
        expect(timer.count).to eq(1)
      end
    end

    describe '#histogram' do
      it 'creates a histogram metric' do
        histogram = metric_registry.histogram('foo')
        expect(histogram).to be_a(Histogram)
      end

      it 'returns an existing histogram' do
        histogram = metric_registry.histogram('foo')
        histogram.update(3)
        histogram = metric_registry.histogram('foo')
        expect(histogram.count).to eq(1)
      end
    end

    describe '#gauge' do
      it 'creates a guage metric that uses the given block' do
        gauge = metric_registry.gauge('foo') { 1 }
        expect(gauge).to be_a(Gauge)
      end

      it 'replaces the gauge when registered again' do
        metric_registry.gauge('foo') { 1 }
        metric_registry.gauge('foo') { 2 }
        gauge = metric_registry.gauge('foo')
        expect(gauge.value).to eq(2)
      end

      context 'when given no block' do
        it 'returns a previously registered gauge' do
          metric_registry.gauge('foo') { 1 }
          gauge = metric_registry.gauge('foo')
          expect(gauge).to be_a(Gauge)
        end

        it 'returns nil when no gauge has been registered' do
          gauge = metric_registry.gauge('foo')
          expect(gauge).to be_nil
        end
      end

      context 'when the return type is specified' do
        it 'converts the value to a Long' do
          [:long, 'long', :loNG, 'LOng', Java::long, java.lang.Long].each do |type|
            gauge = metric_registry.gauge('foo', type) { 3.14 }
            expect(gauge.value).to eq(3)
          end
        end

        it 'converts the value to an Integer' do
          [:int, :integer, 'int', 'integer', :iNt, 'iNtEgEr', Java::int, java.lang.Integer].each do |type|
            gauge = metric_registry.gauge('foo', type) { 3.14 }
            expect(gauge.value).to eq(3)
          end
        end

        it 'converts the value to a Double' do
          [:double, 'double', :dOuBlE, 'dOuBlE', Java::double, java.lang.Double].each do |type|
            gauge = metric_registry.gauge('foo', type) { Rational(1, 3) }
            expect(gauge.value).to be_a(Float)
          end
        end

        it 'converts the value to a Float' do
          [:float, 'float', :fLoaT, 'fLoAt', Java::float, java.lang.Float].each do |type|
            gauge = metric_registry.gauge('foo', type) { Rational(1, 3) }
            expect(gauge.value).to be_a(Float)
          end
        end

        it 'converts the value to a String' do
          [:string, 'string', :sTrInG, 'sTrInG', java.lang.String].each do |type|
            gauge = metric_registry.gauge('foo', type) { 42 }
            expect(gauge.value).to eq('42')
          end
        end

        it 'raises an error when no block is given' do
          expect { metric_registry.gauge('foo', :long) }.to raise_error(ArgumentError, /block must be given/i)
        end

        it 'raises an error when the type is not supported' do
          expect { metric_registry.gauge('foo', :bar) { 3 } }.to raise_error(ArgumentError, /unsupported type "bar"/i)
          expect { metric_registry.gauge('foo', [:wut?]) { {:foo => :bar} } }.to raise_error(ArgumentError, /unsupported type/i)
          expect { metric_registry.gauge('foo', java.util.Map) { {:foo => :bar} } }.to raise_error(ArgumentError, /unsupported type/i)
        end
      end
    end

    describe '#metrics' do
      it 'returns all registered metrics as a hash' do
        metric_registry.counter('a_counter')
        metric_registry.meter('a_meter')
        metric_registry.timer('a_timer')
        metric_registry.histogram('an_histogram')
        metric_registry.gauge('a_gauge') { 3 }
        metrics = metric_registry.metrics
        expect(metrics.keys).to contain_exactly(*%w[a_counter a_meter a_timer an_histogram a_gauge])
      end

      it 'does not return an object that can be used to modify its internal state' do
        counter = metric_registry.counter('a_counter')
        counter.inc
        another_registry = described_class.new
        another_registry.metrics['a_counter'] = counter
        counter = another_registry.counter('a_counter')
        expect(counter.count).to eq(0)
      end
    end

    describe '#to_json' do
      it 'returns a json representing all the metrics' do
        metric_registry.counter('a_counter')
        metric_registry.meter('a_meter')
        metric_registry.timer('a_timer')
        metric_registry.histogram('an_histogram')
        metric_registry.gauge('a_gauge', :int) { 3 }
        h = JSON.parse(metric_registry.to_json)
        metric_types = %w[counters meters timers histograms gauges]
        expect(h.keys).to match_array(metric_types + ['version'])
        metric_types.each do |type|
          metrics = h[type]
          metrics.each do |name, value|
            expect(value).to eq(JSON.parse(metric_registry.metrics[name].to_json))
          end
        end
      end
    end

    describe '#to_java' do
      it 'returns the underlying metric registry' do
        mr = metric_registry.to_java
        expect(mr).to be_a(com.codahale.metrics.MetricRegistry)
      end

      it 'has registered all metrics with the underlying registry' do
        counter = metric_registry.counter('foo')
        counter.inc
        metric_registry.gauge('bar') { 3 }
        mr = metric_registry.to_java
        metrics = mr.get_metrics
        expect(metrics['foo'].count).to eq(1)
        expect(metrics['bar'].value).to eq(3)
      end
    end
  end
end
