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
    end

    describe '#to_h' do
      it 'returns a hash representing all the metrics' do
        metric_registry.counter('a_counter')
        metric_registry.meter('a_meter')
        metric_registry.timer('a_timer')
        metric_registry.histogram('an_histogram')
        metric_registry.gauge('a_gauge') { 3 }
        h = metric_registry.to_h
        expect(h.keys).to contain_exactly(*%w[a_counter a_meter a_timer an_histogram a_gauge])
        h.each do |key, value|
          expect(value).to eq(metric_registry.metrics[key].to_h)
        end
      end
    end
  end
end
